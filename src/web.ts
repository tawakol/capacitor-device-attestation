import { WebPlugin } from '@capacitor/core';

import type { AttestationToken, AvailabilityResult, DeviceAttestationPlugin } from './definitions';

export class DeviceAttestationWeb extends WebPlugin implements DeviceAttestationPlugin {
  async isAvailable(): Promise<AvailabilityResult> {
    return { available: false };
  }

  async getToken(): Promise<AttestationToken> {
    throw this.unavailable('Device attestation is not available on web; use a browser challenge instead.');
  }

  async resetKey(): Promise<void> {
    // No key to forget on web.
  }
}
