package com.paywithspare.plugins.deviceattestation;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

@CapacitorPlugin(name = "DeviceAttestation")
public class DeviceAttestationPlugin extends Plugin {

    private DeviceAttestation implementation;

    @Override
    public void load() {
        implementation = new DeviceAttestation(getContext());
    }

    @PluginMethod
    public void isAvailable(PluginCall call) {
        boolean available = implementation.isAvailable();
        JSObject ret = new JSObject();
        ret.put("available", available);
        if (available) ret.put("scheme", "playintegrity");
        call.resolve(ret);
    }

    @PluginMethod
    public void getToken(PluginCall call) {
        String challenge = call.getString("challenge");
        String cloudProjectNumber = call.getString("cloudProjectNumber");
        if (challenge == null || challenge.isEmpty()) {
            call.reject("challenge is required", "UNKNOWN");
            return;
        }
        if (cloudProjectNumber == null || cloudProjectNumber.isEmpty()) {
            call.reject("cloudProjectNumber is required on Android", "UNKNOWN");
            return;
        }
        long projectNumber;
        try {
            projectNumber = Long.parseLong(cloudProjectNumber);
        } catch (NumberFormatException e) {
            call.reject("cloudProjectNumber must be numeric", "UNKNOWN");
            return;
        }
        implementation.getToken(
            challenge,
            projectNumber,
            new DeviceAttestation.Callback() {
                @Override
                public void onToken(String token) {
                    JSObject ret = new JSObject();
                    ret.put("scheme", "playintegrity");
                    ret.put("payload", token);
                    call.resolve(ret);
                }

                @Override
                public void onError(String code, String message) {
                    call.reject(message, code);
                }
            }
        );
    }

    @PluginMethod
    public void resetKey(PluginCall call) {
        // Play Integrity holds no device key; nothing to forget.
        call.resolve();
    }
}
