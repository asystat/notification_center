package ai.sbreit.notificationcenter;

import ai.sbreit.notificationcenter.services.OneSignalService;
import ai.sbreit.notificationcenter.services.OneSignalService.*;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.IBinder;
import android.os.PowerManager;
import android.util.Log;
import android.widget.Toast;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.plugin.common.MethodChannel;

import static android.content.Intent.FLAG_ACTIVITY_NEW_TASK;

public class MainActivity extends io.flutter.embedding.android.FlutterActivity{
    static final String TAG = "rest";
    static final String CHANNEL = "ai.sbreit.notificationcenter/service";

    OneSignalService appService;
    boolean serviceConnected = false;
    MethodChannel.Result keepResult = null;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }


    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    try {
                        if (call.method.equals("connect")) {
                            connectToService();
                            keepResult = result;
                        } else if (serviceConnected) {
                            if (call.method.equals("start")) {
                                appService.startTimer(call.argument("duration"));
                                result.success(null);
                            } else if (call.method.equals("stop")) {
                                appService.stopTimer();
                                result.success(null);
                            } else if (call.method.equals("getCurrentSeconds")) {
                                int sec = appService.getCurrentSeconds();
                                result.success(sec);
                            }
                        } else {
                            result.error(null, "App not connected to service", null);
                        }
                    } catch (Exception e) {
                        result.error(null, e.getMessage(), null);
                    }
        });
    }

    private void connectToService() {
        if (!serviceConnected) {
            Intent service = new Intent(this, OneSignalService.class);
            startService(service);
            bindService(service, connection, Context.BIND_AUTO_CREATE);
        } else {
            Log.i(TAG, "Service already connected");
            if (keepResult != null) {
                keepResult.success(null);
                keepResult = null;
            }
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Context context = getApplicationContext();
            String packageName = context.getPackageName();
            PowerManager pm = (PowerManager) context.getSystemService(Context.POWER_SERVICE);
            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                Toast.makeText(context, "This app needs to be whitelisted", Toast.LENGTH_LONG).show();
                Intent intent = new Intent();
                intent.setAction(android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
                intent.setFlags(FLAG_ACTIVITY_NEW_TASK);
                intent.setData(Uri.parse("package:" + packageName));
                context.startActivity(intent);
            }
        }
    }

    @Override
    protected void onStop() {
        super.onStop();
        unbindService(connection);
        serviceConnected = false;
    }

    private ServiceConnection connection = new ServiceConnection() {

        @Override
        public void onServiceConnected(ComponentName className,
                                       IBinder service) {
            OneSignalService.AppServiceBinder binder = (OneSignalService.AppServiceBinder) service;
            appService = binder.getService();
            serviceConnected = true;
            Log.i(TAG, "Service connected");
            if (keepResult != null) {
                keepResult.success(null);
                keepResult = null;
            }
        }

        @Override
        public void onServiceDisconnected(ComponentName arg0) {
            serviceConnected = false;
            Log.i(TAG, "Service disconnected");
        }
    };

}
