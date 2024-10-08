import 'dart:convert'; // For JSON encoding and decoding
import 'package:flutter/material.dart';
import 'package:raitavechamitra/utils/localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class SleepTrackerScreen extends StatefulWidget {
  @override
  _SleepTrackerScreenState createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen> {
  bool isTracking = false;
  DateTime? _startTime;
  DateTime? _endTime;
  Duration _sleepDuration = Duration.zero;
  List<Map<String, Object>> sleepHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSleepHistory();
  }

  // Load sleep history from SharedPreferences
  Future<void> _loadSleepHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final sleepHistoryData = prefs.getStringList('sleepHistory') ?? [];

    setState(() {
      sleepHistory = sleepHistoryData.map((entry) {
        final sleepEntry = jsonDecode(entry) as Map<String, dynamic>;
        return {
          'start': DateTime.parse(sleepEntry['start']),
          'end': DateTime.parse(sleepEntry['end']),
          'duration': Duration(seconds: sleepEntry['duration']),
        };
      }).toList();
    });
  }

  // Save sleep history to SharedPreferences
  Future<void> _saveSleepHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final sleepHistoryData = sleepHistory.map((entry) {
      return jsonEncode({
        'start': (entry['start'] as DateTime).toIso8601String(),
        'end': (entry['end'] as DateTime).toIso8601String(),
        'duration': (entry['duration'] as Duration).inSeconds,
      });
    }).toList();

    await prefs.setStringList('sleepHistory', sleepHistoryData);
  }

  // Start tracking sleep
  void _startTracking() {
    setState(() {
      isTracking = true;
      _startTime = DateTime.now();
      _endTime = null;
      _sleepDuration = Duration.zero;
    });
  }

  // Stop tracking sleep and calculate duration
  void _stopTracking() {
    if (_startTime == null) return; // Safety check

    setState(() {
      isTracking = false;
      _endTime = DateTime.now();
      _sleepDuration = _endTime!.difference(_startTime!);

      // Add the sleep record to history
      sleepHistory.add({
        'start': _startTime!,
        'end': _endTime!,
        'duration': _sleepDuration,
      });

      _saveSleepHistory();
    });
  }

  // Format duration to HH:MM:SS
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  // UI Design Improvements
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('app_title')),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo[400]!, Colors.indigo[800]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSleepTrackerHeader(),
            SizedBox(height: 20),
            _buildSleepHistoryHeader(),
            SizedBox(height: 10),
            _buildSleepHistoryList(),
          ],
        ),
      ),
    );
  }

  // Header section for Sleep Tracker
  Widget _buildSleepTrackerHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isTracking ? AppLocalizations.of(context).translate('tracking_sleep') :  AppLocalizations.of(context).translate('sleep_tracker'),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          if (isTracking)
            Column(
              children: [
                Text(
                  AppLocalizations.of(context).translate('started_at')+': ${_startTime != null ? _startTime!.toLocal().toString().split('.')[0] : ''}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _stopTracking,
                  child: Text(AppLocalizations.of(context).translate('stop_tracking')),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                ElevatedButton(
                  onPressed: _startTracking,
                  child: Text(AppLocalizations.of(context).translate('start_tracking')),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Colors.greenAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (_sleepDuration != Duration.zero)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                     AppLocalizations.of(context).translate('last_sleep_duration')+': ${formatDuration(_sleepDuration)}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // Header for Sleep History Section
  Widget _buildSleepHistoryHeader() {
    return Text(
      AppLocalizations.of(context).translate('sleep_history'),
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo[800]),
    );
  }

  // Sleep History List Section
  Widget _buildSleepHistoryList() {
    return Expanded(
      child: sleepHistory.isEmpty
          ? Center(child: Text( AppLocalizations.of(context).translate('no_sleep_history')))
          : ListView.builder(
              itemCount: sleepHistory.length,
              itemBuilder: (context, index) {
                final sleepRecord = sleepHistory[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.bedtime, color: Colors.indigo[600]),
                    title: Text(
                      AppLocalizations.of(context).translate('start_time')+' ${(sleepRecord['start'] as DateTime).toLocal().toString().split('.')[0]}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context).translate('end_time')+' ${(sleepRecord['end'] as DateTime).toLocal().toString().split('.')[0]}\nDuration: ${formatDuration(sleepRecord['duration'] as Duration)}',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
