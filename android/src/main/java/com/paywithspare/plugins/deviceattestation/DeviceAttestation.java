package com.paywithspare.plugins.deviceattestation;

import android.content.Context;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GoogleApiAvailability;
import com.google.android.play.core.integrity.IntegrityManagerFactory;
import com.google.android.play.core.integrity.StandardIntegrityException;
import com.google.android.play.core.integrity.StandardIntegrityManager;
import com.google.android.play.core.integrity.StandardIntegrityManager.PrepareIntegrityTokenRequest;
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityToken;
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityTokenProvider;
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityTokenRequest;
import com.google.android.play.core.integrity.model.StandardIntegrityErrorCode;

public class DeviceAttestation {

    public interface Callback {
        void onToken(String token);
        void onError(String code, String message);
    }

    private final Context context;
    private final StandardIntegrityManager manager;
    private volatile StandardIntegrityTokenProvider provider; // warmed once per process, per Google's guidance
    private volatile long preparedForProject = -1;

    public DeviceAttestation(Context context) {
        this.context = context.getApplicationContext();
        this.manager = IntegrityManagerFactory.createStandard(this.context);
    }

    public boolean isAvailable() {
        return GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(context) == ConnectionResult.SUCCESS;
    }

    public void getToken(String challenge, long cloudProjectNumber, Callback callback) {
        if (!isAvailable()) {
            callback.onError("API_NOT_AVAILABLE", "Google Play services not available");
            return;
        }
        StandardIntegrityTokenProvider p = provider;
        if (p != null && preparedForProject == cloudProjectNumber) {
            request(p, challenge, callback);
            return;
        }
        manager
            .prepareIntegrityToken(PrepareIntegrityTokenRequest.builder().setCloudProjectNumber(cloudProjectNumber).build())
            .addOnSuccessListener((prepared) -> {
                provider = prepared;
                preparedForProject = cloudProjectNumber;
                request(prepared, challenge, callback);
            })
            .addOnFailureListener((e) -> callback.onError(mapCode(e), describe(e)));
    }

    private void request(StandardIntegrityTokenProvider p, String challenge, Callback callback) {
        p.request(StandardIntegrityTokenRequest.builder().setRequestHash(challenge).build())
            .addOnSuccessListener((StandardIntegrityToken token) -> callback.onToken(token.token()))
            .addOnFailureListener((e) -> {
                if (provider == p) {
                    provider = null; // force a fresh prepare next time; a stale failure keeps a newer provider
                }
                callback.onError(mapCode(e), describe(e));
            });
    }

    private static String describe(Exception e) {
        return e.getMessage() != null ? e.getMessage() : e.toString();
    }

    private String mapCode(Exception e) {
        if (e instanceof StandardIntegrityException) {
            int code = ((StandardIntegrityException) e).getErrorCode();
            switch (code) {
                case StandardIntegrityErrorCode.API_NOT_AVAILABLE:
                case StandardIntegrityErrorCode.PLAY_STORE_NOT_FOUND:
                case StandardIntegrityErrorCode.PLAY_SERVICES_NOT_FOUND:
                case StandardIntegrityErrorCode.PLAY_STORE_VERSION_OUTDATED:
                case StandardIntegrityErrorCode.PLAY_SERVICES_VERSION_OUTDATED:
                    return "API_NOT_AVAILABLE";
                case StandardIntegrityErrorCode.NETWORK_ERROR:
                case StandardIntegrityErrorCode.GOOGLE_SERVER_UNAVAILABLE:
                    return "NETWORK";
                default:
                    return "UNKNOWN";
            }
        }
        return "UNKNOWN";
    }
}
