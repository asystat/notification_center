package ai.sbreit.notificationcenter.services;

import android.content.Context;
import android.graphics.Color;
import android.os.Vibrator;
import android.util.Log;
import org.json.JSONObject;

import com.onesignal.OSNotification;
import com.onesignal.OSMutableNotification;
import com.onesignal.OSNotificationReceivedEvent;
import com.onesignal.OneSignal.OSRemoteNotificationReceivedHandler;

@SuppressWarnings("unused")
public class NotificationServiceExtension implements OSRemoteNotificationReceivedHandler {

    @Override
    public void remoteNotificationReceived(Context context, OSNotificationReceivedEvent notificationReceivedEvent) {

        Vibrator v = (Vibrator) context.getSystemService(Context.VIBRATOR_SERVICE);
        v.vibrate(1000);

        OSNotification notification = notificationReceivedEvent.getNotification();

        // Example of modifying the notification's accent color
        OSMutableNotification mutableNotification = notification.mutableCopy();
        mutableNotification.setExtender(builder -> builder.setColor(Color.BLUE));

        JSONObject data = notification.getAdditionalData();
        Log.i("ONESIGNALEXAMPLE", "RECEIVED NOTIFICATION IN BACKGROUND!: " + data);

        // If complete isn't call within a time period of 25 seconds, OneSignal internal logic will show the original notification
        // To omit displaying a notification, pass `null` to complete()
        notificationReceivedEvent.complete(mutableNotification);
    }
}