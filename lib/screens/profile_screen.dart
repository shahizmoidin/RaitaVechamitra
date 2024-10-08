import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:raitavechamitra/screens/login_screen.dart';
import 'package:raitavechamitra/utils/localization.dart'; // Import localization

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController nameController = TextEditingController();
  bool isEditing = false;
  bool isLoading = false; // Loading state for saving and deleting

  @override
  void initState() {
    super.initState();
    if (user != null) {
      nameController.text = user!.displayName ?? ''; // Pre-fill with the current name
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('profile')), // Localized
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildProfileHeader(context),
              SizedBox(height: 20),
              _buildEditNameField(context),
              SizedBox(height: 20),
              _buildSaveButton(context),
              SizedBox(height: 40),
              _buildSignOutButton(context),
              SizedBox(height: 10),
              _buildDeleteAccountButton(context),
              if (isLoading) CircularProgressIndicator(), // Show loading indicator
            ],
          ),
        ),
      ),
    );
  }

  // Function to build Profile Header with Avatar
  Widget _buildProfileHeader(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.greenAccent[400],
          child: Text(
            user?.displayName?.isNotEmpty == true 
              ? user!.displayName!.substring(0, 1).toUpperCase() 
              : 'N', // Check for non-empty displayName
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        SizedBox(height: 10),
        Text(
          user?.displayName ?? AppLocalizations.of(context).translate('guest_user'), // Localized
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        SizedBox(height: 5),
        Text(
          '${AppLocalizations.of(context).translate('email')}: ${user?.email ?? 'N/A'}', // Localized
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
        SizedBox(height: 5),
        Text(
          '${AppLocalizations.of(context).translate('using_since')}: ${DateFormat.yMMMd().format(user?.metadata.creationTime ?? DateTime.now())}', // Localized
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
      ],
    );
  }

  // Widget to edit name
  Widget _buildEditNameField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('edit_name'), // Localized
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[700]),
        ),
        SizedBox(height: 10),
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.green[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            hintText: AppLocalizations.of(context).translate('enter_name'), // Localized
          ),
          onChanged: (value) {
            setState(() {
              isEditing = true;
            });
          },
        ),
      ],
    );
  }

  // Save Button
  Widget _buildSaveButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isEditing ? _saveDisplayName : null,
      icon: Icon(Icons.save),
      label: Text(AppLocalizations.of(context).translate('save_changes')), // Localized
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: Colors.green[700],
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }

  // Function to save the updated display name
  Future<void> _saveDisplayName() async {
    if (user != null && nameController.text.isNotEmpty) {
      setState(() {
        isLoading = true; // Start loading
      });
      try {
        await user!.updateDisplayName(nameController.text);
        await user!.reload();
        setState(() {
          isEditing = false;
          isLoading = false; // Stop loading
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate('name_updated'))), // Localized
        );
      } catch (e) {
        setState(() {
          isLoading = false; // Stop loading in case of error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).translate('failed_update_name')}: $e')), // Localized
        );
      }
    }
  }

  // Sign Out Button
  Widget _buildSignOutButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _showSignOutConfirmation(context),
      icon: Icon(Icons.logout),
      label: Text(AppLocalizations.of(context).translate('sign_out')), // Localized
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: Colors.red,
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }

  // Show confirmation dialog for signing out
  Future<void> _showSignOutConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).translate('confirm_sign_out')), // Localized
          content: Text(AppLocalizations.of(context).translate('are_you_sure_sign_out')), // Localized
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context).translate('cancel')), // Localized
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppLocalizations.of(context).translate('sign_out')), // Localized
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _signOut();
    }
  }

  // Sign Out Logic
  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).translate('error_signing_out')}: $e')), // Localized
      );
    }
  }

  // Delete Account Button
  Widget _buildDeleteAccountButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _showDeleteAccountConfirmation(context),
      icon: Icon(Icons.delete),
      label: Text(AppLocalizations.of(context).translate('delete_account')), // Localized
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: Colors.red[700],
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }

  // Show confirmation dialog for deleting account
  Future<void> _showDeleteAccountConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).translate('confirm_delete_account')), // Localized
          content: Text(AppLocalizations.of(context).translate('are_you_sure_delete')), // Localized
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context).translate('cancel')), // Localized
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppLocalizations.of(context).translate('delete')), // Localized
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _deleteAccount();
    }
  }

  // Delete Account Logic
  Future<void> _deleteAccount() async {
    if (user != null) {
      setState(() {
        isLoading = true; // Start loading
      });
      try {
        await user!.delete();
        Navigator.of(context).pushReplacementNamed('/signup');
      } catch (e) {
        setState(() {
          isLoading = false; // Stop loading in case of error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).translate('failed_delete_account')}: $e')), // Localized
        );
      }
    }
  }
}
