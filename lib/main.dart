import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graphics_playground/core/develop/performance_overlay_painter.dart';
import 'package:graphics_playground/core/graphics_viewport.dart';
import 'package:graphics_playground/core/primitive/quad_object.dart';

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
  final quadPrimitivePainter = QuadPrimitiveObject();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: GridView(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
          children: [
            Card(
              child: Padding(padding: const EdgeInsets.all(8.0), child: Placeholder()),
            ),
            Card(
              child: Padding(padding: const EdgeInsets.all(8.0), child: Placeholder()),
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints.tightFor(width: 800, height: 600),
          child: GraphicsViewport(
            painter: quadPrimitivePainter,
            showEditorMetrics: true,
            performanceOverlayOps: kIsWeb
                ? PerformanceOverlayOptionExtension.none
                : PerformanceOverlayOptionExtension.all,
          ),
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 32,
            children: [
              FloatingActionButton.small(
                child: Icon(Icons.menu_rounded),
                onPressed: () {
                  if (Scaffold.hasDrawer(context)) {
                    Scaffold.of(context).openDrawer();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
