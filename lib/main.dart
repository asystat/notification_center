import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'application_toolset.dart';

import 'dart:async';


Future<void> main() async {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NotificationCenter',
      theme: ThemeData(primarySwatch: Colors.grey, brightness: Brightness.dark),
      home: Scaffold(
        body: NotificationCenter(),
      ),
    );
  }
}

class NotificationCenter extends StatefulWidget {
  @override
  ApplicationToolset createState() => new ApplicationToolset();
}

