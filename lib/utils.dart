import 'dart:ui';

import 'package:flutter/rendering.dart';

void drawOnPictureLayer({
  required LayerHandle<PictureLayer> layer,
  required PaintingContext context,
  required Rect bounds,
  required ValueSetter<Canvas> draw,
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
