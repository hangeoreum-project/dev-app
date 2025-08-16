import 'package:flutter/material.dart';

class NextScreen extends StatelessWidget {
  static const routeName = '/next';
  const NextScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Next Page')),
      body: Center(child: Text('Next screen')),
    );
  }
}