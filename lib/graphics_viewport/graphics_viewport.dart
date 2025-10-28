import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:graphics_playground/core/canvas_extension.dart';
import 'package:graphics_playground/graphics_viewport/develop/editor_metrics_painter.dart';
import 'package:graphics_playground/graphics_viewport/editor/axis_painter.dart';
import 'package:graphics_playground/graphics_viewport/develop/performance_overlay_painter.dart';
import 'package:graphics_playground/graphics_viewport/gesture.dart';
import 'package:graphics_playground/graphics_viewport/editor/grid_painter.dart';
import 'package:graphics_playground/graphics_viewport/painter_context.dart';
import 'package:graphics_playground/graphics_viewport/viewport.dart';

class GraphicsViewportController {
  WeakReference<GraphicsViewportRenderObject>? _renderObject;

  @pragma('vm:prefer-inline')
  void _useObject(void Function(GraphicsViewportRenderObject object) callback) {
    if (_renderObject?.target case GraphicsViewportRenderObject object) {
      callback(object);
    }
  }

  void centerViewport() {
    _useObject((object) {
      final viewport = object.viewport;
      viewport.reset();
      object.lastDragPosition = object.size.center(Offset.zero);
      object.markNeedsPaint();
    });
  }

  void dispose() {
    _renderObject = null;
  }
}

class GraphicsViewport extends LeafRenderObjectWidget {
  const GraphicsViewport({
    super.key,
    required this.controller,
    this.performanceOverlayOps = PerformanceOverlayOptionExtension.none,
  });

  final GraphicsViewportController controller;

  final int performanceOverlayOps;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return GraphicsViewportRenderObject(controller: controller, overlayOption: performanceOverlayOps);
  }

  @override
  void updateRenderObject(BuildContext context, GraphicsViewportRenderObject renderObject) {
    renderObject
      ..overlayOption = performanceOverlayOps
      ..controller = controller;
    super.updateRenderObject(context, renderObject);
  }
}

class GraphicsViewportRenderObject extends RenderBox {
  GraphicsViewportRenderObject({required GraphicsViewportController controller, required int overlayOption})
    : _overlayOption = overlayOption,
      _controller = controller {
    controller._renderObject = WeakReference(this);
  }

  final viewport = Viewport2D();

  final performanceOverlayPainter = PerformanceOverlayPainter();
  final gridPainter = GridPainter();
  final axisPainter = AxisPainter();
  final editorMetrics = EditorMetricsPainter();

  final translationInfoLayer = LayerHandle<ContainerLayer>();

  Gesture _gesture = Gesture.none;

  Offset _lastDragPosition = Offset.zero;
  Offset get lastDragPosition => _lastDragPosition;
  set lastDragPosition(Offset value) {
    _lastDragPosition = value;
    editorMetrics.lastDragPosition = value;
  }

  int _overlayOption;
  int get overlayOption => _overlayOption;
  set overlayOption(int value) {
    if (value == _overlayOption) return;

    _overlayOption = value;
    performanceOverlayPainter.overlayOption = _overlayOption;
    markNeedsPaint();
  }

  GraphicsViewportController _controller;
  GraphicsViewportController get controller => _controller;
  set controller(GraphicsViewportController value) {
    if (value == _controller) return;
    _controller._renderObject = null;
    _controller = value;
    controller._renderObject = WeakReference(this);
  }

  @override
  bool get sizedByParent => true;

  @override
  bool get isRepaintBoundary => true;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final parentSize = constraints.biggest;
    // Update viewport
    viewport.updateProjection(parentSize);

    // Overlay setup
    performanceOverlayPainter.overlayRect = Offset.zero & Size(parentSize.width, 200);
    performanceOverlayPainter.overlayOption = _overlayOption;

    debugPrint('GraphicsViewportRenderObject.computeDryLayout: $parentSize');
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
    } else if (event case PointerScrollEvent(kind: PointerDeviceKind.mouse)) {
      _gesture = Gesture.scroll;
    }

    if (_gesture == Gesture.scroll) {
      if (event is PointerScrollEvent) {
        final factor = event.scrollDelta.dy.isNegative ? 1.2 : 0.9;
        if (viewport.scale(factor, lastDragPosition = event.position)) {
          markNeedsPaint();
        }
        return;
      }
    }

    var worldDelta = (event.position - lastDragPosition) / viewport.zoom;

    if (_gesture.isMoving && worldDelta.distance > 1.0) {
      viewport.translate(worldDelta);
      lastDragPosition = event.position;
      markNeedsPaint();
    }
  }

  // Offset snapOffset(Offset offset) => Offset(snap(offset.dx), snap(offset.dy));

  // double snap(double value) => (value / snapFactor).round() * snapFactor;

  @override
  void paint(PaintingContext context, Offset offset) {
    final gvContext = GVPainterContext(surfaceContext: context, offset: offset, viewport: viewport);
    final canvas = context.canvas;
    canvas
      ..save()
      ..translate(offset.dx, offset.dy)
      ..clipRect(offset & size);
    viewport.applyTransformation(canvas);
    canvas
      ..drawObject((canvas) {
        gridPainter.paint(gvContext);
        axisPainter.paint(gvContext);
      })
      ..drawObject((canvas) {
        canvas.drawRSuperellipse(
          RSuperellipse.fromRectAndRadius(viewport.getWorldRect(), Radius.circular(12) / viewport.zoom),
          Paint()
            ..style = PaintingStyle.stroke
            ..color = Colors.grey.shade400.withAlpha(210)
            ..strokeWidth = 10.0 / viewport.zoom,
        );
      })
      ..drawObject((canvas) {
        final rect = Offset.zero & Size(100, 100);
        final paint = Paint()..color = Colors.grey.shade300.withAlpha(164);
        canvas
          ..save()
          ..drawRect(rect, paint)
          ..drawRect(
            rect,
            paint
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6 / viewport.zoom
              ..color = Colors.grey.shade400,
          )
          ..drawLine(Offset(rect.center.dx, rect.top), Offset(rect.center.dx, rect.bottom), paint)
          ..drawLine(Offset(rect.center.dx, rect.bottom), Offset(rect.center.dx - 8, rect.bottom - 12), paint)
          ..drawLine(Offset(rect.center.dx, rect.bottom), Offset(rect.center.dx + 8, rect.bottom - 12), paint)
          ..restore();
      });

    performanceOverlayPainter.paint(gvContext);
    editorMetrics.paint(gvContext);
    context.canvas.restore();
  }

  @override
  void dispose() {
    editorMetrics.dispose();
    super.dispose();
  }
}
