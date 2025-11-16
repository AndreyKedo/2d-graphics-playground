import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:graphics_playground/graphics_viewport/gv_painter.dart';
import 'package:graphics_playground/graphics_viewport/painter_context.dart';

class AxisPainter extends GvPainterMixin {
  AxisPainter();

  final dxAxisPainter = Paint()..color = Colors.red;
  final dyAxisPainter = Paint()..color = Colors.green;
  final crossPainter = Paint()..color = Colors.black;

  final crossAxisPosition = Float32List.fromList([-4, 0, 4, 0, 0, -4, 0, 4]);

  @override
  void paint(GVPainterContext context) {
    final (:canvas, :viewport) = context.expanded;

    final screenOrigin = viewport.worldToScreen(Offset.zero);

    final drawDyAxis = screenOrigin.dx >= 0 && screenOrigin.dx < viewport.viewportSize.width;
    final drawDxAxis = screenOrigin.dy >= 0 && screenOrigin.dy < viewport.viewportSize.height;

    if (!drawDxAxis && !drawDyAxis) return;
    final viewportRect = viewport.getWorldRect();
    //print("Draw axis Y $drawDyAxis; Draw axis X $drawDxAxis; Draw cross axis ${drawDxAxis && drawDyAxis}");
    canvas.save();
    if (drawDxAxis) {
      canvas.drawRawPoints(
        PointMode.lines,
        Float32List.fromList([viewportRect.left, 0, viewportRect.right, 0]),
        dxAxisPainter..strokeWidth = 1.0 / viewport.zoom,
      );
    }

    if (drawDyAxis) {
      canvas.drawRawPoints(
        PointMode.lines,
        Float32List.fromList([0, viewportRect.bottom, 0, viewportRect.top]),
        dyAxisPainter..strokeWidth = 1.0 / viewport.zoom,
      );
    }

    if (drawDxAxis && drawDyAxis) {
      canvas.drawRawPoints(PointMode.lines, crossAxisPosition, crossPainter..strokeWidth = 1.5 / viewport.zoom);
    }

    canvas.restore();
  }
}
