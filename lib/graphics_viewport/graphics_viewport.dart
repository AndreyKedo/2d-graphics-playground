import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:graphics_playground/core/develop/editor_metrics_painter.dart';
import 'package:graphics_playground/core/develop/performance_overlay_painter.dart';
import 'package:graphics_playground/core/editor/editor_painter.dart';
import 'package:graphics_playground/core/gv_painter.dart';
import 'package:graphics_playground/core/painter_context.dart';
import 'package:graphics_playground/core/viewport.dart';
import 'package:graphics_playground/core/viewport_context.dart';

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

abstract class TickerRenderObject extends RenderBox {
  Ticker? _ticker;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _ticker = Ticker(onTick, debugLabel: 'GraphicsViewportRenderObject::Ticker')..start();
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

mixin GraphicsViewportEventHandleMixin on TickerRenderObject {
  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) => false;
}

class GraphicsViewportRenderObject extends TickerRenderObject
    with GraphicsViewportEventHandleMixin
    implements GraphicsViewportContext {
  GraphicsViewportRenderObject({required int overlayOption, required bool showEditorMetrics, GvPainter? painter})
    : _overlayOption = overlayOption,
      _painter = painter,
      _showEditorMetrics = showEditorMetrics;

  @override
  final viewport = Viewport2D();

  final editorMetrics = EditorMetricsPainter();
  final performanceOverlayPainter = PerformanceOverlayPainter();
  final editorPainter = EditorPainter();

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
    performanceOverlayPainter.onAttached(this);
    editorMetrics.onAttached(this);
    editorPainter.onAttached(this);
    painter?.onAttached(this);
  }

  @override
  void markNeedsPaint() {
    debugPrint('GraphicsViewportRenderObject::markNeedsPaint');
    super.markNeedsPaint();
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    super.handleEvent(event, entry);
    if (painter?.handleEvent(event, entry) ?? false) return;
    editorPainter.handleEvent(event, entry);
  }

  @override
  void onTick(Duration duration) {
    super.onTick(duration);
    if (!attached) return;

    performanceOverlayPainter.onTick(duration);
    editorMetrics.onTick(duration);
    editorPainter.onTick(duration);

    final innerEffectiveNeedPaint =
        editorPainter.needsPaint | performanceOverlayPainter.needsPaint | editorMetrics.needsPaint;

    painter?.onTick(duration);

    if ((painter?.needsPaint ?? false) | innerEffectiveNeedPaint) {
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
    painter?.onDetach();
    // editor
    editorPainter.onDetach();

    performanceOverlayPainter.onDetach();
    editorMetrics.onDetach();
    super.detach();
  }
}
