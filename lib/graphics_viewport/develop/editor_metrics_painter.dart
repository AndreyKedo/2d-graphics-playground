import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:graphics_playground/core/canvas_extension.dart';
import 'package:graphics_playground/graphics_viewport/gv_painter.dart';
import 'package:graphics_playground/graphics_viewport/painter_context.dart';

class EditorMetricsPainter extends GvPainter {
  EditorMetricsPainter();

  final _layer = LayerHandle<PictureLayer>();

  //ui.Picture? _picture;

  final Rect _bounds = Offset.zero & Size(200, 200);

  Offset position = Offset.zero;

  double _zoom = .0;

  ui.Paragraph buildTextParagraph(String text) {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 12.0))
      ..pushStyle(ui.TextStyle(color: Colors.black))
      ..addText(text);
    return builder.build();
  }

  @override
  void paint(GVPainterContext context) {
    final (:canvas, :viewport) = context.expanded;

    final worldPos = position == Offset.zero ? Offset.zero : viewport.screenToWorld(position);
    if (position != worldPos || _zoom != viewport.zoom) {
      _layer.layer = null;
    }
    position = worldPos;
    _zoom = viewport.zoom;

    canvas.drawOnPictureLayer(
      layer: _layer,
      context: context.surfaceContext,
      bounds: _bounds,
      draw: (canvas) {
        final paragraph = buildTextParagraph(
          'Scale: ${viewport.zoom.toStringAsFixed(2)}\n'
          'Pos: (${viewport.position.dx.toStringAsFixed(1)}, '
          '${viewport.position.dy.toStringAsFixed(1)})\n'
          'World: (${worldPos.dx.toStringAsFixed(1)}, '
          '${worldPos.dy.toStringAsFixed(1)})',
        );
        paragraph.layout(ui.ParagraphConstraints(width: 200));
        canvas.drawParagraph(paragraph, Offset(10, 10));
      },
    );
  }

  @override
  void onDetach() {
    _layer.layer = null;
    super.onDetach();
  }
}
