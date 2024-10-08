import 'package:flutter/material.dart';

import 'package:raitavechamitra/providers/auth_providers.dart';
import 'package:raitavechamitra/screens/home_screen.dart';
import 'package:raitavechamitra/screens/signup_screen.dart';
import 'package:raitavechamitra/utils/localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1F8E9),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            left: -150,
            child: _buildBackgroundCircle(300, 0.2),
          ),
          Positioned(
            bottom: -100,
            right: -150,
            child: _buildBackgroundCircle(400, 0.3),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context).translate('welcome'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.green[800],
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black38,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        _emailController,
                        AppLocalizations.of(context).translate('email'),
                        false,
                        Icons.email_outlined,
                      ),
                      SizedBox(height: 20),
                      _buildTextField(
                        _passwordController,
                        AppLocalizations.of(context).translate('password'),
                        true,
                        Icons.lock_outline,
                      ),
                      SizedBox(height: 30),
                      _isLoading
                          ? CircularProgressIndicator()
                          : _buildLoginButton(context),
                      SizedBox(height: 20),
                      _buildSignUpButton(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green.withOpacity(opacity),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    bool obscureText,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: Colors.green[900]),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.green[700]),
        labelText: label,
        labelStyle: TextStyle(color: Colors.green[800]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.greenAccent, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label cannot be empty';
        }
        if (label == "Email" && !RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading
          ? null
          : () async {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  _isLoading = true;
                });

                String? error = await ref.read(authProvider.notifier).signIn(
                      _emailController.text,
                      _passwordController.text,
                    );

                setState(() {
                  _isLoading = false;
                });

                if (error == null) {
                  _emailController.clear();
                  _passwordController.clear();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(error),
                  ));
                }
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 102, 187, 106),
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      child: Text(
        AppLocalizations.of(context).translate('login'),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSignUpButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SignUpScreen()),
        );
      },
      child: Text(
        AppLocalizations.of(context).translate('dont_have_account'),
        style: TextStyle(color: Colors.green[800], fontSize: 16),
      ),
    );
  }
}
