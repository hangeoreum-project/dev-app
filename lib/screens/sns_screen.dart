import 'package:flutter/material.dart';

class SNSScreen extends StatelessWidget {
  static const routeName = '/sns';
  const SNSScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SNS Search')),
      body: Center(child: Text('SNS screen')),
    );
  }
}