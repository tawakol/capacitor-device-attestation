import { registerPlugin } from '@capacitor/core';

import type { DeviceAttestationPlugin } from './definitions';

const DeviceAttestation = registerPlugin<DeviceAttestationPlugin>('DeviceAttestation', {
  web: () => import('./web').then((m) => new m.DeviceAttestationWeb()),
});

export * from './definitions';
export { DeviceAttestation };
