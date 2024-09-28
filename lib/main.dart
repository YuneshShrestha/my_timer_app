import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_timer_app/splash_screen.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(MyApp(
    flutterLocalNotificationsPlugin: _flutterLocalNotificationsPlugin,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.flutterLocalNotificationsPlugin});
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Timer App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home:  SplashScreen(flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,),
      debugShowCheckedModeBanner: false,
    );
  }
}
