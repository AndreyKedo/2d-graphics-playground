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

  Offset lastDragPosition = Offset.zero;

  Offset _previsionUpdatePosition = Offset.zero;

  ui.Paragraph buildTextParagraph(String text) {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 12.0))
      ..pushStyle(ui.TextStyle(color: Colors.black))
      ..addText(text);
    return builder.build();
  }

  @override
  void paint(GVPainterContext context) {
    final (:canvas, :viewport) = context.expanded;

    // if (lastDragPosition != _previsionUpdatePosition) {
    //   _previsionUpdatePosition = lastDragPosition;
    //   _picture?.dispose();
    //   _picture = null;
    //   //_layer.layer = null;
    // }
    // canvas.drawPicture(
    //   _picture ??= canvas.drawObjectToPicture((canvas) {
    //     print("DRAW metrics");
    //     final worldPos = lastDragPosition == Offset.zero ? Offset.zero : viewport.screenToWorld(lastDragPosition);
    //     final text =
    //         'Scale: ${viewport.zoom.toStringAsFixed(2)}\n'
    //         'Pos: (${viewport.position.dx.toStringAsFixed(1)}, '
    //         '${viewport.position.dy.toStringAsFixed(1)})\n'
    //         'World: (${worldPos.dx.toStringAsFixed(1)}, '
    //         '${worldPos.dy.toStringAsFixed(1)})';

    //     final paragraph = buildTextParagraph(text);
    //     paragraph.layout(ui.ParagraphConstraints(width: 200));
    //     canvas.drawParagraph(paragraph, Offset(10, 10));
    //   }),
    // );

    if (lastDragPosition != _previsionUpdatePosition) {
      _previsionUpdatePosition = lastDragPosition;
      _layer.layer = null;
    }

    canvas.drawOnPictureLayer(
      layer: _layer,
      context: context.surfaceContext,
      bounds: _bounds,
      draw: (canvas) {
        final worldPos = lastDragPosition == Offset.zero ? Offset.zero : viewport.screenToWorld(lastDragPosition);

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

    // canvas.drawObject((canvas) {
    //   final worldPos = viewport.screenToWorld(lastDragPosition);
    //   final text =
    //       'Scale: ${viewport.zoom.toStringAsFixed(2)}\n'
    //       'Pos: (${viewport.position.dx.toStringAsFixed(1)}, '
    //       '${viewport.position.dy.toStringAsFixed(1)})\n'
    //       'World: (${worldPos.dx.toStringAsFixed(1)}, '
    //       '${worldPos.dy.toStringAsFixed(1)})';

    //   final paragraph = buildTextParagraph(text);
    //   paragraph.layout(ui.ParagraphConstraints(width: 200));
    //   canvas.drawParagraph(paragraph, Offset(10, 10));
    // });
  }

  @override
  void dispose() {
    _layer.layer = null;
    super.dispose();
  }
}
