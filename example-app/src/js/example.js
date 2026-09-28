import { DeviceAttestation } from 'capacitor-device-attestation';

window.testEcho = () => {
    const inputValue = document.getElementById("echoInput").value;
    DeviceAttestation.echo({ value: inputValue })
}
