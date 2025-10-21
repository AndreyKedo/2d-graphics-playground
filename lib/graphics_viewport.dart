import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

extension type const Gesture._(int val) {
  static const Gesture none = Gesture._(0);

  static const Gesture down = Gesture._(1);
  static const Gesture up = Gesture._(2);
  static const Gesture move = Gesture._(3);

  Gesture compose(Gesture other) => Gesture._(val | other.val);

  bool get isMoving {
    return _bit(down.val) && _bit(move.val);
  }

  bool _bit(int bit) => (val & bit) != 0;

  Gesture operator +(Gesture other) => compose(other);
}

class Viewport {
  vm.Matrix4 _matrix = vm.Matrix4.identity();
  Offset _translation = Offset.zero;
  double _scale = 1.0;

  vm.Matrix4 get matrix => _matrix.clone();

  void translate(Offset delta) {
    _translation += delta;
    _updateMatrix();
  }

  void scale(double scale, Offset focalPoint) {
    _scale *= scale;
    _updateMatrix();
  }

  void _updateMatrix() {
    _matrix = Matrix4.identity()
      ..translateByVector3(vm.Vector3(_translation.dx, _translation.dy, 0))
      ..translateByVector3(vm.Vector3.all(_scale));
  }
}

class GraphicsViewport extends LeafRenderObjectWidget {
  const GraphicsViewport();

  @override
  RenderObject createRenderObject(BuildContext context) {
    return GraphicsViewportRenderObject();
  }
}

class GraphicsViewportRenderObject extends RenderBox {
  final gridLayer = LayerHandle<PictureLayer>();
  final viewportLayer = LayerHandle<PictureLayer>();

  Gesture _gesture = Gesture.none;

  Offset lastPosition = Offset.zero;
  vm.Vector3 lastDirection = vm.Vector3.zero();

  vm.Matrix4 viewport = vm.Matrix4.identity();

  double snapFactor = 20;

  double _scale = 1.0;
  double get scale => _scale;
  set scale(double value) {
    if (_scale != value) {
      _scale = value;
      markNeedsPaint();
    }
  }

  vm.Vector3 _offset = vm.Vector3.zero();
  vm.Vector3 get offset => _offset;
  set offset(vm.Vector3 value) {
    if (_offset != value) {
      _offset = value;
      markNeedsPaint();
    }
  }

  @override
  bool get sizedByParent => true;

  @override
  bool get isRepaintBoundary => true;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final parentSize = constraints.biggest;
    viewport = vm.Matrix4.identity()
      // Затем применяем масштабирование
      ..scaleByVector3(vm.Vector3.all(_scale))
      // Затем применяем смещение (panning)
      ..translateByVector3(lastDirection);
    return parentSize;
  }

  // Для обработки указателей
  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (event is PointerHoverEvent) return;
    // Пока просто выводим информацию о событии
    //debugPrint('Pointer event: ${event.runtimeType} at ${event.position}');

    if (event is PointerDownEvent) {
      _gesture += Gesture.down;
      lastPosition = snapOffset(event.position);
    } else if (event is PointerMoveEvent) {
      _gesture += Gesture.move;
    } else if (event is PointerUpEvent) {
      _gesture = Gesture.up;
      lastPosition = Offset.zero;
    }
    final deltaVal = delta(event.position, lastPosition);
    if (_gesture.isMoving && deltaVal.distance > 1.0) {
      // Создаем матрицу трансформации на основе параметров viewport
      updateViewport((viewport) {
        return viewport..translateByVector3(offset = positionFromDelta(deltaVal));
      });
      lastDirection += offset;
      lastPosition = snapOffset(event.position);
    }
  }

  Offset delta(Offset first, Offset second) => first - second;

  vm.Vector3 positionFromDelta(Offset delta) => vm.Vector3(snap(delta.dx), snap(delta.dy), 0);

  Offset snapOffset(Offset offset) => Offset(snap(offset.dx), snap(offset.dy));

  double snap(double value) {
    return (value / snapFactor).round() * snapFactor;
  }

  void updateViewport(vm.Matrix4 Function(vm.Matrix4 viewport) update) {
    viewport = update(viewport);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..translate(size.width * .5, size.height * .5)
      ..drawObject(drawAxis)
      ..drawObject(drawGrid)
      ..drawObject(
        (canvas) => canvas.drawRawPoints(
          PointMode.lines,
          Float32List.fromList([-4, 0, 4, 0, 0, -4, 0, 4]),
          Paint()
            ..color = Colors.black
            ..strokeWidth = 1.5,
        ),
      )
      ..transform(viewport.storage)
      ..drawObject((canvas) {
        canvas.drawRect(Offset.zero & Size(100, 100), Paint()..color = Colors.deepPurple);
      })
      ..restore();
  }

  void drawAxis(Canvas canvas) {
    canvas
      ..drawRawPoints(
        PointMode.lines,
        Float32List.fromList([-size.width, 0, size.width, 0]),
        Paint()
          ..color = Colors.red
          ..strokeWidth = 1.0 / _scale,
      )
      ..drawRawPoints(
        PointMode.lines,
        Float32List.fromList([0, -size.height, 0, size.height]),
        Paint()
          ..color = Colors.green
          ..strokeWidth = 1.0 / _scale,
      );
  }

  void drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.grey.withAlpha(60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 / _scale;

    final viewportRect = (Offset(-size.width, -size.height) & (size * 2)).inflate(20);

    final gridSize = snapFactor;
    final startX = (viewportRect.left / gridSize).floor() * gridSize;
    final endX = (viewportRect.right / gridSize).ceil() * gridSize;
    final startY = (viewportRect.top / gridSize).floor() * gridSize;
    final endY = (viewportRect.bottom / gridSize).ceil() * gridSize;

    final path = Path();
    for (double x = startX.toDouble(); x < endX; x += gridSize) {
      path.moveTo(x, viewportRect.top);
      path.lineTo(x, viewportRect.bottom);
    }
    for (double y = startY.toDouble(); y < endY; y += gridSize) {
      path.moveTo(viewportRect.left, y);
      path.lineTo(viewportRect.right, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  void dispose() {
    viewportLayer.layer = null;
    gridLayer.layer = null;
    super.dispose();
  }
}

extension CanvasExtension on Canvas {
  Canvas drawObject(void Function(Canvas canvas) draw) {
    draw(this);
    return this;
  }
}
