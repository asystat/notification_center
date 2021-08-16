package ai.sbreit.notificationcenter.services;

import android.app.Service;
import android.content.Intent;
import android.os.Binder;
import android.os.IBinder;
import android.util.Log;

public class OneSignalService extends Service{
    private final IBinder binder = new AppServiceBinder();
    private final String TAG = "rest/service";

    @Override
    public void onCreate() {
        super.onCreate();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        return START_NOT_STICKY;
    }

    @Override
    public void onDestroy() {
        Log.d(TAG, "onDestroy: ");
        super.onDestroy();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return binder;
    }

    public class AppServiceBinder extends Binder {
        public OneSignalService getService() {
            return  OneSignalService.this;
        }
    }

    public void startTimer(int duration) {
        Log.i(TAG, "Timer started");
    }

    public void stopTimer() {
        Log.i(TAG, "Timer stopped");
    }

    public int getCurrentSeconds() {
        return ((int) System.currentTimeMillis());
    }

}