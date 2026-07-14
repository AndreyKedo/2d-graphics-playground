import 'dart:typed_data';

import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/rendering.dart';
import 'package:graphics_playground/core/foundation/raw_rect.dart';

class Viewport2D with foundation.ChangeNotifier {
  final _worldRect = Float64List(4);
  Size viewportSize = Size.zero;
  Offset _position = Offset.zero;
  double _scale = 1.0;

  double get zoom => _scale;
  Offset get position => _position;

  void reset() {
    _position = Offset.zero;
    _scale = 1.0;
  }

  void translate(Offset delta) {
    if (delta == Offset.zero) return;

    _position += delta;
    notifyListeners();
  }

  void scale(double scale, Offset focalPoint) {
    final oldScale = _scale;
    final newScale = _constraintScale(_scale * scale);
    if (oldScale == newScale) return;

    final worldFocalBefore = screenToWorld(focalPoint);
    _scale = newScale;
    final worldFocalAfter = screenToWorld(focalPoint);
    _position += worldFocalAfter - worldFocalBefore;
    notifyListeners();
  }

  void applyTransformation(Canvas canvas) {
    canvas
      ..translate(viewportSize.width / 2, viewportSize.height / 2)
      ..scale(_scale, -_scale)
      ..translate(_position.dx, _position.dy);
    final rect = canvas.getLocalClipBounds();
    _worldRect[0] = rect.left;
    _worldRect[1] = rect.top;
    _worldRect[2] = rect.right;
    _worldRect[3] = rect.bottom;
  }

  @pragma('vm:prefer-inline')
  Offset screenVectorToWorld(Offset vector) {
    return Offset(vector.dx / _scale, -vector.dy / _scale);
  }

  @pragma('vm:prefer-inline')
  double _constraintScale(double scale) => scale.clamp(0.1, 10.0);

  @pragma('vm:prefer-inline')
  RawRect getWorldRect() => RawRect(_worldRect);

  @pragma('vm:prefer-inline')
  Offset worldToScreen(Offset worldPoint) {
    final center = viewportSize.center(Offset.zero);
    final translated = worldPoint + _position;

    // center + (worldPoint + _position) * _scale
    return Offset(center.dx + translated.dx * _scale, center.dy - translated.dy * _scale);
  }

  @pragma('vm:prefer-inline')
  Offset screenToWorld(Offset screenPoint) {
    final center = viewportSize.center(Offset.zero);
    final relative = Offset((screenPoint.dx - center.dx) / _scale, -(screenPoint.dy - center.dy) / _scale);

    /// (screenPoint - center) / _scale - _position
    return relative - _position;
    // final center = Offset(screenPoint.dx - viewportSize.width / 2, screenPoint.dy - viewportSize.height / 2);
    // return center / _scale + (_position * -1);
    // Мировые_координаты = inverse(Проекционная_матрица × Видовая_матрица) × Экранные_координаты
    // 1. Создаем инвертированную матрицу трансформации
    // Инвертирование матрицы трансформации (обратная матрица) позволяет «отменить» действие исходной матрицы.
    // Это важно, так как матрица линейного преобразования влияет на все векторы векторного пространства:
    // может их сжать или растянуть, сдвинуть или повернуть.
    // Обратная матрица «нейтрализует» действие исходной и возвращает векторы в исходный вид.
    //       y
    //       |                  ┌------------ x
    //       |                  |
    // ------|------ x    =>    |
    //       |                  |
    //       |                  |y
    // [World coordinates]      [Screen coordinates]
    // final inverse = Matrix4.inverted(matrix);
    // // 2. Преобразуем Offset в Vector3
    // // Вектор = Матрица * Вектор
    // final world = inverse.transform3(Vector3(screenPoint.dx, screenPoint.dy, 0));
    // return Offset(world.x, world.y);
  }
}
