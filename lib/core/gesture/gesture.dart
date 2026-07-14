extension type const Gesture._(int val) implements Object {
  static const Gesture none = Gesture._(0);

  static const Gesture down = Gesture._(1);
  static const Gesture up = Gesture._(2);
  static const Gesture move = Gesture._(3);
  static const Gesture scroll = Gesture._(4);

  Gesture compose(Gesture other) => Gesture._(val | other.val);

  bool get isMoving {
    return _bit(down.val) && _bit(move.val);
  }

  bool _bit(int bit) => (val & bit) != 0;

  Gesture operator +(Gesture other) => compose(other);
}

enum GvPointerEventResult { ignore, handle, capture }
