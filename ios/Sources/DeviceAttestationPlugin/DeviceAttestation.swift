// ios/Sources/DeviceAttestationPlugin/DeviceAttestation.swift
import Foundation
import DeviceCheck
import CryptoKit

struct AttestationError: Error {
    let code: String   // ENROLLED_RETRY | API_NOT_AVAILABLE | NETWORK | UNKNOWN
    let message: String
}

@objc public class DeviceAttestation: NSObject {
    private let service = DCAppAttestService.shared
    private let keyIdDefaultsKey = "capacitor-device-attestation.keyId"

    public func isSupported() -> Bool {
        return service.isSupported
    }

    private var storedKeyId: String? {
        get { UserDefaults.standard.string(forKey: keyIdDefaultsKey) }
        set { UserDefaults.standard.set(newValue, forKey: keyIdDefaultsKey) }
    }

    func resetKey() {
        storedKeyId = nil
    }

    /// First call on a device: generate + attest + enrol, then reject with ENROLLED_RETRY so the caller
    /// fetches a fresh challenge (the enrol endpoint consumed this one). Later calls: sign an assertion.
    func getToken(challenge: String, enrollUrl: URL, completion: @escaping (Result<String, AttestationError>) -> Void) {
        guard service.isSupported else {
            completion(.failure(AttestationError(code: "API_NOT_AVAILABLE", message: "App Attest not supported")))
            return
        }
        if let keyId = storedKeyId {
            signAssertion(keyId: keyId, challenge: challenge, completion: completion)
        } else {
            enroll(challenge: challenge, enrollUrl: enrollUrl, completion: completion)
        }
    }

    private func enroll(challenge: String, enrollUrl: URL, completion: @escaping (Result<String, AttestationError>) -> Void) {
        service.generateKey { keyId, error in
            guard let keyId = keyId, error == nil else {
                completion(.failure(self.map(error)))
                return
            }
            let clientDataHash = Data(SHA256.hash(data: Data(challenge.utf8)))
            self.service.attestKey(keyId, clientDataHash: clientDataHash) { attestation, error in
                guard let attestation = attestation, error == nil else {
                    completion(.failure(self.map(error)))
                    return
                }
                self.postEnrolment(url: enrollUrl, keyId: keyId, attestation: attestation, challenge: challenge) { result in
                    switch result {
                    case .success:
                        self.storedKeyId = keyId
                        completion(.failure(AttestationError(code: "ENROLLED_RETRY", message: "Key enrolled; fetch a new challenge and call again")))
                    case .failure(let err):
                        completion(.failure(err))
                    }
                }
            }
        }
    }

    private func signAssertion(keyId: String, challenge: String, completion: @escaping (Result<String, AttestationError>) -> Void) {
        // clientData is the JSON the server re-hashes: {"challenge":"<value>"}
        let clientData = Data("{\"challenge\":\"\(challenge)\"}".utf8)
        let clientDataHash = Data(SHA256.hash(data: clientData))
        service.generateAssertion(keyId, clientDataHash: clientDataHash) { assertion, error in
            if let error = error as? DCError, error.code == .invalidKey {
                // Key revoked or app reinstalled: drop it and re-enrol on the next call.
                self.storedKeyId = nil
                completion(.failure(AttestationError(code: "ENROLLED_RETRY", message: "Stored key invalid; re-enrolling")))
                return
            }
            guard let assertion = assertion, error == nil else {
                completion(.failure(self.map(error)))
                return
            }
            let payload = "\(keyId).\(self.base64url(assertion)).\(self.base64url(clientData))"
            completion(.success(payload))
        }
    }

    private func postEnrolment(url: URL, keyId: String, attestation: Data, challenge: String, completion: @escaping (Result<Void, AttestationError>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = ["keyId": keyId, "attestation": base64url(attestation), "challenge": challenge]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                completion(.failure(AttestationError(code: "NETWORK", message: "Enrolment request failed")))
                return
            }
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                let json = data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
                let serverCode = json?["code"] as? String
                let code = (500...599).contains(status) ? "NETWORK" : "UNKNOWN"
                completion(.failure(AttestationError(code: code, message: "Enrolment rejected with status \(status) code \(serverCode ?? "none")")))
                return
            }
            completion(.success(()))
        }.resume()
    }

    private func map(_ error: Error?) -> AttestationError {
        if let dc = error as? DCError {
            switch dc.code {
            case .featureUnsupported: return AttestationError(code: "API_NOT_AVAILABLE", message: dc.localizedDescription)
            case .serverUnavailable: return AttestationError(code: "NETWORK", message: dc.localizedDescription)
            default: return AttestationError(code: "UNKNOWN", message: dc.localizedDescription)
            }
        }
        return AttestationError(code: "UNKNOWN", message: error?.localizedDescription ?? "unknown")
    }

    private func base64url(_ data: Data) -> String {
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
