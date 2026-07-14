import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:graphics_playground/core/gesture/viewport_pointer_event.dart';
import 'package:graphics_playground/core/painter_context.dart';
import 'package:graphics_playground/core/rendering/canvas_item.dart';
import 'package:graphics_playground/core/rendering/gv_owner.dart';
import 'package:graphics_playground/core/rendering/gv_painter.dart';
import 'package:graphics_playground/core/viewport/viewport_context.dart';

class GvScene extends GvPainterObject with ChangeNotifier implements GvOwner {
  GvScene({required this.children});

  final List<CanvasItem> children;

  final _pointerCaptures = <int, CanvasItem>{};

  @override
  void onAttached(GraphicsViewportContext context) {
    super.onAttached(context);
    for (final item in children) {
      item.mount(this);
    }
  }

  @override
  void onDetach() {
    _pointerCaptures.clear();
    for (final item in children) {
      item.unmount(this);
    }
    super.onDetach();
  }

  @override
  bool handleEvent(ViewportPointerEvent event, BoxHitTestEntry entry) {
    final origin = event.origin;

    if (origin is PointerDownEvent) {
      if (!hitTestItem(event)) return false;
    }

    final item = _pointerCaptures[origin.pointer];
    if (item == null) return false;

    item.handlePointerEvent(event);

    if (origin is PointerUpEvent || origin is PointerCancelEvent) {
      _pointerCaptures.remove(origin.pointer);
    }

    return true;
  }

  @override
  void paint(GVPainterContext context) {
    for (final item in children) {
      item.paint(context);
    }
  }

  @override
  void requestFrame() {
    if (!attached) return;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final item in children) {
      item.unmount(this);
      item.dispose();
    }

    super.dispose();
  }

  @protected
  @nonVirtual
  bool hitTestItem(ViewportPointerEvent event) {
    for (var i = children.length - 1; i >= 0; i--) {
      final item = children[i];

      if (!item.hitTest(event.worldPosition)) {
        continue;
      }

      final result = item.handlePointerEvent(event);

      switch (result) {
        case .ignore:
          continue;

        case .handle:
          return true;

        case .capture:
          _pointerCaptures[event.origin.pointer] = item;
          return true;
      }
    }

    return false;
  }
}
