import 'package:flutter/rendering.dart';
//import 'package:vector_math/vector_math_64.dart' show Vector3;

class Viewport2D {
  //Matrix4 matrix = Matrix4.identity();
  Size viewportSize = Size.zero;
  Offset _position = Offset.zero;
  double _scale = 1.0;

  double get zoom => _scale;
  Offset get position => _position;

  void updateProjection(Size size) {
    viewportSize = size;
  }

  void reset() {
    _position = Offset.zero;
    _scale = 1.0;
  }

  void setPosition(Offset position) {
    _position = position;
  }

  void translate(Offset delta) {
    _position += delta;
  }

  bool scale(double scale, Offset focalPoint) {
    final oldScale = _scale;
    final newScale = _constraintScale(_scale * scale);

    if (oldScale == newScale) return false;
    _scale = newScale;
    // final worldFocal = screenToWorld(focalPoint);
    // final r = Vector3(worldFocal.dx, worldFocal.dy, 1) - Vector3(worldFocalBefore.dx, worldFocalBefore.dy, 1.0);
    // worldFocalBefore = worldFocal;
    // // 2. Устанавливаем новый масштаб
    // _scale = newScale;
    // _position += _position - Offset(r.x, r.y);
    //_position += (worldFocalBefore - _position) * (oldScale / newScale);

    return true;
  }

  void applyTransformation(Canvas canvas) {
    canvas
      ..translate(viewportSize.width / 2, viewportSize.height / 2)
      ..scale(_scale, _scale)
      ..translate(_position.dx, _position.dy);
    //matrix = Matrix4.fromFloat64List(canvas.getTransform());
  }

  @pragma('vm:prefer-inline')
  double _constraintScale(double scale) {
    return scale.clamp(0.1, 10.0);
  }

  @pragma('vm:prefer-inline')
  Rect getWorldRect() {
    final topLeft = screenToWorld(Offset.zero);
    final bottomRight = screenToWorld(Offset(viewportSize.width, viewportSize.height));
    return Rect.fromPoints(topLeft, bottomRight);
  }

  @pragma('vm:prefer-inline')
  Offset worldToScreen(Offset worldPoint) {
    final center = worldPoint - _position;
    return center * _scale + Offset(viewportSize.width / 2, viewportSize.height / 2);
    // final screen = matrix.transform3(Vector3(worldPoint.dx, worldPoint.dy, 0));
    // return Offset(screen.x, screen.y);
  }

  @pragma('vm:prefer-inline')
  Offset screenToWorld(Offset screenPoint) {
    final center = Offset(screenPoint.dx - viewportSize.width / 2, screenPoint.dy - viewportSize.height / 2);
    return center / _scale + (_position * -1);
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
