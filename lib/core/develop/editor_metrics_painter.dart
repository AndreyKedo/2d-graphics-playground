import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:graphics_playground/core/gv_painter.dart';
import 'package:graphics_playground/core/painter_context.dart';

/// Отображает метрики о смещение мира и его масштабе
class EditorMetricsPainter extends GvPainterMixin {
  EditorMetricsPainter();

  final _layer = LayerHandle<OffsetLayer>();

  ui.Paragraph buildTextParagraph(String text) {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 12.0))
      ..pushStyle(ui.TextStyle(color: Colors.black))
      ..addText(text);
    return builder.build();
  }

  @override
  void paint(GVPainterContext context) {
    final (:canvas, :viewport) = context.expanded;

    context.surfaceContext.pushLayer(_layer.layer ??= OffsetLayer(), (paintContext, _) {
      final paragraph = buildTextParagraph(
        'Zoom: ${viewport.zoom.toStringAsFixed(2)}\n'
        'Offset: (${viewport.position.dx.toStringAsFixed(1)}, '
        '${viewport.position.dy.toStringAsFixed(1)})\n',
      );
      paragraph.layout(ui.ParagraphConstraints(width: 200));
      paintContext.canvas.drawParagraph(paragraph, Offset(10, 10));
    }, Offset.zero);
  }

  @override
  void onDetach() {
    _layer.layer = null;
    super.onDetach();
  }
}
