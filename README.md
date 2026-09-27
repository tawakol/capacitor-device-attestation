# capacitor-device-attestation
Capacitor plugin for device attestation: Play Integrity on Android, App Attest on iOS, one JS API. Returns a platform-signed token bound to a server challenge, for verifying that requests come from your unmodified app on a genuine device.

A single isAvailable() / getToken(challenge) interface over Google's Play Integrity API and Apple's App Attest. The plugin hands you a token you send to your own server, which verifies it with the platform's keys. It holds no secrets and makes no network calls of its own beyond the optional App Attest enrolment POST to a URL you provide. Web returns not-available so your app can fall back to a browser challenge.
