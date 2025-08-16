import 'package:flutter/material.dart';

class PostcardScreen extends StatelessWidget {
  static const routeName = '/postcard';
  const PostcardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Postcard')),
      body: Center(child: Text('Postcard screen')),
    );
  }
}