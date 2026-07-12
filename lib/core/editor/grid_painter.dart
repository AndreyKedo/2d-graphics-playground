import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:graphics_playground/core/foundation/canvas_extension.dart';
import 'package:graphics_playground/core/gv_painter.dart';
import 'package:graphics_playground/core/painter_context.dart';

class GridPainter extends GvPainterMixin {
  GridPainter();

  final gridPainter = Paint()
    ..color = Colors.grey.withAlpha(60)
    ..style = PaintingStyle.stroke;

  late Size _viewportSize = viewport.viewportSize;
  late Offset _lastCameraPosition = viewport.position;
  late double _lastZoom = viewport.zoom;
  ui.Picture? _picture;

  void innerPaint(Canvas canvas) {
    final paint = gridPainter..strokeWidth = 1.0 / viewport.zoom;

    final viewportRect = viewport.getWorldRect();

    final gridSize = 20.0 / viewport.zoom;
    final startX = (viewportRect.left / gridSize).floor() * gridSize;
    final endX = (viewportRect.right / gridSize).ceil() * gridSize;
    final startY = (viewportRect.top / gridSize).floor() * gridSize;
    final endY = (viewportRect.bottom / gridSize).ceil() * gridSize;

    final path = Path();
    for (double x = startX; x < endX; x += gridSize) {
      path.moveTo(x, viewportRect.top);
      path.lineTo(x, viewportRect.bottom);
    }
    for (double y = startY; y < endY; y += gridSize) {
      path.moveTo(viewportRect.left, y);
      path.lineTo(viewportRect.right, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void markNeedsPaint() {
    _picture?.dispose();
    _picture = null;
  }

  @override
  void paint(GVPainterContext context) {
    final canvas = context.canvas;

    final sizeChanged = _viewportSize != viewport.viewportSize;
    final positionChanged = _lastCameraPosition != viewport.position;
    final zoomChanged = _lastZoom != viewport.zoom;

    if (sizeChanged | positionChanged | zoomChanged) {
      _viewportSize = viewport.viewportSize;
      _lastCameraPosition = viewport.position;
      _lastZoom = viewport.zoom;

      markNeedsPaint();
    }

    canvas.drawPicture(_picture ??= drawObjectToPicture(innerPaint));
  }
}
