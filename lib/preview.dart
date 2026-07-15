import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:graphics_playground/core/develop/performance_overlay_painter.dart';
import 'package:graphics_playground/core/graphics_viewport.dart';
import 'package:graphics_playground/core/primitive/quad_object.dart';
import 'package:graphics_playground/core/rendering/gv_scene.dart';

class PreviewViewport extends StatefulWidget {
  @Preview(name: '2D Viewport')
  const PreviewViewport({super.key});

  @override
  State<PreviewViewport> createState() => _PreviewViewportState();
}

class _PreviewViewportState extends State<PreviewViewport> {
  final scene = GvScene();

  @override
  void initState() {
    super.initState();

    scene.bulkAddItems([
      QuadPrimitiveObject(worldPosition: Offset(16, 0)),
      QuadPrimitiveObject(worldPosition: Offset(232, 0), backgroundColor: Colors.amberAccent),
      QuadPrimitiveObject(worldPosition: Offset(16, 216), backgroundColor: Colors.cyan),
      QuadPrimitiveObject(worldPosition: Offset(232, 216), backgroundColor: Colors.green),
    ]);
  }

  @override
  void dispose() {
    scene.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GraphicsViewport(
      painter: scene,
      showEditorMetrics: true,
      performanceOverlayOps: kIsWeb ? PerformanceOverlayOptionExtension.none : PerformanceOverlayOptionExtension.all,
    );
  }
}
