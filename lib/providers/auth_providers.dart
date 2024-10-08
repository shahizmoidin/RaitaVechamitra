import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// StateNotifier to handle Firebase authentication and state changes
class AuthNotifier extends StateNotifier<User?> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthNotifier() : super(FirebaseAuth.instance.currentUser) {
    // Listen to auth state changes
    _auth.authStateChanges().listen((user) {
      state = user; // Update the current user in the state
    });
  }

  // Sign in with email and password
  Future<String?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = userCredential.user; // Update the state after successful sign-in
      return null; // Sign-in successful
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
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
        state = userCredential.user; // Update the state after successful sign-up
        return null;
      }
      return 'Failed to create a user account.';
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    }
  }

  // Sign out the current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      state = null; // Update the state after sign-out
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Get the current user's name from Firestore
  Future<String?> getUserName() async {
    if (state != null) {
      try {
        DocumentSnapshot doc = await _firestore.collection('users').doc(state!.uid).get();
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

  // Send password reset email
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return 'Password reset link sent. Please check your email.';
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    }
  }

  // Update the user's email
  Future<String?> updateEmail(String newEmail) async {
    try {
      await state?.updateEmail(newEmail);
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    }
  }

  // Delete the user's account
  Future<String?> deleteAccount() async {
    try {
      await state?.delete();
      state = null; // Update state after account deletion
      return 'Account successfully deleted.';
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    }
  }

  // Handle FirebaseAuth errors
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'email-already-in-use':
        return 'The email is already in use by another account.';
      case 'weak-password':
        return 'The password is too weak.';
      default:
        return 'Error: ${e.message}';
    }
  }
}

// Riverpod provider for AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier();
});
