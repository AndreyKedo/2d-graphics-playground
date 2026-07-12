import 'package:flutter/gestures.dart';

class ViewportPointerEvent {
  ViewportPointerEvent({
    required this.origin,
    required this.screenPosition,
    required this.worldPosition,
    required this.screenDelta,
    required this.worldDelta,
  });

  final PointerEvent origin;

  final Offset screenPosition;
  final Offset worldPosition;
  final Offset screenDelta;
  final Offset worldDelta;
}
