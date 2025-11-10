import 'package:flutter/rendering.dart' show Canvas, PaintingContext, Offset;
import 'package:graphics_playground/graphics_viewport/viewport.dart';

class GVPainterContext {
  const GVPainterContext({required this.viewport, required this.offset, required this.surfaceContext});

  final Viewport2D viewport;
  final Offset offset;
  final PaintingContext surfaceContext;

  Canvas get canvas => surfaceContext.canvas;

  ({Viewport2D viewport, Canvas canvas}) get expanded => (viewport: viewport, canvas: canvas);
}
