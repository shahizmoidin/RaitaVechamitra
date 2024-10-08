import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod; // Use a prefix for Riverpod
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Firebase Messaging for notifications
import 'package:flutter_localizations/flutter_localizations.dart'; // Localization support

import 'package:raitavechamitra/providers/local_provider.dart';
import 'package:raitavechamitra/screens/splash_screen.dart';
import 'package:raitavechamitra/utils/localization.dart';


Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Firebase Messaging background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    riverpod.ProviderScope(
      
      child: ChangeNotifierProvider(
        create: (_) => LocaleProvider(), // Initialize LocaleProvider
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return  MaterialApp(
        title: 'Raitavechamitra',
        debugShowCheckedModeBanner: false,
        locale: localeProvider.locale, // Bind locale to LocaleProvider
        supportedLocales: L10n.all, // Use supported locales from L10n class
        localizationsDelegates: [
          AppLocalizations.delegate, // Custom localization delegate
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeResolutionCallback: (locale, supportedLocales) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale?.languageCode) {
              return supportedLocale;
            }
          }
          return supportedLocales.first;
        },
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(153, 47, 240, 85)),
        ),
        home: SplashScreen(), // Splash screen as the starting point
      );
    
  }
}
