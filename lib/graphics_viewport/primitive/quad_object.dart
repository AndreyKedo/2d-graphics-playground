import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:graphics_playground/graphics_viewport/gv_painter.dart';
import 'package:graphics_playground/graphics_viewport/painter_context.dart';

class QuadPrimitiveObject extends GvPainter {
  QuadPrimitiveObject();

  ui.Picture? _cubePicture;

  ui.Rect _rect = ui.Offset.zero & ui.Size(200, 200);

  bool move = false;
  Offset lastPosition = Offset.zero;

  bool _repaint = false;
  @override
  bool get needsPaint => _repaint;

  @override
  bool handleEvent(PointerEvent event, HitTestEntry<HitTestTarget> entry) {
    if (event is PointerDownEvent) {
      lastPosition = event.position;
    } else if (event is PointerMoveEvent && _rect.contains(viewport.screenToWorld(event.position))) {
      move = true;
      var worldDelta = (event.position - lastPosition) / viewport.zoom;
      if (worldDelta.distance > 1.0) {
        _rect = _rect.translate(worldDelta.dx, worldDelta.dy);
        lastPosition = event.position;

        _cubePicture = null;
        _repaint = true;
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
    _repaint = false;
    final (:canvas, :viewport) = context.expanded;

    if (_cubePicture != null) {
      canvas.drawPicture(_cubePicture!);
      return;
    }

    final recorder = ui.PictureRecorder();
    final canvasInner = ui.Canvas(recorder);
    final paint = ui.Paint()..color = Colors.grey.shade300.withAlpha(164);
    canvasInner
      ..drawRect(_rect, paint)
      ..drawRect(
        _rect,
        paint
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1.6 / viewport.zoom
          ..color = Colors.grey.shade400,
      )
      ..drawLine(ui.Offset(_rect.center.dx, _rect.top), ui.Offset(_rect.center.dx, _rect.bottom), paint)
      ..drawLine(ui.Offset(_rect.center.dx, _rect.bottom), ui.Offset(_rect.center.dx - 8, _rect.bottom - 12), paint)
      ..drawLine(ui.Offset(_rect.center.dx, _rect.bottom), ui.Offset(_rect.center.dx + 8, _rect.bottom - 12), paint);

    _cubePicture = recorder.endRecording();
    canvas.drawPicture(_cubePicture!);
    debugPrint('QuadPrimitiveObject::paint');
  }
}
