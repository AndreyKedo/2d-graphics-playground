import 'package:graphics_playground/graphics_viewport/painter_context.dart';
import 'package:meta/meta.dart';

abstract class GvPainter {
  @mustBeOverridden
  void paint(GVPainterContext context);

  @mustCallSuper
  void dispose() {}
}
