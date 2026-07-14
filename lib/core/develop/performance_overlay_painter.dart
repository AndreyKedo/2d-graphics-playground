import 'package:flutter/rendering.dart';
import 'package:graphics_playground/core/rendering/gv_painter.dart';
import 'package:graphics_playground/core/painter_context.dart';

/// Отображает график производительности отрисовки
class PerformanceOverlayPainter extends GvPainterObject {
  PerformanceOverlayPainter();

  int overlayOption = PerformanceOverlayOptionExtension.none;
  Rect overlayRect = Rect.zero;

  @override
  void paint(GVPainterContext context) {
    final surface = context.surfaceContext;

    if (overlayOption != PerformanceOverlayOptionExtension.none) {
      surface.addLayer(PerformanceOverlayLayer(overlayRect: overlayRect, optionsMask: overlayOption));
    }
  }
}

extension PerformanceOverlayOptionExtension on PerformanceOverlayOption {
  static final all = PerformanceOverlayOption.values.fold(0, (mask, option) => mask | (1 << option.index));

  static const none = -1;

  static int from(Set<PerformanceOverlayOption> options) =>
      options.fold(0, (mask, option) => mask | (1 << option.index));
}
