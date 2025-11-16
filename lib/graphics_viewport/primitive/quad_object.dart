import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:graphics_playground/core/canvas_extension.dart';
import 'package:graphics_playground/graphics_viewport/gv_painter.dart';
import 'package:graphics_playground/graphics_viewport/painter_context.dart';

class QuadPrimitiveObject extends GvPainterMixin {
  QuadPrimitiveObject();

  final _cubeBackground = Paint()..color = Colors.grey.shade300.withAlpha(164);
  final _cubeBorder = Paint()
    ..color = Colors.grey.shade300.withAlpha(164)
    ..style = ui.PaintingStyle.stroke
    ..color = Colors.grey.shade400;

  ui.Picture? _cubePicture;

  Rect _rect = Offset.zero & ui.Size(200, 200);

  bool move = false;
  Offset lastPosition = Offset.zero;

  bool _repaint = false;

  void _markNeedRepaint() {
    _cubePicture = null;
    _repaint = true;
  }

  void _innerPaint(ui.Canvas canvas) {
    canvas
      ..drawRect(_rect, _cubeBackground)
      ..drawRect(_rect, _cubeBorder..strokeWidth = 1.6 / viewport.zoom);
  }

  @override
  bool get needsPaint => _repaint;

  @override
  bool handleEvent(PointerEvent event, HitTestEntry<HitTestTarget> entry) {
    if (event is PointerDownEvent) {
      lastPosition = event.position;
    } else if (event is PointerMoveEvent && _rect.contains(viewport.screenToWorld(event.position))) {
      move = true;
      var delta = (event.position - lastPosition) / viewport.zoom;
      if (delta.distance > 1.0) {
        _rect = _rect.translate(delta.dx, delta.dy);
        lastPosition = event.position;

        _markNeedRepaint();
        return true;
      }
      debugPrint('QuadPrimitiveObject::handleEvent::move ${_rect.contains(viewport.screenToWorld(event.position))}');
    } else if (event is PointerUpEvent) {
      move = false;
    }

    return move;
  }

  @override
  void paint(GVPainterContext context) {
    final canvas = context.canvas;

    if (_cubePicture != null) {
      canvas.drawPicture(_cubePicture!);
    } else {
      canvas.drawPicture(_cubePicture = drawObjectToPicture(_innerPaint));
      debugPrint('QuadPrimitiveObject::paint');
      _repaint = false;
    }
  }
}
