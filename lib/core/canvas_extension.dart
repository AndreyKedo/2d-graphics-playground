import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

/// Собирает инструкции визуализации в [ui.Picture]
ui.Picture drawObjectToPicture(void Function(Canvas canvas) draw) {
  final pictureRecorder = RendererBinding.instance.createPictureRecorder();
  final canvas = RendererBinding.instance.createCanvas(pictureRecorder);
  draw(canvas);
  return pictureRecorder.endRecording();
}
