import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notification_center/main.dart';
import 'package:notification_center/ui_components/handable_button.dart';
import 'package:another_flushbar/flushbar.dart';
import 'dart:async';

//import OneSignal
import 'package:onesignal_flutter/onesignal_flutter.dart';

//sound
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

//vibration
import 'package:vibration/vibration.dart';

class ApplicationToolset extends State<NotificationCenter> with WidgetsBindingObserver{


  static const MethodChannel platform = MethodChannel('ai.sbreit.notificationcenter/service');
  bool _serviceStarted = false;


  String _debugLabelString = "";
  String? _emailAddress;
  String? _smsNumber;
  String? _externalUserId;
  bool _enableConsentButton = false;

  // CHANGE THIS parameter to true if you want to test GDPR privacy consent
  bool _requireConsent = true;

  Future<void> connectToService() async {
    try {
      await platform.invokeMethod<void>('connect');
      print('Connected to service');
      _handleFlushbar(title:"Connection successful", message: "Fluter app is connected to native Android service ;)");
    } on Exception catch (e) {
      print(e.toString());
      _handleFlushbar(title:"Connection failed", message: "Couldn'' connect to to native Android service ;)");
      return;
    }

    try {
      int serviceData = await stopServiceAlarm() ?? 0;
      setState(() {
        _debugLabelString = 'Service returned data: ${serviceData}';
      });
    } on PlatformException catch (e) {
      print(e.toString());
    } on Exception catch (e) {
      print(e.toString());
    }
  }

  Future<int?> stopServiceAlarm() async {

    try {
      final int? result = await platform.invokeMethod<int>('stopAlarm');
      print("Service call result: ${result}");
      return result;
    } on PlatformException catch (e) {
      print(e.toString());
    }
    return 0;
  }

