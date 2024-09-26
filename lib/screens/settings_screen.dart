import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:raitavechamitra/screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Dummy variable for demonstration; you can use a proper state management solution
  bool _notificationsEnabled = true; // Default value

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
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
          _buildNotificationOption(context),
          _buildSettingOption(
            context,
            title: 'Reset Password',
            icon: Icons.lock_reset,
            onTap: () => _resetPassword(context),
          ),
          _buildSettingOption(
            context,
            title: 'Delete Account',
            icon: Icons.delete_forever,
            onTap: () => _confirmDeleteAccount(context),
            color: Colors.redAccent,
          ),
          Divider(),
          _buildSettingOption(
            context,
            title: 'Sign Out',
            icon: Icons.logout,
            onTap: _signOut,
          ),
          Divider(),
          _buildSettingOption(
            context,
            title: 'Language',
            icon: Icons.language,
            onTap: _changeLanguage,
          ),
        ],
      ),
    );
  }

  // Notification Settings Option
  Widget _buildNotificationOption(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4,
      child: ListTile(
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green[800],
          ),
        ),
        trailing: Switch(
          value: _notificationsEnabled,
          onChanged: (value) {
            setState(() {
              _notificationsEnabled = value;
            });
          },
          activeColor: Colors.green,
        ),
      ),
    );
  }

  // Reusable Setting Option Widget with improved design
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
          SnackBar(content: Text('Password reset email sent!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending reset email: $e')),
        );
      }
    }
  }

  // Confirm Delete Account Dialog
  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account', style: TextStyle(color: Colors.red)),
        content: Text('Are you sure you want to delete your account? This action is irreversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _deleteAccount(context),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
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
        SnackBar(content: Text('Error deleting account: $e')),
      );
    }
  }

  // Sign Out Functionality
  void _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  // Change Language Functionality
  void _changeLanguage() {
    // Handle language change logic here
  }
}
