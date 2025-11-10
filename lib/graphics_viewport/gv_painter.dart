import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:graphics_playground/graphics_viewport/graphics_viewport.dart';
import 'package:graphics_playground/graphics_viewport/painter_context.dart';
import 'package:graphics_playground/graphics_viewport/viewport.dart';
import 'package:meta/meta.dart';

abstract mixin class GvPainter {
  GvPainter();

  late GraphicsViewportContext context;

  Viewport2D get viewport => context.viewport;

  bool get needsPaint => false;

  @mustCallSuper
  void onAttached(GraphicsViewportContext context) {
    this.context = context;
  }

  bool handleEvent(PointerEvent event, HitTestEntry entry) {
    return false;
  }

  @mustBeOverridden
  void paint(GVPainterContext context);

  @mustCallSuper
  void onDetach() {}
}
