import 'package:flutter/rendering.dart';
import 'package:graphics_playground/core/viewport/viewport.dart';

abstract interface class GraphicsViewportContext {
  Viewport2D get viewport;

  Size get size;
}
