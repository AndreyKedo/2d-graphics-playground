import 'dart:ui';

import 'package:flutter/rendering.dart';

extension CanvasExtension on Canvas {
  Canvas drawObject(void Function(Canvas canvas) draw) {
    draw(this);
    return this;
  }

  Picture drawObjectToPicture(void Function(Canvas canvas) draw) {
    final pictureRecorder = RendererBinding.instance.createPictureRecorder();
    final canvas = RendererBinding.instance.createCanvas(pictureRecorder);
    draw(canvas);
    return pictureRecorder.endRecording();
  }

  void drawOnPictureLayer({
    required LayerHandle<PictureLayer> layer,
    required PaintingContext context,
    required ValueSetter<Canvas> draw,
    Rect bounds = Rect.zero,
  }) {
    if (layer.layer == null) {
      final pictureRecorder = PictureRecorder();
      final canvas = Canvas(pictureRecorder);

      draw(canvas);

      final picture = pictureRecorder.endRecording();

      layer.layer = PictureLayer(bounds)..picture = picture;
    }

    if (layer.layer != null) {
      context.addLayer(layer.layer!);
    }
  }
}
