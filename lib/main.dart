import 'package:flutter/material.dart';
import 'package:graphics_playground/graphics_viewport/graphics_viewport.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey.shade300,
          dynamicSchemeVariant: DynamicSchemeVariant.content,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const PlaygroundWidget(),
    );
  }
}

final class PlaygroundWidget extends StatefulWidget {
  const PlaygroundWidget({super.key});

  @override
  State<PlaygroundWidget> createState() => _PlaygroundWidgetState();
}

/// State for widget PlaygroundWidget
class _PlaygroundWidgetState extends State<PlaygroundWidget> {
  final controller = GraphicsViewportController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GraphicsViewport(controller: controller),
      floatingActionButton: FloatingActionButton.small(
        child: Icon(Icons.center_focus_strong),
        onPressed: () {
          controller.centerViewport();
        },
      ),
    );
  }
}
