package ai.sbreit.notificationcenter.services;

import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.media.AudioManager;
import android.media.ToneGenerator;
import android.os.Binder;
import android.os.IBinder;
import android.os.Vibrator;
import android.util.Log;

import com.onesignal.OSMutableNotification;
import com.onesignal.OSNotification;
import com.onesignal.OSNotificationReceivedEvent;
import com.onesignal.OneSignal;

import org.json.JSONObject;

import java.util.Calendar;

import ai.sbreit.notificationcenter.MainActivity;

public class OneSignalService extends Service implements OneSignal.OSRemoteNotificationReceivedHandler {

    private static boolean isFinding = false;

    private final IBinder binder = new AppServiceBinder();
    private final String TAG = "rest/service";


    @Override
    public void remoteNotificationReceived(Context context, OSNotificationReceivedEvent notificationReceivedEvent) {

        Vibrator v = (Vibrator) context.getSystemService(Context.VIBRATOR_SERVICE);
        v.vibrate(1000);
        startAlarm();

        OSNotification notification = notificationReceivedEvent.getNotification();

        // Example of modifying the notification's accent color
        OSMutableNotification mutableNotification = notification.mutableCopy();
        mutableNotification.setExtender(builder -> builder.setColor(Color.BLUE));

        JSONObject data = notification.getAdditionalData();
        Log.i("ONESIGNALEXAMPLE", "RECEIVED NOTIFICATION IN BACKGROUND!: " + data);

        //startAppIfNotStarted();

        isFinding = true;


        // If complete isn't call within a time period of 25 seconds, OneSignal internal logic will show the original notification
        // To omit displaying a notification, pass `null` to complete()

        notificationReceivedEvent.complete(null);

        Intent service = new Intent(this, OneSignalService.class);
        startService(service);


    }

    private void startAppIfNotStarted(){
        Intent dialogIntent = new Intent(this, MainActivity.class);
        dialogIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(dialogIntent);
    }

    public int stopAlarm() {
        isFinding = false;
        Log.d(TAG, "stopAlarm was called");
        return ((int) System.currentTimeMillis());
    }

    public void startAlarm(){

        isFinding = true;

        (new Thread() {
            public void run() {
                //turn into thread
                long timeStart = Calendar.getInstance().getTimeInMillis();
                Log.d(TAG, "FindSound Start: "+timeStart);
                ToneGenerator toneG = new ToneGenerator(AudioManager.STREAM_ALARM, ToneGenerator.MAX_VOLUME);
                while(isFinding) {
                    try {
                        long timeDiff =  Calendar.getInstance().getTimeInMillis() - timeStart;
                        Log.d(TAG, "Sound time: " + timeDiff/1000);
                        toneG.startTone(ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD, 200); // 200 ms tone
                        Thread.sleep(600L);
                    }
                    catch(InterruptedException ie) {
                        Thread.currentThread().interrupt();
                        return;
                    }
                }
            }
        }).start();


    }


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