import 'package:flutter/rendering.dart' show Canvas, PaintingContext, Offset;
import 'package:graphics_playground/core/viewport.dart';
import 'package:vector_math/vector_math_64.dart';

class GVPainterContext {
  const GVPainterContext({required this.viewport, required this.offset, required this.surfaceContext});

  final Viewport2D viewport;
  final Offset offset;
  final PaintingContext surfaceContext;

  Canvas get canvas => surfaceContext.canvas;

  Matrix4 get transform => Matrix4.fromFloat64List(surfaceContext.canvas.getTransform());

  ({Viewport2D viewport, Canvas canvas}) get expanded => (viewport: viewport, canvas: canvas);
}
