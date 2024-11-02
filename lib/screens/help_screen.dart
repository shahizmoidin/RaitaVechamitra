import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raitavechamitra/utils/localization.dart';
import 'package:raitavechamitra/providers/local_provider.dart';

class HelpScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('help_guide_title'),  // App's title
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo
            Center(
              child: Image.asset(
                'assets/images/logo.png', // Your app's logo
                height: 100,
              ),
            ),
            SizedBox(height: 20),

            // App Introduction
            Text(
              AppLocalizations.of(context).translate('title'),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[800]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              AppLocalizations.of(context).translate('app_description'),
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 20),

            // Language Selection
            _buildLanguageSelection(context),

            SizedBox(height: 30),

            // Help Section for Income & Expense Screen
            _buildHelpSection(
              context,
              AppLocalizations.of(context).translate('income_expense'),
              AppLocalizations.of(context).translate('income_expense_description'),
            ),
            SizedBox(height: 30),

            // Help Section for Weather Screen
            _buildHelpSection(
              context,
              AppLocalizations.of(context).translate('weather_screen'),
              AppLocalizations.of(context).translate('weather_screen_description'),
            ),
            SizedBox(height: 30),

            // Help Section for Schemes Screen
            _buildHelpSection(
              context,
              AppLocalizations.of(context).translate('schemes_screen'),
              AppLocalizations.of(context).translate('schemes_screen_description'),
            ),
            SizedBox(height: 30),

            // Help Section for Health Screen
            _buildHelpSection(
              context,
              AppLocalizations.of(context).translate('health_screen'),
              AppLocalizations.of(context).translate('health_screen_description'),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Improved language selection widget with card design
  Widget _buildLanguageSelection(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.language, color: Colors.green[800]),
            SizedBox(width: 10),
            Text(
              AppLocalizations.of(context).translate('select_language'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800]),
            ),
            SizedBox(width: 20),
            DropdownButton<String>(
              value: AppLocalizations.of(context).locale.languageCode,
              onChanged: (String? languageCode) {
                if (languageCode != null) {
                  context.read<LocaleProvider>().setLocale(Locale(languageCode));
                }
              },
              items: [
                DropdownMenuItem(value: 'en', child: Text(AppLocalizations.of(context).translate('eng'))),
                DropdownMenuItem(value: 'kn', child: Text(AppLocalizations.of(context).translate('kan'))),
                DropdownMenuItem(value: 'hi', child: Text(AppLocalizations.of(context).translate('hin'))),
              ],
              icon: Icon(Icons.arrow_drop_down, color: Colors.green[800]),
              underline: Container(), // Remove default underline
              dropdownColor: Colors.green[50], // Match dropdown background
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build each section of the help guide
  Widget _buildHelpSection(BuildContext context, String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[800]),
        ),
        SizedBox(height: 10),
        Text(
          description,
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
      ],
    );
  }
}
