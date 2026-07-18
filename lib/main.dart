import 'dart:math' as math;

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
  static const _squareExtent = 200.0;
  static const _squareGap = 16.0;

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

  void _addSquareGrid(int count, ColorScheme colors) {
    final columns = math.sqrt(count).ceil();
    final rows = (count / columns).ceil();
    const stride = _squareExtent + _squareGap;
    final origin = Offset(-(columns - 1) * stride / 2, -(rows - 1) * stride / 2);
    final palette = <Color>[
      colors.primary,
      colors.primaryContainer,
      colors.secondary,
      colors.secondaryContainer,
      colors.tertiary,
      colors.tertiaryContainer,
    ];

    scene.bulkAddItems(
      Iterable.generate(count, (index) {
        final column = index % columns;
        final row = index ~/ columns;

        return QuadPrimitiveObject(
          worldPosition: origin + Offset(column * stride, row * stride),
          backgroundColor: palette[(row + column) % palette.length],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Builder(
        builder: (context) {
          final colors = ColorScheme.of(context);

          return Drawer(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Добавить на сцену', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _SquareBatchTile(
                    count: 1,
                    color: colors.primary,
                    onPressed: () {
                      scene.addItem(
                        QuadPrimitiveObject(worldPosition: const Offset(-100, -100), backgroundColor: colors.primary),
                      );
                    },
                  ),
                  _SquareBatchTile(count: 1000, color: colors.secondary, onPressed: () => _addSquareGrid(1000, colors)),
                  _SquareBatchTile(
                    count: 10000,
                    color: colors.tertiary,
                    onPressed: () => _addSquareGrid(10000, colors),
                  ),
                ],
              ),
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

class _SquareBatchTile extends StatelessWidget {
  const _SquareBatchTile({required this.count, required this.color, required this.onPressed});

  final int count;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: SizedBox.square(dimension: 32, child: ColoredBox(color: color)),
        title: Text('$count ${count == 1 ? 'квадрат' : 'квадратов'}'),
        subtitle: count == 1 ? null : const Text('Равномерная квадратная сетка'),
        onTap: () {
          Navigator.of(context).pop();
          onPressed();
        },
      ),
    );
  }
}
