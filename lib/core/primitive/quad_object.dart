import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:graphics_playground/core/foundation/canvas_extension.dart';
import 'package:graphics_playground/core/gesture/gesture.dart';
import 'package:graphics_playground/core/gesture/viewport_pointer_event.dart';
import 'package:graphics_playground/core/rendering/canvas_item.dart';

class QuadPrimitiveObject extends CanvasItem {
  QuadPrimitiveObject({Color? backgroundColor, super.worldPosition})
    : _cubeBackground = Paint()..color = backgroundColor ?? Colors.grey.shade300.withAlpha(164);

  late final Paint _cubeBackground;
  final _cubeBorder = Paint()
    ..color = Colors.grey.shade300.withAlpha(164)
    ..style = PaintingStyle.stroke
    ..color = Colors.grey.shade400;

  late final _localRect = Offset.zero & Size(200, 200);

  ui.Picture? _picture;

  void _innerPaint(Canvas canvas) {
    canvas
      ..drawRect(_localRect, _cubeBackground)
      ..drawRect(_localRect, _cubeBorder..strokeWidth = 1.6);
  }

  @override
  bool hitTestLocal(ui.Offset localPosition) {
    return _localRect.contains(localPosition);
  }

  @override
  GvPointerEventResult handlePointerEvent(ViewportPointerEvent event) {
    final origin = event.origin;

    final primaryPressed = origin.buttons & kPrimaryMouseButton > 0;

    if (origin is PointerDownEvent) {
      if (primaryPressed) return .capture;
      return .ignore;
    }

    if (origin is PointerMoveEvent) {
      translateWorld(event.worldDelta);
      return .handle;
    }

    if (origin is PointerUpEvent || origin is PointerCancelEvent) {
      return .handle;
    }

    return super.handlePointerEvent(event);
  }

  @override
  void dispose() {
    _picture?.dispose();
    _picture = null;
    super.dispose();
  }

  @override
  void draw(Canvas canvas) {
    canvas.drawPicture(_picture ??= drawObjectToPicture(_innerPaint));
  }

  @override
  Rect get localBounds => _localRect;
}
