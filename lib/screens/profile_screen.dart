import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
        title: Text("Profile"),
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
              _buildProfileHeader(),
              SizedBox(height: 20),
              _buildEditNameField(),
              SizedBox(height: 20),
              _buildSaveButton(),
              SizedBox(height: 40),
              _buildSignOutButton(),
              SizedBox(height: 10),
              _buildDeleteAccountButton(),
              if (isLoading) CircularProgressIndicator(), // Show loading indicator
            ],
          ),
        ),
      ),
    );
  }

  // Function to build Profile Header with Avatar
  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.greenAccent[400],
          child: Text(
            user?.displayName?.isNotEmpty == true ? 
            user!.displayName!.substring(0, 1).toUpperCase() : 'N', // Check for non-empty displayName
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        SizedBox(height: 10),
        Text(
          user?.displayName ?? 'Guest User',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        SizedBox(height: 5),
        Text(
          'Email: ${user?.email ?? 'N/A'}',
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
        SizedBox(height: 5),
        Text(
          'Using Since: ${DateFormat.yMMMd().format(user?.metadata.creationTime ?? DateTime.now())}',
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
      ],
    );
  }

  // Widget to edit name
  Widget _buildEditNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edit Name',
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
            hintText: 'Enter your name',
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
  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: isEditing ? _saveDisplayName : null,
      icon: Icon(Icons.save),
      label: Text('Save Changes'),
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
          SnackBar(content: Text('Name updated successfully!')),
        );
      } catch (e) {
        setState(() {
          isLoading = false; // Stop loading in case of error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update name: $e')),
        );
      }
    }
  }

  // Sign Out Button
  Widget _buildSignOutButton() {
    return ElevatedButton.icon(
      onPressed: () => _showSignOutConfirmation(),
      icon: Icon(Icons.logout),
      label: Text('Sign Out'),
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
  Future<void> _showSignOutConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Sign Out'),
          content: Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Sign Out'),
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
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  // Delete Account Button
  Widget _buildDeleteAccountButton() {
    return ElevatedButton.icon(
      onPressed: () => _showDeleteAccountConfirmation(),
      icon: Icon(Icons.delete),
      label: Text('Delete Account'),
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
  Future<void> _showDeleteAccountConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Account Deletion'),
          content: Text('Are you sure you want to delete your account? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete Account'),
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
          SnackBar(content: Text('Failed to delete account: $e')),
        );
      }
    }
  }
}
