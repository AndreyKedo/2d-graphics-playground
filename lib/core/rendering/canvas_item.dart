import 'package:flutter/rendering.dart';
import 'package:graphics_playground/core/gesture/gesture.dart';
import 'package:graphics_playground/core/gesture/viewport_pointer_event.dart';
import 'package:graphics_playground/core/painter_context.dart';
import 'package:graphics_playground/core/rendering/gv_owner.dart';
import 'package:meta/meta.dart';

abstract class CanvasItem {
  CanvasItem({Offset worldPosition = Offset.zero}) {
    _modelTransform.setTranslationRaw(worldPosition.dx, worldPosition.dy, 0);
  }

  // MARK: Private properties
  final _modelTransform = Matrix4.identity();
  final _inverseModelTransform = Matrix4.identity();

  GvOwner? _owner;
  bool _disposed = false;
  bool _inverseTransformDirty = true;

  // MARK: properties
  bool get mounted => _owner != null;

  Offset get worldPosition {
    return MatrixUtils.transformPoint(_modelTransform, Offset.zero);
  }

  Offset worldToLocal(Offset worldPosition) {
    if (_inverseTransformDirty) {
      _inverseModelTransform
        ..setFrom(_modelTransform)
        ..invert();
      _inverseTransformDirty = false;
    }

    return MatrixUtils.transformPoint(_inverseModelTransform, worldPosition);
  }

  // MARK: manipulate
  set worldPosition(Offset value) {
    if (worldPosition == value) return;
    _modelTransform.setTranslationRaw(value.dx, value.dy, 0);
    markNeedsPaint();
  }

  void translateWorld(Offset delta) => worldPosition += delta;

  // MARK: Lifecycle
  @nonVirtual
  void mount(GvOwner owner) {
    assert(_owner == null);
    _owner = owner;
  }

  @nonVirtual
  void unmount(GvOwner owner) {
    assert(identical(_owner, owner));
    _owner = null;
  }

  @mustCallSuper
  void dispose() {
    assert(_owner == null);
    assert(!_disposed);
    _disposed = true;
  }

  // MARK: Gesture
  @nonVirtual
  bool hitTest(Offset worldPosition) {
    final localPosition = worldToLocal(worldPosition);
    return hitTestLocal(localPosition);
  }

  // MARK: overridable
  @mustBeOverridden
  void draw(Canvas canvas);

  GvPointerEventResult handlePointerEvent(ViewportPointerEvent event) => .ignore;

  @protected
  bool hitTestLocal(Offset localPosition);

  // MARK: inner
  @protected
  @nonVirtual
  void markNeedsPaint() {
    _owner?.requestFrame();
    _inverseTransformDirty = true;
  }

  @nonVirtual
  void paint(GVPainterContext context) {
    final canvas = context.canvas;

    canvas
      ..save()
      ..transform(_modelTransform.storage);

    draw(canvas);

    canvas.restore();
  }
}
