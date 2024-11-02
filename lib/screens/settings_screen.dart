import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:raitavechamitra/providers/local_provider.dart';
import 'package:raitavechamitra/utils/localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raitavechamitra/screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // No need to load or save notification settings
  }

  // Language Selection Handler
  void _selectLanguage(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.green[50], // Light green background
          title: Text(
            AppLocalizations.of(context).translate('select_language'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green[800], // Dark green color for the title
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.language, color: Colors.green),
                  title: Text(
                    AppLocalizations.of(context).translate('eng'),
                    style: TextStyle(fontSize: 18),
                  ),
                  onTap: () {
                    context.read<LocaleProvider>().setLocale(Locale('en'));
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.language, color: Colors.green),
                  title: Text(
                    AppLocalizations.of(context).translate('kan'),
                    style: TextStyle(fontSize: 18),
                  ),
                  onTap: () {
                    context.read<LocaleProvider>().setLocale(Locale('kn'));
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.language, color: Colors.green),
                  title: Text(
                    AppLocalizations.of(context).translate('hin'),
                    style: TextStyle(fontSize: 18),
                  ),
                  onTap: () {
                    context.read<LocaleProvider>().setLocale(Locale('hi'));
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                AppLocalizations.of(context).translate('cancel'),
                style: TextStyle(color: Colors.green[800]),
              ),
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('settings')),
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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSettingOption(
            context,
            title: AppLocalizations.of(context).translate('reset_password'),
            icon: Icons.lock_reset,
            onTap: () => _resetPassword(context),
          ),
          _buildSettingOption(
            context,
            title: AppLocalizations.of(context).translate('delete_account'),
            icon: Icons.delete_forever,
            onTap: () => _confirmDeleteAccount(context),
            color: Colors.redAccent,
          ),
          Divider(),
          _buildSettingOption(
            context,
            title: AppLocalizations.of(context).translate('sign_out'),
            icon: Icons.logout,
            onTap: _signOut,
          ),
          Divider(),
          _buildSettingOption(
            context,
            title: AppLocalizations.of(context).translate('language'),
            icon: Icons.language,
            onTap: () => _selectLanguage(context),
          ),
        ],
      ),
    );
  }

  // Reusable Setting Option Widget
  Widget _buildSettingOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.black,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4,
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green[800],
          ),
        ),
        leading: Icon(icon, color: color),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  // Reset Password Functionality
  void _resetPassword(BuildContext context) async {
    if (_auth.currentUser?.email != null) {
      try {
        await _auth.sendPasswordResetEmail(email: _auth.currentUser!.email!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate('password_reset_email_sent'))),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).translate('error_sending_reset_email')}: $e')),
        );
      }
    }
  }

  // Confirm Delete Account Dialog
  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('delete_account'), style: TextStyle(color: Colors.red)),
        content: Text(AppLocalizations.of(context).translate('delete_account_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () => _deleteAccount(context),
            child: Text(AppLocalizations.of(context).translate('delete'), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Delete Account Functionality
  void _deleteAccount(BuildContext context) async {
    try {
      await _auth.currentUser?.delete();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).translate('error_deleting_account')}: $e')),
      );
    }
  }

  // Sign Out Functionality
  void _signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _auth.signOut();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }
}
