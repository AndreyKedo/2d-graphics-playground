import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:graphics_playground/core/gesture/viewport_pointer_event.dart';
import 'package:graphics_playground/core/viewport/viewport_context.dart';
import 'package:graphics_playground/core/painter_context.dart';
import 'package:graphics_playground/core/viewport/viewport.dart';
import 'package:meta/meta.dart';

abstract interface class GvPainter implements Listenable {
  @mustCallSuper
  void onAttached(GraphicsViewportContext context);

  bool handleEvent(ViewportPointerEvent event, BoxHitTestEntry entry);

  @mustBeOverridden
  void paint(GVPainterContext context);

  @mustCallSuper
  void onDetach() {}
}

abstract class GvPainterMixin implements GvPainter {
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
  @mustCallSuper
  void onAttached(GraphicsViewportContext context) {
    _context = context;
  }

  @override
  bool handleEvent(ViewportPointerEvent event, BoxHitTestEntry entry) {
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

  @override
  void addListener(VoidCallback listener) {
    // TODO: implement addListener
  }

  @override
  void removeListener(VoidCallback listener) {
    // TODO: implement removeListener
  }
}
