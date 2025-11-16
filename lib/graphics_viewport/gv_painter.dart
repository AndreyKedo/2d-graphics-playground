import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:graphics_playground/graphics_viewport/graphics_viewport.dart';
import 'package:graphics_playground/graphics_viewport/painter_context.dart';
import 'package:graphics_playground/graphics_viewport/viewport.dart';
import 'package:meta/meta.dart';

abstract interface class GvPainter {
  bool get needsPaint;

  @mustCallSuper
  void onAttached(GraphicsViewportContext context);

  bool handleEvent(PointerEvent event, HitTestEntry entry);

  @mustBeOverridden
  void paint(GVPainterContext context);

  @mustCallSuper
  void onDetach() {}
}

abstract mixin class GvPainterMixin implements GvPainter {
  GvPainterMixin();

  late GraphicsViewportContext context;

  Viewport2D get viewport => context.viewport;

  @override
  bool get needsPaint => false;

  @override
  @mustCallSuper
  void onAttached(GraphicsViewportContext context) {
    this.context = context;
  }

  @override
  bool handleEvent(PointerEvent event, HitTestEntry entry) {
    return false;
  }

  @override
  @mustBeOverridden
  void paint(GVPainterContext context);

  @override
  @mustCallSuper
  void onDetach() {}
}
