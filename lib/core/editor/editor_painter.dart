import 'package:flutter/gestures.dart';
import 'package:graphics_playground/core/gesture.dart';
import 'package:graphics_playground/core/gv_painter.dart';
import 'package:graphics_playground/core/editor/axis_painter.dart';
import 'package:graphics_playground/core/editor/grid_painter.dart';
import 'package:graphics_playground/core/viewport_context.dart';
import 'package:graphics_playground/core/painter_context.dart';

/// Отвечает за отрисовку деталей редактора таких как сетка, координатные оси
final class EditorPainter extends GvPainterMixin {
  final gridPainter = GridPainter();
  final axisPainter = AxisPainter();

  Gesture _gesture = Gesture.none;

  Offset _lastDragPosition = Offset.zero;

  @override
  bool get needsPaint => gridPainter.needsPaint | axisPainter.needsPaint;

  @override
  bool handleEvent(PointerEvent event, HitTestEntry entry) {
    if (event is PointerHoverEvent) return false;

    if (event is PointerDownEvent) {
      _gesture += Gesture.down;
      _lastDragPosition = event.position;
    } else if (event is PointerMoveEvent) {
      _gesture += Gesture.move;
    } else if (event is PointerUpEvent) {
      _gesture = Gesture.up;
      _lastDragPosition = Offset.zero;
    } else if (event case PointerScrollEvent(kind: PointerDeviceKind.mouse)) {
      _gesture = Gesture.scroll;
    }

    if (_gesture == Gesture.scroll) {
      if (event is PointerScrollEvent) {
        final factor = event.scrollDelta.dy.isNegative ? 1.2 : 0.9;
        viewport.scale(factor, _lastDragPosition = event.position);
        return true;
      }
    }

    var worldDelta = (event.position - _lastDragPosition) / viewport.zoom;

    if (_gesture.isMoving) {
      viewport.translate(worldDelta);
      _lastDragPosition = event.position;
      return true;
    }

    return false;
  }

  @override
  void onTick(Duration delta) {
    super.onTick(delta);
    gridPainter.onTick(delta);
    axisPainter.onTick(delta);
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
