import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

extension type const RawRect(Float32List _raw) {
  factory RawRect.fromLTRB(double left, double top, double right, double bottom) {
    final storage = Float32List(4)
      ..[0] = left
      ..[1] = top
      ..[2] = right
      ..[3] = bottom;
    return RawRect(storage);
  }

  factory RawRect.view(RawRect value) {
    return RawRectView(value.storage);
  }

  static final zero = RawRect.fromLTRB(0, 0, 0, 0);

  Float32List get storage => Float32List.view(_raw.buffer);

  void setFrom(Rect rect) {
    _raw[0] = rect.left;
    _raw[1] = rect.top;
    _raw[2] = rect.right;
    _raw[3] = rect.bottom;
  }

  void setFromDouble(double left, double top, double right, double bottom) {
    _raw[0] = left;
    _raw[1] = top;
    _raw[2] = right;
    _raw[3] = bottom;
  }

  void setFromPoints(Offset a, Offset b) {
    _raw[0] = math.min(a.dx, b.dx);
    _raw[1] = math.min(a.dy, b.dy);
    _raw[2] = math.max(a.dx, b.dx);
    _raw[3] = math.max(a.dy, b.dy);
  }

  double get left => _raw[0];
  double get top => _raw[1];
  double get right => _raw[2];
  double get bottom => _raw[3];

  double get width => right - left;

  double get height => bottom - top;

  Size get size => Size(width, height);

  Offset get topLeft => Offset(left, top);

  Offset get topRight => Offset(right, top);

  Offset get center => Offset(left + width / 2.0, top + height / 2.0);

  Offset get bottomLeft => Offset(left, bottom);

  Offset get bottomRight => Offset(right, bottom);

  bool contains(Offset offset) {
    return offset.dx >= left && offset.dx < right && offset.dy >= top && offset.dy < bottom;
  }

  bool overlaps(Rect other) {
    if (right <= other.left || other.right <= left) {
      return false;
    }
    if (bottom <= other.top || other.bottom <= top) {
      return false;
    }
    return true;
  }
}

extension type RawRectView(Float32List _raw) implements RawRect {
  @redeclare
  void setFromPoints(Offset a, Offset b) {
    _throwUnmodifiableException();
  }

  @redeclare
  void setFromDouble(double left, double top, double right, double bottom) {
    _throwUnmodifiableException();
  }

  @redeclare
  void setFrom(Rect rect) {
    _throwUnmodifiableException();
  }

  Never _throwUnmodifiableException() {
    throw StateError('View is unmodifiable');
  }
}
