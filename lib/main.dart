import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/postcard_screen.dart';
import 'screens/sns_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/next_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      routes: {
        SearchScreen.routeName: (context) => const SearchScreen(),
        PostcardScreen.routeName: (context) => const PostcardScreen(),
        SNSScreen.routeName: (context) => const SNSScreen(),
        SettingsScreen.routeName: (context) => const SettingsScreen(),
        NextScreen.routeName: (context) => const NextScreen(),
      },
    );
  }
}