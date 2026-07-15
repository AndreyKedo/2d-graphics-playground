import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graphics_playground/core/develop/performance_overlay_painter.dart';
import 'package:graphics_playground/core/graphics_viewport.dart';
import 'package:graphics_playground/core/primitive/quad_object.dart';
import 'package:graphics_playground/core/rendering/gv_scene.dart';

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
          seedColor: Colors.green.shade300,
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
  final scene = GvScene();

  bool initItemsAdd = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (initItemsAdd) {
      final theme = ColorScheme.of(context);

      scene.bulkAddItems([
        QuadPrimitiveObject(worldPosition: Offset(16, 0), backgroundColor: theme.primary),
        QuadPrimitiveObject(worldPosition: Offset(232, 0), backgroundColor: theme.primaryContainer),
        QuadPrimitiveObject(worldPosition: Offset(16, 216), backgroundColor: theme.secondaryContainer),
        QuadPrimitiveObject(worldPosition: Offset(232, 216), backgroundColor: theme.tertiaryContainer),
      ]);

      initItemsAdd = false;
    }
  }

  @override
  void dispose() {
    scene.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Builder(
        builder: (context) {
          return Drawer(
            child: GridView(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
              children: [
                GestureDetector(
                  onTap: () {
                    Scaffold.of(context).closeDrawer();
                    scene.addItem(QuadPrimitiveObject(worldPosition: Offset(-100, -100), backgroundColor: Colors.blue));
                  },
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ColoredBox(color: Colors.blue),
                    ),
                  ),
                ),
                Card(
                  child: Padding(padding: const EdgeInsets.all(8.0), child: Placeholder()),
                ),
              ],
            ),
          );
        },
      ),
      body: GraphicsViewport(
        painter: scene,
        showEditorMetrics: true,
        performanceOverlayOps: kIsWeb ? PerformanceOverlayOptionExtension.none : PerformanceOverlayOptionExtension.all,
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
