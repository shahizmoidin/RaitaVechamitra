import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class HealthReminderScreen extends ConsumerStatefulWidget {
  @override
  _HealthReminderScreenState createState() => _HealthReminderScreenState();
}

class _HealthReminderScreenState extends ConsumerState<HealthReminderScreen> {
  double waterIntakeProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    tz.initializeTimeZones();
  }

  void _initializeNotifications() async {
    final androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings();
    final settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await flutterLocalNotificationsPlugin.initialize(settings);
    _scheduleDailyNotifications();
  }

  void _scheduleDailyNotifications() async {
    await _scheduleNotification('Stay Hydrated!', 'Drink a glass of water now.', 9, 0);  // Morning hydration reminder
    await _scheduleNotification('Stretch Break', 'Take a few minutes to stretch and relax.', 12, 0); // Noon stretch break
    await _scheduleNotification('Healthy Eating', 'Don’t forget to eat a healthy lunch!', 14, 0);   // Afternoon eating reminder
    await _scheduleNotification('Rest and Recharge', 'Time to relax and sleep well.', 21, 0);  // Evening relaxation reminder
  }

  Future<void> _scheduleNotification(String title, String body, int hour, int minute) async {
    const androidDetails = AndroidNotificationDetails('reminder_id', 'Health Reminders', 
      importance: Importance.max);
    final iosDetails = DarwinNotificationDetails();
    final platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      platformDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Health & Safety Reminders'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[400]!, Colors.green[800]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHealthTipCard(
                'Stay Hydrated',
                'Make sure to drink water every hour, especially during long farming hours. Proper hydration is key to maintaining energy levels.',
                Icons.local_drink,
                Colors.blue,
              ),
              SizedBox(height: 16),
              _buildWaterTracker(),
              SizedBox(height: 16),
              _buildHealthTipCard(
                'Take Breaks',
                'Taking short breaks while working in the field helps prevent fatigue and muscle strain. Try to stretch every hour.',
                Icons.self_improvement,
                Colors.purple,
              ),
              SizedBox(height: 16),
              _buildStretchingReminder(),
              SizedBox(height: 16),
              _buildHealthTipCard(
                'UV Protection',
                'Be mindful of UV exposure during peak hours (10 AM - 4 PM). Wear protective clothing and apply sunscreen.',
                Icons.wb_sunny,
                Colors.orange,
              ),
              SizedBox(height: 16),
              _buildUVIndexAlert(),
              SizedBox(height: 16),
              _buildHealthTipCard(
                'Natural Remedies',
                'For cuts and scrapes, apply honey or turmeric for faster healing. Aloe vera gel works great for sunburns.',
                Icons.healing,
                Colors.teal,
              ),
              SizedBox(height: 16),
              _buildHealthTipCard(
                'Get Enough Sleep',
                'Ensure at least 7-8 hours of sleep every day to recharge your body and mind. Good sleep is essential for a productive day.',
                Icons.bedtime,
                Colors.indigo,
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthTipCard(String title, String description, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              radius: 35,
              child: Icon(icon, color: color, size: 30),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                  ),
                  SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Water Intake Tracker Widget
  Widget _buildWaterTracker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Water Intake Tracker',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        SizedBox(height: 10),
        LinearProgressIndicator(
          value: waterIntakeProgress,
          minHeight: 10,
          backgroundColor: Colors.grey[300],
          color: waterIntakeProgress >= 1.0 ? Colors.green : Colors.blue,
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${(waterIntakeProgress * 100).toStringAsFixed(0)}% of daily intake'),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (waterIntakeProgress < 1.0) {
                    waterIntakeProgress += 0.1;
                  }
                });
              },
              child: Text('Add Water Intake'),
            ),
          ],
        ),
      ],
    );
  }

  // Stretching Reminder Widget
  Widget _buildStretchingReminder() {
    return _buildHealthTipCard(
      'Stretch Every Hour',
      'Set a reminder to take a stretching break every hour. Stretching improves blood flow and prevents muscle fatigue.',
      Icons.accessibility_new,
      Colors.purple,
    );
  }

  // UV Index Alert Widget
  Widget _buildUVIndexAlert() {
    return _buildHealthTipCard(
      'UV Index Alert',
      'During peak UV index hours (10 AM - 4 PM), avoid prolonged sun exposure. Wear protective clothing and apply sunscreen.',
      Icons.wb_sunny,
      Colors.orange,
    );
  }
}
