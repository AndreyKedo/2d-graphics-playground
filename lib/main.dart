import 'package:flutter/material.dart';
import 'package:graphics_playground/graphics_viewport.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Scaffold(body: GraphicsViewport()));
  }
}
