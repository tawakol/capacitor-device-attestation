export type AttestationScheme = 'playintegrity' | 'appattest';

export interface AvailabilityResult {
  /** True when the platform can attest on this device. False on web and on Android without Google Play services. */
  available: boolean;
  /** Which scheme `getToken` will return when available. */
  scheme?: AttestationScheme;
}

export interface GetTokenOptions {
  /** Server-issued one-time challenge (base64url, 43 chars). The token is bound to it. */
  challenge: string;
  /** iOS only. Where the plugin POSTs `{ keyId, attestation, challenge }` on first use to enrol the device key. */
  enrollUrl: string;
  /** Android only. Google Cloud project number linked to the app in Play Console (required by the standard Play Integrity API). */
  cloudProjectNumber?: string;
}

export interface AttestationToken {
  scheme: AttestationScheme;
  /**
   * playintegrity: the integrity token as returned by Play.
   * appattest: `<keyId>.<base64url(assertion)>.<base64url(clientData)>`.
   */
  payload: string;
}

/**
 * Rejection codes carried on the error's `code` property.
 * ENROLLED_RETRY: iOS enrolled a new key using this challenge; fetch a fresh challenge and call again.
 * API_NOT_AVAILABLE: attestation is not possible on this device; use your fallback.
 * NETWORK: the platform or enrolment call could not reach its server; retry later.
 * UNKNOWN: anything else; the message carries the platform's description.
 */
export type DeviceAttestationErrorCode = 'ENROLLED_RETRY' | 'API_NOT_AVAILABLE' | 'NETWORK' | 'UNKNOWN';

export interface DeviceAttestationPlugin {
  isAvailable(): Promise<AvailabilityResult>;
  getToken(options: GetTokenOptions): Promise<AttestationToken>;
  /** Forget the enrolled key so the next getToken enrols a fresh one. Call after the server rejects an appattest token as invalid. No-op on Android and web. */
  resetKey(): Promise<void>;
}
