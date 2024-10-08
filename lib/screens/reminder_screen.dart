import 'package:flutter/material.dart';
import 'package:raitavechamitra/screens/sleep_tracker.dart';
import 'package:raitavechamitra/utils/localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthReminderScreen extends StatefulWidget {
  @override
  _HealthReminderScreenState createState() => _HealthReminderScreenState();
}

class _HealthReminderScreenState extends State<HealthReminderScreen> {
  double waterIntakeProgress = 0.0;
  DateTime _lastUpdatedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadWaterIntakeProgress();
  }

  Future<void> _loadWaterIntakeProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      waterIntakeProgress = prefs.getDouble('waterIntakeProgress') ?? 0.0;
      _lastUpdatedDate = DateTime.tryParse(prefs.getString('lastUpdatedDate') ?? '') ?? DateTime.now();
      if (!_isSameDay(DateTime.now(), _lastUpdatedDate)) {
        waterIntakeProgress = 0.0;
        _saveWaterIntakeProgress();
      }
    });
  }

  Future<void> _saveWaterIntakeProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('waterIntakeProgress', waterIntakeProgress);
    await prefs.setString('lastUpdatedDate', DateTime.now().toIso8601String());
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('health_reminders'),style: TextStyle(color: Colors.white),),
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
                AppLocalizations.of(context).translate('stay_hydrated'),
                AppLocalizations.of(context).translate('stay_hydrated_desc'),
                Icons.local_drink,
                Colors.blue,
                () => _trackWaterIntake(),
              ),
              SizedBox(height: 16),
              _buildWaterTracker(),
              SizedBox(height: 16),
              _buildHealthTipCard(
                AppLocalizations.of(context).translate('take_breaks'),
                AppLocalizations.of(context).translate('take_breaks_desc'),
                Icons.self_improvement,
                Colors.purple,
                () => _showStretchBreakInfo(),
              ),
              SizedBox(height: 16),
              _buildHealthTipCard(
                 AppLocalizations.of(context).translate('protect_uv'),
                 AppLocalizations.of(context).translate('protect_uv_desc'),
                Icons.wb_sunny,
                Colors.orange,
                () => _showUVInfo(),
              ),
              SizedBox(height: 16),
              _buildHealthTipCard(
                 AppLocalizations.of(context).translate('get_sleep'),
                 AppLocalizations.of(context).translate('get_sleep_desc'),
                Icons.bedtime,
                Colors.indigo,
                () =>   _showSleepTracker(),
              ),
              SizedBox(height: 16),
              _buildHealthTipCard(
                 AppLocalizations.of(context).translate('remedies_tips'),
                 AppLocalizations.of(context).translate('remedies_tips_desc'),
                Icons.healing,
                Colors.redAccent,
                () => _showRemedies(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthTipCard(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
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
      ),
    );
  }

  Widget _buildWaterTracker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('water_tracker'),
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
            Text('${(waterIntakeProgress * 100).toStringAsFixed(0)}%'+AppLocalizations.of(context).translate('of_daily')),
            ElevatedButton(
              onPressed: _trackWaterIntake,
              child: Text(AppLocalizations.of(context).translate('add_water_intake')),
            ),
          ],
        ),
      ],
    );
  }

  void _trackWaterIntake() {
    setState(() {
      if (waterIntakeProgress < 1.0) {
        waterIntakeProgress += 0.1;
        _saveWaterIntakeProgress();
      }
    });
  }

  void _showStretchBreakInfo() {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).translate('stretch_breaks'))),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).translate('stretch_importance'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                AppLocalizations.of(context).translate('stretch_importance_desc')
              ),
              SizedBox(height: 20),
              Text(
                 AppLocalizations.of(context).translate('stretching_exercises'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              _buildStretchExercise(AppLocalizations.of(context).translate('neck_stretch'),AppLocalizations.of(context).translate('neck_stretch_desc')),
              _buildStretchExercise(AppLocalizations.of(context).translate('shoulder_shrugs'),AppLocalizations.of(context).translate('shoulder_shrugs_desc')),
              _buildStretchExercise(AppLocalizations.of(context).translate('leg_stretch'),AppLocalizations.of(context).translate('leg_stretch_desc')),
            ],
          ),
        ),
      );
    }));
  }

  Widget _buildStretchExercise(String name, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.check, color: Colors.green),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUVInfo() {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).translate('uv_protection'))),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).translate('understand_uv'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                AppLocalizations.of(context).translate('uv_desc')
              ),
              SizedBox(height: 20),
              Text(
                 AppLocalizations.of(context).translate('uv_levels'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              _buildUVIndexInfo(AppLocalizations.of(context).translate('low_uv'), AppLocalizations.of(context).translate('low_uv_desc')),
              _buildUVIndexInfo(AppLocalizations.of(context).translate('moderate_uv'), AppLocalizations.of(context).translate('moderate_uv_desc')),
              _buildUVIndexInfo(AppLocalizations.of(context).translate('high_uv'), AppLocalizations.of(context).translate('high_uv_desc')),
              _buildUVIndexInfo(AppLocalizations.of(context).translate('very_high_uv'), AppLocalizations.of(context).translate('very_high_uv_desc')),
              _buildUVIndexInfo(AppLocalizations.of(context).translate('extreme_uv'), AppLocalizations.of(context).translate('extreme_uv_desc')),
            ],
          ),
        ),
      );
    }));
  }

  Widget _buildUVIndexInfo(String level, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.wb_sunny, color: Colors.orange),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(level, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSleepTracker() {
  Navigator.push(context, MaterialPageRoute(builder: (context) {
    return SleepTrackerScreen();
  }));
}

  void _showRemedies() {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).translate('remedies_tips'))),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).translate('remedies_tips_desc'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              _buildRemedy(AppLocalizations.of(context).translate('honey_lemon'), AppLocalizations.of(context).translate('honey_lemon_desc')),
              _buildRemedy(AppLocalizations.of(context).translate('ginger_tea'), AppLocalizations.of(context).translate('ginger_tea_desc')),
              _buildRemedy(AppLocalizations.of(context).translate('turmeric_milk'), AppLocalizations.of(context).translate('turmeric_milk_desc')),
              _buildRemedy(AppLocalizations.of(context).translate('stay_active'), AppLocalizations.of(context).translate('stay_active_desc')),
            ],
          ),
        ),
      );
    }));
  }

  Widget _buildRemedy(String name, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.local_florist, color: Colors.redAccent),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
