import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:graphics_playground/core/gesture/gesture.dart';
import 'package:graphics_playground/core/gesture/viewport_pointer_event.dart';
import 'package:graphics_playground/core/painter_context.dart';
import 'package:graphics_playground/core/rendering/canvas_item.dart';
import 'package:graphics_playground/core/rendering/gv_owner.dart';
import 'package:graphics_playground/core/rendering/gv_painter.dart';
import 'package:graphics_playground/core/rendering/transform_gizmo.dart';
import 'package:graphics_playground/core/viewport/viewport_context.dart';

class GvScene extends GvPainterObject with ChangeNotifier implements GvOwner {
  GvScene();

  @protected
  final children = <CanvasItem>[];

  @protected
  final gizmo = TransformGizmo();

  final _pointerCaptures = <int, GvPointerHandler>{};

  CanvasItem? _selected;

  CanvasItem? get selected => _selected;
  set selected(CanvasItem? item) {
    if (identical(_selected, item)) return;
    _selected = item;
    gizmo.target = item;
    requestFrame();
  }

  void bulkAddItems(Iterable<CanvasItem> items) {
    children.addAll(items);
    requestFrame();
  }

  void addItem(CanvasItem item) {
    children.add(item);
    requestFrame();
  }

  @override
  void onAttached(GraphicsViewportContext context) {
    super.onAttached(context);
    gizmo.onAttached(context);
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
    gizmo.onDetach();
    super.onDetach();
  }

  @override
  bool handleEvent(ViewportPointerEvent event, BoxHitTestEntry entry) {
    final origin = event.origin;

    if (origin is PointerDownEvent) {
      final gizmoResult = gizmo.handlePointerEvent(event);
      if (gizmoResult == .capture) {
        _pointerCaptures[origin.pointer] = gizmo;
        return true;
      }

      if (!hitTestItem(event)) {
        if (origin.buttons & kPrimaryMouseButton > 0) {
          selected = null;
        }

        return false;
      }
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

    gizmo.paint(context);
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
    if (children.isEmpty) return false;

    for (var i = children.length - 1; i >= 0; i--) {
      final item = children[i];

      if (!item.hitTest(event.worldPosition)) continue;

      final result = item.handlePointerEvent(event);
      if (result == .ignore) continue;

      selected = item;

      if (result == .capture) {
        _pointerCaptures[event.origin.pointer] = item;
      }

      return true;
    }

    return false;
  }
}
