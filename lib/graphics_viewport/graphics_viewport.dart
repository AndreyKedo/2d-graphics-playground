import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:graphics_playground/core/canvas_extension.dart';
import 'package:graphics_playground/graphics_viewport/develop/editor_metrics_painter.dart';
import 'package:graphics_playground/graphics_viewport/editor/axis_painter.dart';
import 'package:graphics_playground/graphics_viewport/develop/performance_overlay_painter.dart';
import 'package:graphics_playground/graphics_viewport/gesture.dart';
import 'package:graphics_playground/graphics_viewport/editor/grid_painter.dart';
import 'package:graphics_playground/graphics_viewport/gv_painter.dart';
import 'package:graphics_playground/graphics_viewport/painter_context.dart';
import 'package:graphics_playground/graphics_viewport/viewport.dart';

abstract interface class GraphicsViewportContext {
  Viewport2D get viewport;

  Size get size;
}

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
    this.painter,
    this.performanceOverlayOps = PerformanceOverlayOptionExtension.none,
  });

  final GraphicsViewportController controller;
  final GvPainter? painter;

  final int performanceOverlayOps;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return GraphicsViewportRenderObject(controller: controller, overlayOption: performanceOverlayOps, painter: painter);
  }

  @override
  void updateRenderObject(BuildContext context, GraphicsViewportRenderObject renderObject) {
    renderObject
      ..overlayOption = performanceOverlayOps
      ..controller = controller;

    if (!identical(renderObject.painter, painter)) {
      renderObject.painter = painter;
    }

    super.updateRenderObject(context, renderObject);
  }
}

abstract class TickerRenderObject extends RenderBox {
  Ticker? _ticker;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _ticker = Ticker(onTick, debugLabel: 'GraphicsViewportRenderObject')..start();
  }

  @mustCallSuper
  void onTick(Duration duration) {}

  @override
  void detach() {
    _ticker?.dispose();
    _ticker = null;
    super.detach();
  }
}

mixin GraphicsViewportCameraMixin on TickerRenderObject {
  final viewport = Viewport2D();

  Gesture _gesture = Gesture.none;

  bool _needsRebuild = false;

  Offset _lastDragPosition = Offset.zero;
  Offset get lastDragPosition => _lastDragPosition;
  set lastDragPosition(Offset value) {
    _lastDragPosition = value;
  }

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
          _needsRebuild = true;
        }
        return;
      }
    }

    var worldDelta = (event.position - lastDragPosition) / viewport.zoom;

    if (_gesture.isMoving && worldDelta.distance > 1.0) {
      viewport.translate(worldDelta);
      lastDragPosition = event.position;
      _needsRebuild = true;
    }
  }
}

mixin GraphicsViewportEventHandleMixin on TickerRenderObject {
  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) => false;
}

class GraphicsViewportRenderObject extends TickerRenderObject
    with GraphicsViewportEventHandleMixin, GraphicsViewportCameraMixin
    implements GraphicsViewportContext {
  GraphicsViewportRenderObject({
    required GraphicsViewportController controller,
    required int overlayOption,
    GvPainter? painter,
  }) : _overlayOption = overlayOption,
       _controller = controller,
       _painter = painter {
    controller._renderObject = WeakReference(this);
  }

  final performanceOverlayPainter = PerformanceOverlayPainter();

  final gridPainter = GridPainter();
  final axisPainter = AxisPainter();
  final editorMetrics = EditorMetricsPainter();

  GvPainter? _painter;
  GvPainter? get painter => _painter;
  set painter(GvPainter? value) {
    _painter?.onDetach();
    value?.onAttached(this);
    _painter = value;
  }

  int _overlayOption;
  int get overlayOption => _overlayOption;
  set overlayOption(int value) {
    if (value == _overlayOption) return;

    _overlayOption = value;
    performanceOverlayPainter.overlayOption = _overlayOption;
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

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _painter?.onAttached(this);
  }

  @override
  void markNeedsPaint() {
    debugPrint('GraphicsViewportRenderObject::markNeedsPaint');
    super.markNeedsPaint();
  }

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    editorMetrics.position = _lastDragPosition;
    if (_painter?.handleEvent(event, entry) ?? false) return;

    super.handleEvent(event, entry);
  }

  @override
  void onTick(Duration duration) {
    super.onTick(duration);
    if (!attached) return;

    final needPaint = (_painter?.needsPaint ?? false) | _needsRebuild;

    if (needPaint) {
      _needsRebuild = false;
      markNeedsPaint();
    }
  }

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
    // draw editor
    .drawObject((canvas) {
      gridPainter.paint(gvContext);
      axisPainter.paint(gvContext);
    });

    if (_painter != null) {
      _painter?.paint(gvContext);
    }

    performanceOverlayPainter.paint(gvContext);
    editorMetrics.paint(gvContext);
    context.canvas.restore();
  }

  @override
  void detach() {
    _painter?.onDetach();
    // editor
    gridPainter.onDetach();
    axisPainter.onDetach();

    // metrics
    performanceOverlayPainter.onDetach();
    editorMetrics.onDetach();
    super.detach();
  }
}
