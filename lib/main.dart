import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/sns_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/postcard/postcard_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      routes: {
        '/postcard': (_) => const PostcardScreen(),
        '/sns': (_) => const SNSScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
