import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  AuthProvider() {
    // Listen to auth state changes and notify listeners accordingly
    _auth.authStateChanges().listen((user) {
      notifyListeners();
    });
  }

  // Sign in with email and password
  Future<String?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners(); // Notify listeners on sign-in success
      return null; // Sign-in successful
    } on FirebaseAuthException catch (e) {
      // Handle specific error codes
      switch (e.code) {
        case 'user-not-found':
          return 'No user found for that email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-email':
          return 'The email address is not valid.';
        default:
          return 'Error signing in: ${e.message}';
      }
    } catch (e) {
      return 'An unexpected error occurred during sign-in: $e';
    }
  }

  // Sign up with email and password and store user details in Firestore
  Future<String?> signUp(String name, String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        // Save additional user data to Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        notifyListeners();
        return null; // Sign-up successful
      }
      return 'Failed to create a user account.';
    } on FirebaseAuthException catch (e) {
      // Handle Firebase sign-up errors
      switch (e.code) {
        case 'email-already-in-use':
          return 'The email is already in use by another account.';
        case 'weak-password':
          return 'The password is too weak.';
        default:
          return 'Error during sign-up: ${e.message}';
      }
    } catch (e) {
      return 'An unexpected error occurred during sign-up: $e';
    }
  }

  // Sign out the current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners(); // Notify listeners after signing out
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Get the current user's name from Firestore
  Future<String?> getUserName() async {
    if (currentUser != null) {
      try {
        DocumentSnapshot doc = await _firestore.collection('users').doc(currentUser!.uid).get();
        if (doc.exists) {
          return doc['name'] as String?;
        } else {
          return 'No user data found';
        }
      } catch (e) {
        return 'Error retrieving user name: $e';
      }
    }
    return null;
  }

  // Check if the user is logged in
  bool isLoggedIn() {
    return currentUser != null;
  }

  // Send password reset email
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return 'Password reset link sent. Please check your email.';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found for that email.';
      }
      return 'Error resetting password: ${e.message}';
    }
  }

  // Update the user's email
  Future<String?> updateEmail(String newEmail) async {
    try {
      await currentUser?.updateEmail(newEmail);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'The email address is already in use by another account.';
      }
      return 'Error updating email: ${e.message}';
    }
  }

  // Delete the user's account
  Future<String?> deleteAccount() async {
    try {
      await currentUser?.delete();
      notifyListeners();
      return 'Account successfully deleted.';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'Please log in again and try deleting the account.';
      }
      return 'Error deleting account: ${e.message}';
    }
  }
}
