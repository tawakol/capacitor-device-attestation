# capacitor-device-attestation
Capacitor plugin for device attestation: Play Integrity on Android, App Attest on iOS, one JS API. Returns a platform-signed token bound to a server challenge, for verifying that requests come from your unmodified app on a genuine device.

A single isAvailable() / getToken(challenge) interface over Google's Play Integrity API and Apple's App Attest. The plugin hands you a token you send to your own server, which verifies it with the platform's keys. It holds no secrets and makes no network calls of its own beyond the optional App Attest enrolment POST to a URL you provide. Web returns not-available so your app can fall back to a browser challenge.

## Usage

```ts
import { DeviceAttestation } from 'capacitor-device-attestation';

const { available } = await DeviceAttestation.isAvailable();
if (!available) { /* use a browser challenge such as Turnstile */ }

const challenge = await fetchChallengeFromYourServer();
try {
  const { scheme, payload } = await DeviceAttestation.getToken({
    challenge,
    enrollUrl: 'https://api.example.com/attest/ios/enroll',
    cloudProjectNumber: '123456789012',
  });
  await fetch('/protected', { headers: { 'X-Device-Attestation': `${scheme} ${payload}` } });
} catch (e) {
  if (e.code === 'ENROLLED_RETRY') { /* fetch a fresh challenge and call getToken again */ }
  // If your server rejects an appattest token as invalid, call DeviceAttestation.resetKey() and retry once.
}
```

The server verifies `playintegrity` tokens with Google's Play Console keys and `appattest` payloads (`<keyId>.<assertion>.<clientData>`) with the key enrolled at `enrollUrl`.

### Concurrency

Serialise `getToken` calls: overlapping calls on iOS can enrol twice, and App Attest assertions must reach your server in counter order.

## API

<docgen-index>

* [`isAvailable()`](#isavailable)
* [`getToken(...)`](#gettoken)
* [`resetKey()`](#resetkey)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### isAvailable()

```typescript
isAvailable() => Promise<AvailabilityResult>
```

**Returns:** <code>Promise&lt;<a href="#availabilityresult">AvailabilityResult</a>&gt;</code>

--------------------


### getToken(...)

```typescript
getToken(options: GetTokenOptions) => Promise<AttestationToken>
```

| Param         | Type                                                        |
| ------------- | ----------------------------------------------------------- |
| **`options`** | <code><a href="#gettokenoptions">GetTokenOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#attestationtoken">AttestationToken</a>&gt;</code>

--------------------


### resetKey()

```typescript
resetKey() => Promise<void>
```

Forget the enrolled key so the next getToken enrols a fresh one. Call after the server rejects an appattest token as invalid. No-op on Android and web.

--------------------


### Interfaces


#### AvailabilityResult

| Prop            | Type                                                            | Description                                                                                                 |
| --------------- | --------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| **`available`** | <code>boolean</code>                                            | True when the platform can attest on this device. False on web and on Android without Google Play services. |
| **`scheme`**    | <code><a href="#attestationscheme">AttestationScheme</a></code> | Which scheme `getToken` will return when available.                                                         |


#### AttestationToken

| Prop          | Type                                                            | Description                                                                                                                                    |
| ------------- | --------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| **`scheme`**  | <code><a href="#attestationscheme">AttestationScheme</a></code> |                                                                                                                                                |
| **`payload`** | <code>string</code>                                             | playintegrity: the integrity token as returned by Play. appattest: `&lt;keyId&gt;.&lt;base64url(assertion)&gt;.&lt;base64url(clientData)&gt;`. |


#### GetTokenOptions

| Prop                     | Type                | Description                                                                                                                |
| ------------------------ | ------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| **`challenge`**          | <code>string</code> | Server-issued one-time challenge (base64url, 43 chars). The token is bound to it.                                          |
| **`enrollUrl`**          | <code>string</code> | iOS only. Where the plugin POSTs `{ keyId, attestation, challenge }` on first use to enrol the device key.                 |
| **`cloudProjectNumber`** | <code>string</code> | Android only. Google Cloud project number linked to the app in Play Console (required by the standard Play Integrity API). |


### Type Aliases


#### AttestationScheme

<code>'playintegrity' | 'appattest'</code>

</docgen-api>

