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
  late vm.Matrix4 _matrix = _initialMatrix();

  Offset _position = Offset.zero;
  double _scale = 1.0;

  vm.Matrix4 get matrix => _matrix.clone();

  Float64List get rawMatrix => _matrix.storage;

  vm.Matrix4 _initialMatrix() {
    return vm.Matrix4.translation(vm.Vector3(.0, .0, 0))
      // Отражение по оси Y
      ..scaleByVector3(vm.Vector3(1, -1, 1));
  }

  void translate(Offset delta) {
    _position += delta;
    _updateMatrix();
  }

  void scale(double scale, [Offset? focalPoint]) {
    _scale *= scale;
    _scale = _scale.clamp(1, 10.0) / 10; // Ограничения масштаба
    _updateMatrix();
  }

  @pragma('vm:prefer-inline')
  void _updateMatrix() {
    _matrix = vm.Matrix4.translation(vm.Vector3(_position.dx, _position.dy, 0))
      ..scaleByVector3(vm.Vector3(1, -1, 1))
      ..scaleByVector3(vm.Vector3.all(_scale));
  }

  Rect getWorldRect(Size size) {
    // Преобразуем углы экрана в мировые координаты
    final topLeft = screenToWorld(Offset.zero, size);
    final bottomRight = screenToWorld(Offset(size.width, size.height), size);

    return Rect.fromPoints(topLeft, bottomRight);
  }

  // Методы для преобразования координат
  Offset worldToScreen(Offset worldPoint, Size viewportSize) {
    final transformed = matrix.transform3(vm.Vector3(worldPoint.dx, worldPoint.dy, 0));
    return Offset(transformed.x + viewportSize.width / 2, transformed.y + viewportSize.height / 2);
  }

  Offset screenToWorld(Offset screenPoint, Size viewportSize) {
    // Возвращаем матрицу к исходному состоянию
    // То есть переводим трансформацию в к мировым координатам
    final inverse = vm.Matrix4.inverted(matrix);
    final world = inverse.transform3(
      vm.Vector3(screenPoint.dx - viewportSize.width / 2, screenPoint.dy - viewportSize.height / 2, 0),
    );
    return Offset(world.x, world.y);
  }
}

class GraphicsViewport extends LeafRenderObjectWidget {
  const GraphicsViewport({super.key});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return GraphicsViewportRenderObject();
  }
}

class GraphicsViewportRenderObject extends RenderBox {
  Gesture _gesture = Gesture.none;

  Viewport viewport = Viewport();

  Offset lastDragPosition = Offset.zero;

  double snapFactor = 20;

  @override
  bool get sizedByParent => true;

  @override
  bool get isRepaintBoundary => true;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final parentSize = constraints.biggest;
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
      lastDragPosition = event.position;
    } else if (event is PointerMoveEvent) {
      _gesture += Gesture.move;
    } else if (event is PointerUpEvent) {
      _gesture = Gesture.up;
      lastDragPosition = Offset.zero;
    }
    var worldDelta = delta(event.position, snapOffset(lastDragPosition));
    if (_gesture.isMoving && worldDelta.distance > 1.0) {
      viewport.translate(snapOffset(worldDelta));
      lastDragPosition = event.position;
      markNeedsPaint();
    }
  }

  Offset delta(Offset first, Offset second) => (first - second) / viewport._scale;

  Offset snapOffset(Offset offset) => Offset(snap(offset.dx), snap(offset.dy));

  double snap(double value) {
    return (value / snapFactor).round() * snapFactor;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..translate(size.width * .5, size.height * .5)
      ..transform(viewport.rawMatrix)
      ..drawObject(drawGrid)
      ..drawObject(drawAxis)
      ..drawObject((canvas) {
        canvas.drawRect(Offset.zero & Size(100, 100), Paint()..color = Colors.deepPurple);
      })
      ..restore();
  }

  void drawAxis(Canvas canvas) {
    final viewportRect = viewport.getWorldRect(size);
    canvas
      ..save()
      ..clipRect(viewportRect)
      ..drawRawPoints(
        PointMode.lines,
        Float32List.fromList([viewportRect.left, 0, viewportRect.right, 0]),
        Paint()
          ..color = Colors.red
          ..strokeWidth = 1.0 / viewport._scale,
      )
      ..drawRawPoints(
        PointMode.lines,
        Float32List.fromList([0, viewportRect.bottom, 0, viewportRect.top]),
        Paint()
          ..color = Colors.green
          ..strokeWidth = 1.0 / viewport._scale,
      )
      ..drawRawPoints(
        PointMode.lines,
        Float32List.fromList([-4, 0, 4, 0, 0, -4, 0, 4]),
        Paint()
          ..color = Colors.black
          ..strokeWidth = 1.5,
      )
      ..restore();
  }

  void drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.grey.withAlpha(60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 / viewport._scale;

    final viewportRect = viewport.getWorldRect(size);

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
}

extension CanvasExtension on Canvas {
  Canvas drawObject(void Function(Canvas canvas) draw) {
    draw(this);
    return this;
  }
}
