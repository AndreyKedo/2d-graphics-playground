import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:graphics_playground/core/develop/editor_metrics_painter.dart';
import 'package:graphics_playground/core/develop/performance_overlay_painter.dart';
import 'package:graphics_playground/core/editor/editor_painter.dart';
import 'package:graphics_playground/core/gesture/viewport_pointer_event.dart';
import 'package:graphics_playground/core/rendering/gv_painter.dart';
import 'package:graphics_playground/core/painter_context.dart';
import 'package:graphics_playground/core/viewport/viewport.dart';
import 'package:graphics_playground/core/viewport/viewport_context.dart';

class GraphicsViewport extends LeafRenderObjectWidget {
  const GraphicsViewport({
    super.key,
    this.painter,
    this.performanceOverlayOps = PerformanceOverlayOptionExtension.none,
    this.showEditorMetrics = false,
  });

  final GvPainter? painter;

  final int performanceOverlayOps;
  final bool showEditorMetrics;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return GraphicsViewportRenderObject(
      overlayOption: performanceOverlayOps,
      showEditorMetrics: showEditorMetrics,
      painter: painter,
    );
  }

  @override
  void updateRenderObject(BuildContext context, GraphicsViewportRenderObject renderObject) {
    renderObject
      ..overlayOption = performanceOverlayOps
      ..showEditorMetrics = showEditorMetrics;

    if (!identical(renderObject.painter, painter)) {
      renderObject.painter = painter;
    }

    super.updateRenderObject(context, renderObject);
  }
}

class GraphicsViewportRenderObject extends RenderBox implements GraphicsViewportContext {
  GraphicsViewportRenderObject({required this._overlayOption, required this._showEditorMetrics, this._painter});

  @override
  final viewport = Viewport2D();

  late final ticker = Ticker(onTick);
  final pointers = <int>{};

  final editorMetrics = EditorMetricsPainter();
  final performanceOverlayPainter = PerformanceOverlayPainter();
  final editorPainter = EditorPainter();

  GvPainter? _painter;
  GvPainter? get painter => _painter;
  set painter(GvPainter? value) {
    if (identical(value, painter)) return;

    if (attached) {
      _painter?.removeListener(handleVisualChange);
      _painter?.onDetach();
    }

    _painter = value;

    if (attached) {
      _painter?.onAttached(this);
      _painter?.addListener(handleVisualChange);
    }
    markNeedsPaint();
  }

  int _overlayOption;
  int get overlayOption => _overlayOption;
  set overlayOption(int value) {
    if (value == _overlayOption) return;

    _overlayOption = value;

    performanceOverlayPainter.overlayOption = _overlayOption;
  }

  bool _showEditorMetrics;
  bool get showEditorMetrics => _showEditorMetrics;
  set showEditorMetrics(bool value) {
    if (value == _showEditorMetrics) return;

    _showEditorMetrics = value;
  }

  @override
  bool get sizedByParent => true;

  @override
  bool get isRepaintBoundary => true;

  @override
  Object? get debugCreator => "GraphicsViewportRenderObject";

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) => false;

  @override
  bool get alwaysNeedsCompositing => performanceOverlayPainter.overlayOption != PerformanceOverlayOptionExtension.none;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final parentSize = constraints.biggest;
    // Update viewport
    viewport.viewportSize = parentSize;

    // Overlay setup
    performanceOverlayPainter.overlayRect = Offset.zero & Size(parentSize.width, 200);
    performanceOverlayPainter.overlayOption = _overlayOption;

    debugPrint('GraphicsViewportRenderObject.computeDryLayout: $parentSize');
    return parentSize;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    performanceOverlayPainter.onAttached(this);
    editorMetrics.onAttached(this);
    editorPainter.onAttached(this);
    painter?.onAttached(this);
    painter?.addListener(handleVisualChange);
    viewport.addListener(handleVisualChange);
  }

  @override
  void markNeedsPaint() {
    //debugPrint('GraphicsViewportRenderObject::markNeedsPaint');
    super.markNeedsPaint();
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    final localPosition = event.localPosition;
    final viewportEvent = ViewportPointerEvent(
      origin: event,
      screenPosition: localPosition,
      worldPosition: viewport.screenToWorld(localPosition),
      screenDelta: event.localDelta,
      worldDelta: viewport.screenVectorToWorld(event.localDelta),
    );

    bool hasChange = false;

    hasChange |= painter?.handleEvent(viewportEvent, entry) ?? false;

    if (!hasChange) {
      hasChange |= editorPainter.handleEvent(viewportEvent, entry);
    }

    if (event is PointerDownEvent && hasChange) {
      beginInteraction(event.pointer);
    }

    if (event is PointerUpEvent || event is PointerCancelEvent) {
      endInteraction(event.pointer);
    }
    super.handleEvent(event, entry);
  }

  void beginInteraction(int pointer) {
    final wasAdded = pointers.add(pointer);
    if (!wasAdded) return;

    if (pointers.isNotEmpty && !ticker.isActive) {
      ticker.start();
    }
  }

  void endInteraction(int pointer) {
    final wasRemoved = pointers.remove(pointer);
    if (!wasRemoved) return;

    if (pointers.isEmpty && ticker.isActive) {
      ticker.stop();
      markNeedsPaint();
    }
  }

  void handleVisualChange() {
    if (ticker.isActive) {
      return;
    }
    markNeedsPaint();
  }

  void onTick(Duration elapsed) {
    if (attached) {
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
      ..clipRect(Offset.zero & size);
    viewport.applyTransformation(canvas);

    // editor
    editorPainter.paint(gvContext);

    if (painter != null) {
      painter?.paint(gvContext);
    }

    performanceOverlayPainter.paint(gvContext);
    if (showEditorMetrics) {
      editorMetrics.paint(gvContext);
    }
    context.canvas.restore();
  }

  @override
  void detach() {
    if (ticker.isActive) {
      ticker.stop();
    }

    viewport.removeListener(handleVisualChange);
    painter?.removeListener(handleVisualChange);
    painter?.onDetach();
    // editor
    editorPainter.onDetach();

    performanceOverlayPainter.onDetach();
    editorMetrics.onDetach();
    super.detach();
  }

  @override
  void dispose() {
    ticker.dispose();
    viewport.dispose();
    super.dispose();
  }
}
