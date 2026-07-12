import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show Colors, ChangeNotifier;
import 'package:graphics_playground/core/foundation/canvas_extension.dart';
import 'package:graphics_playground/core/gesture/viewport_pointer_event.dart';
import 'package:graphics_playground/core/gv_painter.dart';
import 'package:graphics_playground/core/painter_context.dart';

class QuadPrimitiveObject extends GvPainterMixin with ChangeNotifier {
  QuadPrimitiveObject();

  final _cubeBackground = Paint()..color = Colors.grey.shade300.withAlpha(164);
  final _cubeBorder = Paint()
    ..color = Colors.grey.shade300.withAlpha(164)
    ..style = ui.PaintingStyle.stroke
    ..color = Colors.grey.shade400;

  ui.Picture? _cubePicture;

  Rect _rect = Offset.zero & ui.Size(200, 200);

  void _markNeedRepaint() {
    _cubePicture?.dispose();
    _cubePicture = null;

    notifyListeners();
  }

  void _innerPaint(ui.Canvas canvas) {
    canvas
      ..drawRect(_rect, _cubeBackground)
      ..drawRect(_rect, _cubeBorder..strokeWidth = 1.6 / viewport.zoom);
  }

  @override
  bool handleEvent(ViewportPointerEvent event, HitTestEntry<HitTestTarget> entry) {
    if (!_rect.contains(event.worldPosition)) return false;
    final originEvent = event.origin;

    if (originEvent is PointerMoveEvent && originEvent.buttons & kPrimaryMouseButton > 0) {
      final delta = event.worldDelta;
      _rect = _rect.translate(delta.dx, delta.dy);

      _markNeedRepaint();
      return true;
    }

    return false;
  }

  @override
  void paint(GVPainterContext context) {
    final canvas = context.canvas;

    _cubePicture ??= drawObjectToPicture(_innerPaint);
    canvas.drawPicture(_cubePicture!);
  }

  @override
  void onDetach() {
    _cubePicture?.dispose();
    _cubePicture = null;
    super.onDetach();
  }
}
