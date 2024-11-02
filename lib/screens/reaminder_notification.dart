import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:raitavechamitra/providers/auth_providers.dart';
import 'package:raitavechamitra/utils/localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScheduleNotificationScreen extends ConsumerStatefulWidget {
  @override
  _ScheduleNotificationScreenState createState() => _ScheduleNotificationScreenState();
}

class _ScheduleNotificationScreenState extends ConsumerState<ScheduleNotificationScreen> {
  Timer? _notificationCheckerTimer;
  final TextEditingController _messageController = TextEditingController();
  bool _isRecurring = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  Day _selectedDay = Day.monday;
  List<Map<String, dynamic>> _scheduledNotifications = [];
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  @override
 void initState() {
    super.initState();
    _initializeLocalNotifications();
    _loadScheduledNotifications();
    _saveUserFCMToken();
    _startNotificationChecker();
  }
    @override
   void dispose() {
    _notificationCheckerTimer?.cancel(); // Cancel timer when widget is disposed
    super.dispose();
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initializationSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initializationSettings);
  }

  Future<void> _saveUserFCMToken() async {
    String? fcmToken = await _firebaseMessaging.getToken();
    final user = ref.read(authProvider);
    if (fcmToken != null && user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'fcmToken': fcmToken}, SetOptions(merge: true));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _loadScheduledNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notificationsJson = prefs.getString('scheduled_notifications');
    if (notificationsJson != null) {
      setState(() {
        _scheduledNotifications = List<Map<String, dynamic>>.from(json.decode(notificationsJson));
      });
    }
  }

  Future<void> _saveScheduledNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('scheduled_notifications', json.encode(_scheduledNotifications));
  }

  Future<void> _scheduleNotification() async {
    // Validate form inputs
    if (_messageController.text.isEmpty) {
      _showSnackBar('Please enter a message');
      return;
    } else if (_selectedDate == null) {
      _showSnackBar('Please select a date');
      return;
    } else if (_selectedTime == null) {
      _showSnackBar('Please select a time');
      return;
    }

    final user = ref.read(authProvider);
    if (user == null) {
      _showSnackBar('User not logged in');
      return;
    }

    final DateTime scheduleTime = DateTime(
      _selectedDate?.year ?? DateTime.now().year,
      _selectedDate?.month ?? DateTime.now().month,
      _selectedDate?.day ?? DateTime.now().day,
      _selectedTime?.hour ?? DateTime.now().hour,
      _selectedTime?.minute ?? DateTime.now().minute,
    );

    final notificationData = {
      'message': _messageController.text,
      'timestamp': scheduleTime.toIso8601String(),
      'isRecurring': _isRecurring,
      'day': _isRecurring ? _selectedDay.toString().split('.').last : null,
      'userId': user.uid,
    };

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('scheduled_notifications')
          .add(notificationData);

      notificationData['id'] = docRef.id;
      _addScheduledNotification(notificationData);
      _saveScheduledNotifications();
      _clearFields();

      _showSnackBar('Notification scheduled');
    } catch (e) {
      print('Error scheduling notification: $e');
      _showSnackBar('Failed to schedule notification');
    }
  }

  void _clearFields() {
    _messageController.clear();
    setState(() {
      _selectedDate = null;
      _selectedTime = null;
    });
  }

  void _addScheduledNotification(Map<String, dynamic> notificationData) {
    setState(() {
      _scheduledNotifications.add(notificationData);
    });
    _saveScheduledNotifications();
  }

  Future<void> _removeScheduledNotification(String notificationId) async {
    final user = ref.read(authProvider);
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('scheduled_notifications')
          .doc(notificationId)
          .delete();

      setState(() {
        _scheduledNotifications.removeWhere((notification) => notification['id'] == notificationId);
      });
      _saveScheduledNotifications();
      _showSnackBar('Notification deleted');
    } catch (e) {
      print('Error deleting notification: $e');
      _showSnackBar('Failed to delete notification');
    }
  }

