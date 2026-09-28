// ios/Sources/DeviceAttestationPlugin/DeviceAttestationPlugin.swift
import Foundation
import Capacitor

@objc(DeviceAttestationPlugin)
public class DeviceAttestationPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "DeviceAttestationPlugin"
    public let jsName = "DeviceAttestation"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "isAvailable", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getToken", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "resetKey", returnType: CAPPluginReturnPromise)
    ]
    private let implementation = DeviceAttestation()

    @objc func isAvailable(_ call: CAPPluginCall) {
        let available = implementation.isSupported()
        var result: [String: Any] = ["available": available]
        if available { result["scheme"] = "appattest" }
        call.resolve(result)
    }

    @objc func getToken(_ call: CAPPluginCall) {
        guard let challenge = call.getString("challenge"), !challenge.isEmpty else {
            call.reject("challenge is required", "UNKNOWN")
            return
        }
        guard let enrollUrl = call.getString("enrollUrl"), let url = URL(string: enrollUrl) else {
            call.reject("enrollUrl is required", "UNKNOWN")
            return
        }
        implementation.getToken(challenge: challenge, enrollUrl: url) { result in
            switch result {
            case .success(let payload):
                call.resolve(["scheme": "appattest", "payload": payload])
            case .failure(let error):
                call.reject(error.message, error.code)
            }
        }
    }

    @objc func resetKey(_ call: CAPPluginCall) {
        implementation.resetKey()
        call.resolve()
    }
}
