import 'package:flutter/gestures.dart';
import 'package:graphics_playground/core/gesture/gesture.dart';
import 'package:graphics_playground/core/gesture/viewport_pointer_event.dart';
import 'package:graphics_playground/core/gv_painter.dart';
import 'package:graphics_playground/core/editor/axis_painter.dart';
import 'package:graphics_playground/core/editor/grid_painter.dart';
import 'package:graphics_playground/core/viewport/viewport_context.dart';
import 'package:graphics_playground/core/painter_context.dart';

/// Отвечает за отрисовку деталей редактора таких как сетка, координатные оси
final class EditorPainter extends GvPainterMixin {
  final gridPainter = GridPainter();
  final axisPainter = AxisPainter();

  Gesture _gesture = Gesture.none;

  @override
  bool handleEvent(ViewportPointerEvent event, HitTestEntry entry) {
    final originEvent = event.origin;
    if (originEvent is PointerHoverEvent) return false;

    if (originEvent is PointerDownEvent) {
      _gesture += Gesture.down;
    } else if (originEvent is PointerMoveEvent) {
      _gesture += Gesture.move;
    } else if (originEvent is PointerUpEvent) {
      _gesture = Gesture.up;
    } else if (originEvent case PointerScrollEvent(kind: PointerDeviceKind.mouse)) {
      _gesture = Gesture.scroll;
    }

    if (_gesture == Gesture.scroll) {
      if (originEvent is PointerScrollEvent) {
        final factor = originEvent.scrollDelta.dy.isNegative ? 1.2 : 0.9;
        viewport.scale(factor, event.screenPosition);
        return true;
      }
    }

    if (_gesture.isMoving && originEvent.buttons & kTertiaryButton > 0) {
      viewport.translate(event.worldDelta);
      return true;
    }

    return false;
  }

  @override
  void onAttached(GraphicsViewportContext context) {
    super.onAttached(context);
    gridPainter.onAttached(context);
    axisPainter.onAttached(context);
  }

  @override
  void paint(GVPainterContext context) {
    gridPainter.paint(context);
    axisPainter.paint(context);
  }

  @override
  void onDetach() {
    gridPainter.onDetach();
    axisPainter.onDetach();
    super.onDetach();
  }
}
