import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_timer_app/second_page.dart';
import 'package:rive/rive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Artboard? _riveArtboard;
  SMITrigger? _startTrigger;
  SMITrigger? _stopTrigger;
  SMITrigger? _resetTrigger;
  int _ringAt = 20;
  var _isPlaying = false;
  Timer? _timer;
  int _start = 60; // Example start time of 10 seconds

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final scaffoldState = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await loadRiveFile();
      _initializeNotification();
      _loadTimerState();
    });
  }

  Future<void> loadRiveFile() async {
    final data = await rootBundle.load('asset/rive/timer.riv');
    try {
      final file = RiveFile.import(data);
      setState(() {
        _riveArtboard = file.mainArtboard;
        if (_riveArtboard != null) {
          var controller = StateMachineController.fromArtboard(
              _riveArtboard!, 'State Machine 1');
          if (controller != null) {
            _riveArtboard!.addController(controller);
            _startTrigger = controller.findSMI("Start");
            _stopTrigger = controller.findSMI("Stop");
            _resetTrigger = controller.findSMI("Reset");
          }
        }
      });
    } catch (e) {
      print('Error loading Rive file: $e');
    }
  }

  void _initializeNotification() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _start =
          prefs.getInt('timer') ?? 60; // Load saved time or default to 4000
    });
  }

  void _saveTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('timer', _start);
  }

  Future<void> scheduleNotification(int id, String title, String body,
      DateTime scheduledNotificationDateTime) async {
    if (scheduledNotificationDateTime.isBefore(DateTime.now())) {
      throw ArgumentError('Scheduled date must be in the future.');
    }

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledNotificationDateTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'your_channel_id',
            'your_channel_name',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: id.toString(),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      print("Error scheduling notification: $e");
    }
  }

  void _showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('timer_notification', 'Timer Notification',
            channelDescription: 'Notification channel for timer',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false);
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Timer Update',
      'Time left: $_start seconds',
      platformChannelSpecifics,
    );
  }

  Future<void> stopTimer() async {
    _timer?.cancel();
    _stopTrigger?.fire();
    await Future.delayed(const Duration(seconds: 2), () {
      _resetTrigger?.fire();
    });
  }

  void startTimer() {
    _startTrigger?.fire();
    setState(() {});

    const oneSec = Duration(seconds: 1);
    _timer?.cancel(); // Cancel any previous timer
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
          });
        } else {
          setState(() {
            _start--;
            _saveTimerState();
            if (_start == _ringAt) {
              _showNotification();
              scheduleNotification(
                0,
                'Timer Alert',
                'Your timer has reached $_ringAt seconds',
                DateTime.now().add(Duration(seconds: _ringAt)),
              );
            }
          });
        }
      },
    );
  }

  void _showBottomSheet() {
    int dummyRingAt = _ringAt;
    scaffoldState.currentState!.showBottomSheet(
      (context) => StatefulBuilder(
        builder: (context, setstate) => SizedBox(
          height: 200,
          child: Column(
            children: [
              Text('Set ring time : $dummyRingAt seconds'),
              Slider(
                value: dummyRingAt.toDouble(),
                min: 0,
                max: 60,
                onChanged: (value) {
                  setstate(() {
                    dummyRingAt = value.toInt();
                  });
                },
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _ringAt = dummyRingAt;
                  }); // Ensure the state is updated after closing the bottom sheet
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldState,
      appBar: AppBar(
        title: Text('Timer Example'),
        actions: [
          IconButton(
            icon: Icon(Icons.navigate_next),
            onPressed: () {
              Navigator.of(context).push(_createRoute());
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Timer rings at $_ringAt seconds',
                  style: const TextStyle(fontSize: 20),
                ),
                IconButton(
                    onPressed: () {
                      _showBottomSheet();
                    },
                    icon: const Icon(Icons.edit)),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: SizedBox(
                height: 200,
                width: 200,
                child: _riveArtboard != null
                    ? Rive(artboard: _riveArtboard!)
                    : const SizedBox(),
              ),
            ),
            Text(
              'Time: $_start',
              style: TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isPlaying = !_isPlaying;
            if (_isPlaying) {
              startTimer();
            } else {
              stopTimer();
            }
          });
        },
        tooltip: 'Start Timer',
        child: _isPlaying ? Icon(Icons.pause) : Icon(Icons.play_arrow),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel(); // Always cancel the timer to avoid memory leaks
    super.dispose();
  }
}

Route _createRoute() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => const SecondPage(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}
