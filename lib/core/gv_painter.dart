import 'package:flutter/rendering.dart';
import 'package:graphics_playground/core/viewport_context.dart';
import 'package:graphics_playground/core/painter_context.dart';
import 'package:graphics_playground/core/viewport.dart';
import 'package:meta/meta.dart';

abstract interface class GvPainter {
  bool get needsPaint;

  @mustCallSuper
  void onAttached(GraphicsViewportContext context);

  void onTick(Duration delta);

  bool handleEvent(PointerEvent event, BoxHitTestEntry entry);

  @mustBeOverridden
  void paint(GVPainterContext context);

  @mustCallSuper
  void onDetach() {}
}

abstract mixin class GvPainterMixin implements GvPainter {
  GvPainterMixin();

  GraphicsViewportContext? _context;
  GraphicsViewportContext get context {
    assert(_context != null, 'Context must be attached');
    return _context!;
  }

  bool get attached => _context != null;

  Viewport2D get viewport {
    assert(attached, 'Context must be attached');
    return context.viewport;
  }

  Size get size {
    assert(attached, 'Context must be attached');
    return context.size;
  }

  @override
  void onTick(Duration delta) {}

  @override
  bool get needsPaint => false;

  @override
  @mustCallSuper
  void onAttached(GraphicsViewportContext context) {
    _context = context;
  }

  @override
  bool handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    return false;
  }

  @override
  @mustBeOverridden
  void paint(GVPainterContext context);

  /// **DO NOT USE CONTEXT AFTER onDetach**. Check [attach] before use.
  @override
  @mustCallSuper
  void onDetach() {
    _context = null;
  }
}
