import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:graphics_playground/core/gesture/gesture.dart';
import 'package:graphics_playground/core/gesture/viewport_pointer_event.dart';
import 'package:graphics_playground/core/painter_context.dart';
import 'package:graphics_playground/core/rendering/gv_painter.dart';

abstract interface class TransformGizmoTarget {
  Rect get localBounds;

  Offset localToWorld(Offset point);

  void copyTransformInto(Matrix4 result);

  void setTransform(Matrix4 transform);
}

final class TransformGizmo extends GvPainterObject implements GvPointerHandler {
  TransformGizmo();

  TransformGizmoTarget? _target;
  TransformGizmoTarget? get target => _target;
  set target(TransformGizmoTarget? value) {
    _target = value;
    _updateSelectionBounds(value);
  }

  final _initialTransform = Matrix4.identity();
  final _rotationTransform = Matrix4.identity();
  final _resultTransform = Matrix4.identity();

  final _rectForRender = Float32List(10);

  final _outlinePaint = Paint()
    ..color = Colors.blue
    ..style = PaintingStyle.stroke;

  final _handlePaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  int? _pointer;
  Offset _pivotWorld = .zero;
  Offset _renderPivotWorld = .zero;
  Offset _upperWorld = .zero;
  Offset _handleWorld = .zero;
  Offset _handleScreen = .zero;

  double _lastAngle = 0;
  double _accumulatedAngle = 0;

  bool get active => _pointer != null;

  @override
  GvPointerEventResult handlePointerEvent(ViewportPointerEvent event) {
    final origin = event.origin;
    final item = target;

    if (origin is PointerDownEvent) {
      if (item == null) return .ignore;
      if ((origin.buttons & kPrimaryMouseButton) == 0) return .ignore;

      _updateGeometry();

      if ((event.screenPosition - _handleScreen).distance > 10) {
        return .ignore;
      }

      _pivotWorld = _renderPivotWorld;
      _pointer = origin.pointer;
      item.copyTransformInto(_initialTransform);

      _lastAngle = _angleAroundPivot(event.worldPosition, _pivotWorld);
      _accumulatedAngle = 0;

      return .capture;
    }

    if (origin.pointer != _pointer || item == null) return .ignore;

    if (origin is PointerMoveEvent) {
      final angle = _angleAroundPivot(event.worldPosition, _pivotWorld);
      _accumulatedAngle += _normalize(angle - _lastAngle);
      _lastAngle = angle;

      _rotationTransform
        ..setIdentity()
        ..translateByDouble(_pivotWorld.dx, _pivotWorld.dy, 0, 1)
        ..rotateZ(_accumulatedAngle)
        ..translateByDouble(-_pivotWorld.dx, -_pivotWorld.dy, 0, 1);

      _resultTransform
        ..setFrom(_rotationTransform)
        ..multiply(_initialTransform);

      item.setTransform(_resultTransform);
      return .handle;
    }

    if (origin is PointerCancelEvent) {
      item.setTransform(_initialTransform);
      _pointer = null;
      return .handle;
    }

    if (origin is PointerUpEvent) {
      _pointer = null;
      return .handle;
    }

    return .ignore;
  }

  double _angleAroundPivot(Offset point, Offset pivot) {
    final vector = point - pivot;
    return math.atan2(vector.dy, vector.dx);
  }

  double _normalize(double angle) {
    if (angle > math.pi) return angle - math.pi * 2;
    if (angle < -math.pi) return angle + math.pi * 2;
    return angle;
  }

  void _updateGeometry() {
    final item = target!;
    final bounds = item.localBounds;

    _renderPivotWorld = item.localToWorld(bounds.center);
    _upperWorld = item.localToWorld(bounds.bottomCenter);

    final pivotScreen = viewport.worldToScreen(_renderPivotWorld);
    final upperScreen = viewport.worldToScreen(_upperWorld);

    final vector = upperScreen - pivotScreen;
    if (vector.distance == 0) return;

    final normalizedVector = vector / vector.distance;

    _handleScreen = upperScreen + (normalizedVector * 30);
    _handleWorld = viewport.screenToWorld(_handleScreen);
  }

  void _updateSelectionBounds(TransformGizmoTarget? target) {
    if (target == null) {
      _rectForRender
        ..[0] = 0
        ..[1] = 0
        ..[2] = 0
        ..[3] = 0
        ..[4] = 0
        ..[5] = 0
        ..[6] = 0
        ..[7] = 0
        ..[8] = 0
        ..[9] = 0;
      return;
    }

    final bounds = target.localBounds;

    final topLeft = target.localToWorld(bounds.topLeft);
    final bottomLeft = target.localToWorld(bounds.bottomLeft);
    final topRight = target.localToWorld(bounds.topRight);
    final bottomRight = target.localToWorld(bounds.bottomRight);

    _rectForRender
      ..[0] = topLeft.dx
      ..[1] = topLeft.dy
      ..[2] = topRight.dx
      ..[3] = topRight.dy
      ..[4] = bottomRight.dx
      ..[5] = bottomRight.dy
      ..[6] = bottomLeft.dx
      ..[7] = bottomLeft.dy
      ..[8] = topLeft.dx
      ..[9] = topLeft.dy;
  }

  @override
  void paint(GVPainterContext context) {
    final item = target;
    if (item == null) return;

    _updateGeometry();

    _updateSelectionBounds(item);

    _outlinePaint.strokeWidth = 1.8 / viewport.zoom;
    _outlinePaint.strokeCap = .square;
    final canvas = context.canvas;

    canvas
      ..drawRawPoints(.polygon, _rectForRender, _outlinePaint)
      ..drawLine(_upperWorld, _handleWorld, _outlinePaint)
      ..drawCircle(_handleWorld, 8 / viewport.zoom, _handlePaint)
      ..drawCircle(_handleWorld, 8 / viewport.zoom, _outlinePaint);
  }
}