void _startNotificationChecker() {
  // Start a timer to check for notifications every minute
  _notificationCheckerTimer = Timer.periodic(Duration(minutes: 1), (timer) async {
    // Immediately return if the widget has been disposed
    if (!mounted) {
      timer.cancel();
      return;
    }

    try {
      final now = DateTime.now();
      final user = ref.read(authProvider);

      // Return if the user is not logged in (this also avoids using ref if disposed)
      if (user == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('scheduled_notifications')
          .where('timestamp', isLessThanOrEqualTo: now.toIso8601String())
          .where('userId', isEqualTo: user.uid)
          .get();

      for (var doc in querySnapshot.docs) {
        final notification = doc.data();
        print('Sending local notification: ${notification['message']}'); // Log the message
        _showLocalNotification(notification['message']);
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error in notification checker: $e');
    }
  });
}



  Future<void> _showLocalNotification(String message) async {
    const androidDetails = AndroidNotificationDetails(
      'scheduled_channel',
      'Scheduled Notifications',
      channelDescription: 'Notifications for scheduled reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Scheduled Reminder',
      message,
      notificationDetails,
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return ListTile(
      title: Text(
        AppLocalizations.of(context).translate('select_date'),
        style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold),
      ),
      trailing: Text(
        _selectedDate != null ? DateFormat.yMMMd().format(_selectedDate!) : 'Not selected',
        style: TextStyle(color: Colors.black),
      ),
      onTap: !_isRecurring ? () => _selectDate(context) : null,
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    return ListTile(
      title: Text(
        AppLocalizations.of(context).translate('select_time'),
        style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold),
      ),
      trailing: Text(
        _selectedTime != null ? _selectedTime!.format(context) : 'Not selected',
        style: TextStyle(color: Colors.black),
      ),
      onTap: () => _selectTime(context),
    );
  }

  Widget _buildMessageField() {
    return TextField(
      controller: _messageController,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).translate('custom_message'),
        border: OutlineInputBorder(),
        fillColor: Colors.green[50],
        filled: true,
      ),
    );
  }

  Widget _buildRecurringSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppLocalizations.of(context).translate('recurring_notification'),
          style: TextStyle(fontSize: 16, color: Colors.green[800], fontWeight: FontWeight.bold),
        ),
        Switch(
          value: _isRecurring,
          onChanged: (value) {
            setState(() {
              _isRecurring = value;
            });
          },
          activeColor: Colors.green[700],
        ),
      ],
    );
  }

  Widget _buildDayOfWeekPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: DropdownButton<Day>(
        value: _selectedDay,
        onChanged: (newDay) {
          setState(() {
            _selectedDay = newDay!;
          });
        },
        items: Day.values.map((day) {
          return DropdownMenuItem<Day>(
            value: day,
            child: Text(
              AppLocalizations.of(context).translate(day.toString().split('.').last.toLowerCase()),
            ),
          );
        }).toList(),
        isExpanded: true,
      ),
    );
  }

  Widget _buildScheduleButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[700],
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: _scheduleNotification,
        child: Text(
          AppLocalizations.of(context).translate('schedule'),
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildScheduledNotificationsList() {
    return Container(
      height: 200,
      child: ListView.builder(
        itemCount: _scheduledNotifications.length,
        itemBuilder: (context, index) {
          final notification = _scheduledNotifications[index];
          return ListTile(
            title: Text(notification['message'] ?? 'No message'),
            subtitle: Text(
              notification['isRecurring'] == true
                  ? '${AppLocalizations.of(context).translate('every')} ${notification['day']}'
                  : '${notification['timestamp']}',
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeScheduledNotification(notification['id']),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('schedule_notification'),
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[400]!, Colors.green[800]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDatePicker(context),
              SizedBox(height: 20),
              _buildTimePicker(context),
              SizedBox(height: 20),
              _buildMessageField(),
              SizedBox(height: 20),
              _buildRecurringSwitch(),
              if (_isRecurring) _buildDayOfWeekPicker(),
              SizedBox(height: 20),
              _buildScheduleButton(),
              SizedBox(height: 20),
              Text(
                AppLocalizations.of(context).translate('upcoming_notifications'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800]),
              ),
              SizedBox(height: 10),
              _buildScheduledNotificationsList(),
            ],
          ),
        ),
      ),
    );
  }
}