  Future<void> startServiceAlarm() async {

    try {
      await platform.invokeMethod<int>('startAlarm');

    } on PlatformException catch (e) {
      print(e.toString());
    }

  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      //App is not visible anymore... should stop ui updaters if any
    } else if (state == AppLifecycleState.resumed) {
      //we need to re-connect to our running service when the app is visible
      connectToService();
    }
  }

  @override
  void initState() {
    super.initState();
    //initPlatformState();

    //Native Android Service Binding
    WidgetsBinding.instance?.addObserver(this);
    connectToService();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    if (!mounted) return;

    OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);

    OneSignal.shared.setRequiresUserPrivacyConsent(_requireConsent);

    OneSignal.shared
        .setNotificationOpenedHandler((OSNotificationOpenedResult result) {

      print('NOTIFICATION OPENED HANDLER CALLED WITH: ${result}');
      this.setState(() {
        _debugLabelString =
        "Opened notification: \n${result.notification.jsonRepresentation().replaceAll("\\n", "\n")}";
      });
    });

    OneSignal.shared
        .setNotificationWillShowInForegroundHandler((OSNotificationReceivedEvent event) {

      print('FOREGROUND HANDLER CALLED WITH: ${event}');
      /// Display Notification, send null to not display
      event.complete(null);

      this.setState(() {
        _debugLabelString =
        "Notification received in foreground notification: \n${event.notification.jsonRepresentation().replaceAll("\\n", "\n")}";
      });
    });

    OneSignal.shared
        .setInAppMessageClickedHandler((OSInAppMessageAction action) {
      this.setState(() {
        _debugLabelString =
        "In App Message Clicked: \n${action.jsonRepresentation().replaceAll("\\n", "\n")}";
      });
    });

    OneSignal.shared
        .setSubscriptionObserver((OSSubscriptionStateChanges changes) {
      print("SUBSCRIPTION STATE CHANGED: ${changes.jsonRepresentation()}");
    });

    OneSignal.shared.setPermissionObserver((OSPermissionStateChanges changes) {
      print("PERMISSION STATE CHANGED: ${changes.jsonRepresentation()}");
    });

    OneSignal.shared.setEmailSubscriptionObserver(
            (OSEmailSubscriptionStateChanges changes) {
          print("EMAIL SUBSCRIPTION STATE CHANGED ${changes.jsonRepresentation()}");
        });

    OneSignal.shared.setSMSSubscriptionObserver(
            (OSSMSSubscriptionStateChanges changes) {
          print("SMS SUBSCRIPTION STATE CHANGED ${changes.jsonRepresentation()}");
        });

    // NOTE: Replace with your own app ID from https://www.onesignal.com
    await OneSignal.shared
        .setAppId("a9956a33-3fbd-4063-bd6f-aa634ca5c256");

    bool requiresConsent = await OneSignal.shared.requiresUserPrivacyConsent();

    this.setState(() {
      _enableConsentButton = requiresConsent;
    });

    // Some examples of how to use In App Messaging public methods with OneSignal SDK
    oneSignalInAppMessagingTriggerExamples();

    OneSignal.shared.disablePush(false);

    // Some examples of how to use Outcome Events public methods with OneSignal SDK
    oneSignalOutcomeEventsExamples();

    bool userProvidedPrivacyConsent = await OneSignal.shared.userProvidedPrivacyConsent();
    print("USER PROVIDED PRIVACY CONSENT: $userProvidedPrivacyConsent");
  }

  void _handleGetTags() {
    OneSignal.shared.getTags().then((tags) {
      if (tags == null) return;

      setState((() {
        _debugLabelString = "$tags";
      }));
    }).catchError((error) {
      setState(() {
        _debugLabelString = "$error";
      });
    });
  }

  void _handleSendTags() {
    print("Sending tags");
    OneSignal.shared.sendTag("test2", "val2").then((response) {
      print("Successfully sent tags with response: $response");
    }).catchError((error) {
      print("Encountered an error sending tags: $error");
    });

    print("Sending tags array");
    var sendTags = {'test': 'value'};
    OneSignal.shared.sendTags(sendTags).then((response) {
      print("Successfully sent tags with response: $response");
    }).catchError((error) {
      print("Encountered an error sending tags: $error");
    });
  }

  void _handlePromptForPushPermission() {
    print("Prompting for Permission");
    OneSignal.shared.promptUserForPushNotificationPermission().then((accepted) {
      print("Accepted permission: $accepted");
    });
  }

  void _handleGetDeviceState() async {
    print("Getting DeviceState");
    OneSignal.shared.getDeviceState().then((deviceState) {
      print("DeviceState: ${deviceState?.jsonRepresentation()}");
      this.setState(() {
        _debugLabelString = deviceState?.jsonRepresentation() ?? "Device state null";
      });
    });
  }

  void _handleSetEmail() {
    if (_emailAddress == null) return;

    print("Setting email");

    OneSignal.shared.setEmail(email: _emailAddress!).whenComplete(() {
      print("Successfully set email");
    }).catchError((error) {
      print("Failed to set email with error: $error");
    });
  }

  void _handleLogoutEmail() {
    print("Logging out of email");

    OneSignal.shared.logoutEmail().then((v) {
      print("Successfully logged out of email");
    }).catchError((error) {
      print("Failed to log out of email: $error");
    });
  }

  void _handleSetSMSNumber() {
    if (_smsNumber == null) return;

    print("Setting SMS Number");

    OneSignal.shared.setSMSNumber(smsNumber: _smsNumber!).then((response) {
      print("Successfully set SMSNumber with response $response");
    }).catchError((error) {
      print("Failed to set SMS Number with error: $error");
    });
  }

  void _handleLogoutSMSNumber() {
    print("Logging out of smsNumber");

    OneSignal.shared.logoutSMSNumber().then((response) {
      print("Successfully logoutEmail with response $response");
    }).catchError((error) {
      print("Failed to log out of SMSNumber: $error");
    });
  }

  void _handleConsent() {
    print("Setting consent to true");
    OneSignal.shared.consentGranted(true);

    print("Setting state");
    this.setState(() {
      _enableConsentButton = false;
    });
  }

  void _handleSetLocationShared() {
    print("Setting location shared to true");
    OneSignal.shared.setLocationShared(true);
  }

  void _handleDeleteTag() {
    print("Deleting tag");
    OneSignal.shared.deleteTag("test2").then((response) {
      print("Successfully deleted tags with response $response");
    }).catchError((error) {
      print("Encountered error deleting tag: $error");
    });

    print("Deleting tags array");
    OneSignal.shared.deleteTags(['test']).then((response) {
      print("Successfully sent tags with response: $response");
    }).catchError((error) {
      print("Encountered an error sending tags: $error");
    });
  }

  void _handleSetExternalUserId() {
    print("Setting external user ID");
    if (_externalUserId == null) return;

    OneSignal.shared.setExternalUserId(_externalUserId!).then((results) {
      if (results == null) return;

      this.setState(() {
        _debugLabelString = "External user id set: $results";
      });
    });
  }

  void _handleRemoveExternalUserId() {
    OneSignal.shared.removeExternalUserId().then((results) {
      if (results == null) return;

      this.setState(() {
        _debugLabelString = "External user id removed: $results";
      });
    });
  }

  void _handleSendNotification() async {
    var deviceState = await OneSignal.shared.getDeviceState();

    if (deviceState == null || deviceState.userId == null)
      return;

    var playerId = deviceState.userId!;

    var imgUrlString =
        "http://cdn1-www.dogtime.com/assets/uploads/gallery/30-impossibly-cute-puppies/impossibly-cute-puppy-2.jpg";

    var notification = OSCreateNotification(
        playerIds: [playerId],
        content: "this is a test from OneSignal's Flutter SDK",
        heading: "Test Notification",
        iosAttachments: {"id1": imgUrlString},
        bigPicture: imgUrlString,
        buttons: [
          OSActionButton(text: "test1", id: "id1"),
          OSActionButton(text: "test2", id: "id2")
        ]);

    var response = await OneSignal.shared.postNotification(notification);

    this.setState(() {
      _debugLabelString = "Sent notification with response: $response";
    });
  }

  void _handleSendSilentNotification() async {
    var deviceState = await OneSignal.shared.getDeviceState();

    if (deviceState == null || deviceState.userId == null)
      return;

    var playerId = deviceState.userId!;

    var notification = OSCreateNotification.silentNotification(
        playerIds: [playerId], additionalData: {'test': 'value'});

    var response = await OneSignal.shared.postNotification(notification);

    this.setState(() {
      _debugLabelString = "Sent notification with response: $response";
    });
  }

  void _handlePlayRingtone() async {
    FlutterRingtonePlayer.playNotification();
  }

  void _handleFlushbar({String title = "Flushbar Title", String message = "Lorem Ipsum is simply dummy text of the printing and typesetting industry"}) async {
    Flushbar(
      title:  title,
      message:  message,
      duration:  Duration(seconds: 3),
    )..show(context);
  }

  void _handleStopServiceAlarm() async {


    int serviceData = await stopServiceAlarm() ?? 0;

    _handleFlushbar(title:"Service data received", message: "Service data: ${serviceData}");

    setState(() {
      _debugLabelString = 'Service returned data: ${serviceData}';
    });
  }

  void _handleStartServiceAlarm() async {
    await startServiceAlarm();
  }

  void _handleVibration() async {
    bool? hasVibrator = await Vibration.hasVibrator();

    //no vibrator, or resource is dead...
    if(hasVibrator == null)
      return;

    if (hasVibrator) {

      bool? hasCustomVibratorSupport = await Vibration.hasCustomVibrationsSupport();

      if (hasCustomVibratorSupport == null || !hasCustomVibratorSupport) {
        vibrateWithoutDurationSupport(5);
      } else {
        Vibration.vibrate(duration: 1000);
      }
    }
  }

  void vibrateWithoutDurationSupport(int cycles) async{
    for(var i = 0; i < cycles; i++) {
      Vibration.vibrate();
      await Future.delayed(Duration(milliseconds: 500));
    }
  }

  oneSignalInAppMessagingTriggerExamples() async {
    /// Example addTrigger call for IAM
    /// This will add 1 trigger so if there are any IAM satisfying it, it
    /// will be shown to the user
    OneSignal.shared.addTrigger("trigger_1", "one");

    /// Example addTriggers call for IAM
    /// This will add 2 triggers so if there are any IAM satisfying these, they
    /// will be shown to the user
    Map<String, Object> triggers = new Map<String, Object>();
    triggers["trigger_2"] = "two";
    triggers["trigger_3"] = "three";
    OneSignal.shared.addTriggers(triggers);

    // Removes a trigger by its key so if any future IAM are pulled with
    // these triggers they will not be shown until the trigger is added back
    OneSignal.shared.removeTriggerForKey("trigger_2");

    // Get the value for a trigger by its key
    Object? triggerValue = await OneSignal.shared.getTriggerValueForKey("trigger_3");
    print("'trigger_3' key trigger value: ${triggerValue?.toString()}");

    // Create a list and bulk remove triggers based on keys supplied
    List<String> keys = ["trigger_1", "trigger_3"];
    OneSignal.shared.removeTriggersForKeys(keys);

    // Toggle pausing (displaying or not) of IAMs
    OneSignal.shared.pauseInAppMessages(false);
  }

  oneSignalOutcomeEventsExamples() async {
    // Await example for sending outcomes
    outcomeAwaitExample();

    // Send a normal outcome and get a reply with the name of the outcome
    OneSignal.shared.sendOutcome("normal_1");
    OneSignal.shared.sendOutcome("normal_2").then((outcomeEvent) {
      print(outcomeEvent.jsonRepresentation());
    });

    // Send a unique outcome and get a reply with the name of the outcome
    OneSignal.shared.sendUniqueOutcome("unique_1");
    OneSignal.shared.sendUniqueOutcome("unique_2").then((outcomeEvent) {
      print(outcomeEvent.jsonRepresentation());
    });

    // Send an outcome with a value and get a reply with the name of the outcome
    OneSignal.shared.sendOutcomeWithValue("value_1", 3.2);
    OneSignal.shared.sendOutcomeWithValue("value_2", 3.9).then((outcomeEvent) {
      print(outcomeEvent.jsonRepresentation());
    });
  }

  Future<void> outcomeAwaitExample() async {
    var outcomeEvent = await OneSignal.shared.sendOutcome("await_normal_1");
    print(outcomeEvent.jsonRepresentation());
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
          appBar: new AppBar(
            title: const Text('OneSignal Flutter Demo'),
            backgroundColor: Color.fromARGB(255, 212, 86, 83),
          ),
          body: Container(
            padding: EdgeInsets.all(10.0),
            child: SingleChildScrollView(
              child: new Table(
                children: [
                  new TableRow(children: [
                    new HandableButton(
                        "Get Tags", _handleGetTags, !_enableConsentButton)
                  ]),
                  new TableRow(children: [
                    new HandableButton(
                        "Send Tags", _handleSendTags, !_enableConsentButton)
                  ]),
                  new TableRow(children: [
                    new HandableButton("Prompt for Push Permission",
                        _handlePromptForPushPermission, !_enableConsentButton)
                  ]),
                  new TableRow(children: [
                    new HandableButton(
                        "Print Device State",
                        _handleGetDeviceState,
                        !_enableConsentButton)
                  ]),
                  new TableRow(children: [
                    new TextField(
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                          hintText: "Email Address",
                          labelStyle: TextStyle(
                            color: Color.fromARGB(255, 212, 86, 83),
                          )),
                      onChanged: (text) {
                        this.setState(() {
                          _emailAddress = text == "" ? null : text;
                        });
                      },
                    )
                  ]),
                  new TableRow(children: [
                    Container(
                      height: 8.0,
                    )
                  ]),
                  new TableRow(children: [
                    new HandableButton(
                        "Set Email", _handleSetEmail, !_enableConsentButton)
                  ]),
                  new TableRow(children: [
                    new HandableButton("Logout Email", _handleLogoutEmail,
                        !_enableConsentButton)
                  ]),
                  new TableRow(children: [
                    new TextField(
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                          hintText: "SMS Number",
                          labelStyle: TextStyle(
                            color: Color.fromARGB(255, 212, 86, 83),
                          )),
                      onChanged: (text) {
                        this.setState(() {
                          _smsNumber = text == "" ? null : text;
                        });
                      },
                    )
                  ]),
                  new TableRow(children: [
                    Container(
                      height: 8.0,
                    )
                  ]),
                  new TableRow(children: [
                    new HandableButton(
                        "Set SMS Number", _handleSetSMSNumber, !_enableConsentButton)
                  ]),
                  new TableRow(children: [
                    new HandableButton("Logout SMS Number", _handleLogoutSMSNumber,
                        !_enableConsentButton)
                  ]),
                  new TableRow(children: [
                    new HandableButton("Provide GDPR Consent", _handleConsent,
                        _enableConsentButton)
                  ]),
                  new TableRow(children: [
                    new HandableButton("Set Location Shared",
                        _handleSetLocationShared, !_enableConsentButton)
                  ]),
                  new TableRow(children: [
                    new HandableButton(
                        "Delete Tag", _handleDeleteTag, !_enableConsentButton)
                  ]),
                  new TableRow(children: [
                    new HandableButton("Post Notification",
                        _handleSendNotification, !_enableConsentButton)
                  ]),
                  new TableRow(children: [
                    new HandableButton("Post Silent Notification",
                        _handleSendSilentNotification, !_enableConsentButton)
                  ]),
                  new TableRow(children: [
                    new TextField(
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                          hintText: "External User ID",
                          labelStyle: TextStyle(
                            color: Color.fromARGB(255, 212, 86, 83),
                          )),
                      onChanged: (text) {
                        this.setState(() {
                          _externalUserId = text == "" ? null : text;
                        });
                      },
                    )
                  ]),
                  new TableRow(children: [
                    Container(
                      height: 8.0,
                    )
                  ]),
                  new TableRow(children: [
                    new HandableButton(
                        "Set External User ID", _handleSetExternalUserId, !_enableConsentButton)
                  ]),
                  new TableRow(children: [
                    new HandableButton(
                        "Remove External User ID", _handleRemoveExternalUserId, !_enableConsentButton)
                  ]),



                  new TableRow(children: [
                    new TextField(
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                          hintText: "NotificationCenter",
                          labelStyle: TextStyle(
                            color: Color.fromARGB(255, 212, 86, 83),
                          )),
                      onChanged: (text) {
                        this.setState(() {

                        });
                      },
                    )
                  ]),
                  new TableRow(children: [
                    Container(
                      height: 8.0,
                    )
                  ]),
                  new TableRow(children: [
                    new HandableButton(
                        "Play Ringtone", _handlePlayRingtone, !_enableConsentButton)
                  ]),
                  new TableRow(children: [
                    new HandableButton(
                        "Vibrate", _handleVibration, !_enableConsentButton)
                  ]),
                  new TableRow(children: [
                    new HandableButton(
                        "Show Flushbar", _handleFlushbar, !_enableConsentButton)
                  ]),
                  new TableRow(children: [
                    new HandableButton(
                        "Start service alarm", _handleStartServiceAlarm, !_enableConsentButton)
                  ]),
                  new TableRow(children: [
                    new HandableButton(
                        "Stop service alarm", _handleStopServiceAlarm, !_enableConsentButton)
                  ]),



                  new TableRow(children: [
                    new Container(
                      child: new Text(_debugLabelString),
                      alignment: Alignment.center,
                    )
                  ]),
                ],
              ),
            ),
          )),
    );
  }
}