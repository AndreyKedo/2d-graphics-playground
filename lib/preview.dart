import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:graphics_playground/core/develop/performance_overlay_painter.dart';
import 'package:graphics_playground/core/graphics_viewport.dart';
import 'package:graphics_playground/core/primitive/quad_object.dart';

class PreviewViewport extends StatefulWidget {
  @Preview(name: '2D Viewport')
  const PreviewViewport({super.key});

  @override
  State<PreviewViewport> createState() => _PreviewViewportState();
}

class _PreviewViewportState extends State<PreviewViewport> {
  final quadPrimitivePainter = QuadPrimitiveObject();

  @override
  Widget build(BuildContext context) {
    return GraphicsViewport(
      painter: quadPrimitivePainter,
      showEditorMetrics: true,
      performanceOverlayOps: kIsWeb ? PerformanceOverlayOptionExtension.none : PerformanceOverlayOptionExtension.all,
    );
  }
}
