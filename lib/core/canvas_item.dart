import 'package:flutter/rendering.dart';
import 'package:graphics_playground/core/gesture/viewport_pointer_event.dart';
import 'package:graphics_playground/core/gv_painter.dart';
import 'package:graphics_playground/core/painter_context.dart';

abstract class CanvasItem extends GvPainterMixin {
  CanvasItem({this.globalPosition = Offset.zero});

  Matrix4 model = Matrix4.identity();

  Offset globalPosition = Offset.zero;
  Offset localPosition = Offset.zero;

  @override
  bool handleEvent(ViewportPointerEvent event, BoxHitTestEntry entry) {
    return false;
  }

  @override
  void paint(GVPainterContext context) {
    // TODO: implement paint
  }
}
