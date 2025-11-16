import 'package:flutter/material.dart';
import 'package:graphics_playground/graphics_viewport/gv_painter.dart';
import 'package:graphics_playground/graphics_viewport/painter_context.dart';

class GridPainter extends GvPainterMixin {
  GridPainter();

  final gridPainter = Paint()
    ..color = Colors.grey.withAlpha(60)
    ..style = PaintingStyle.stroke;

  @override
  void paint(GVPainterContext context) {
    final (:canvas, :viewport) = context.expanded;

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
    canvas
      ..save()
      ..clipRect(viewportRect)
      ..drawPath(path, paint)
      ..restore();
  }
}
