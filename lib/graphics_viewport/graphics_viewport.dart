import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:graphics_playground/graphics_viewport/gesture.dart';
import 'package:graphics_playground/graphics_viewport/viewport.dart';

class GraphicsViewportController {
  WeakReference<GraphicsViewportRenderObject>? _renderObject;

  void _useObject(void Function(GraphicsViewportRenderObject object) callback) {
    if (_renderObject?.target case GraphicsViewportRenderObject object) {
      callback(object);
    }
  }

  void centerViewport() {
    _useObject((object) {
      final viewport = object.viewport;
      viewport.reset();
      object.markNeedsPaint();
    });
  }
}

class GraphicsViewport extends LeafRenderObjectWidget {
  const GraphicsViewport({super.key, required this.controller});

  final GraphicsViewportController controller;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return GraphicsViewportRenderObject(controller: controller);
  }
}

class GraphicsViewportRenderObject extends RenderBox {
  GraphicsViewportRenderObject({required this.controller}) {
    controller._renderObject = WeakReference(this);
  }

  final GraphicsViewportController controller;
  final viewport = Viewport2D();

  Gesture _gesture = Gesture.none;

  Offset lastDragPosition = Offset.zero;

  double snapFactor = 20;

  @override
  bool get sizedByParent => true;

  @override
  bool get isRepaintBoundary => true;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final parentSize = constraints.biggest;
    viewport.updateProjection(parentSize);
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
    var worldDelta = delta(event.position, lastDragPosition);
    if (_gesture.isMoving && worldDelta.distance > 1.0) {
      viewport.translate(worldDelta);
      lastDragPosition = event.position;
      markNeedsPaint();
    }
  }

  Offset delta(Offset first, Offset second) => (first - second) / viewport.zoom;

  Offset snapOffset(Offset offset) => Offset(snap(offset.dx), snap(offset.dy));

  double snap(double value) => (value / snapFactor).round() * snapFactor;

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..transform(viewport.projection.storage)
      ..transform(viewport.view.storage)
      //..transform(viewport.rawMatrix)
      ..drawObject(drawGrid)
      ..drawObject(drawAxis)
      ..drawObject((canvas) {
        canvas.drawRect(Offset.zero & Size(100, 100), Paint()..color = Colors.deepPurple);
      })
      ..drawObject((canvas) {
        final worldRect = viewport.getWorldRect(size).deflate(1.5);
        canvas.drawRSuperellipse(
          RSuperellipse.fromRectAndRadius(worldRect, Radius.circular(8)),
          Paint()
            ..color = Colors.deepOrange
            ..strokeWidth = 2.0 / viewport.zoom
            ..style = PaintingStyle.stroke,
        );
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
          ..strokeWidth = 1.0 / viewport.zoom,
      )
      ..drawRawPoints(
        PointMode.lines,
        Float32List.fromList([0, viewportRect.bottom, 0, viewportRect.top]),
        Paint()
          ..color = Colors.green
          ..strokeWidth = 1.0 / viewport.zoom,
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
      ..strokeWidth = 1.0 / viewport.zoom;

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
    canvas
      ..clipRect(viewportRect)
      ..drawPath(path, paint);
  }
}

extension CanvasExtension on Canvas {
  Canvas drawObject(void Function(Canvas canvas) draw) {
    draw(this);
    return this;
  }
}
