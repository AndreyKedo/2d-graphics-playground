import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';

class Viewport2D {
  Matrix4 _view = Matrix4.identity();
  Matrix4 _projection = Matrix4.identity();

  Size viewportSize = Size.zero;
  Offset _position = Offset.zero;
  double _scale = 1.0;

  // Видовая матрица (преобразования камеры)
  Matrix4 get view => _view.clone();
  // Проекционная матрица (преобразования в экранные координаты)
  Matrix4 get projection => _projection.clone();
  // Комбинированная матрица (проекционная * видовая)
  Matrix4 get matrix => _projection * _view;

  double get zoom => _scale;

  void updateProjection(Size size) {
    viewportSize = size;
    _projection = Matrix4.translation(Vector3(size.width / 2, size.height / 2, 0))
      // Отражение по оси Y
      ..scaleByVector3(Vector3(1, -1, 1));
    _updateMatrix();
  }

  void setMatrixRaw(Matrix4 matrix) {
    _view.multiply(matrix);
  }

  void reset() {
    _position = Offset.zero;
    _scale = 1.0;
    _updateMatrix();
  }

  void setPosition(Offset position) {
    _position = position;
    _updateMatrix();
  }

  void translate(Offset delta) {
    _position += delta * _scale;
    _updateMatrix();
  }

  void scale(double scale) {
    // Применяем масштабирование
    final newScale = (_scale * scale).clamp(0.1, 10.0);
    _scale = newScale;
    _updateMatrix();
  }

  @pragma('vm:prefer-inline')
  void _updateMatrix() {
    _view = Matrix4.translation(Vector3(_position.dx, -_position.dy, 0))..scaleByVector3(Vector3(_scale, _scale, 1));
  }

  @pragma('vm:prefer-inline')
  Rect getWorldRect() {
    final topLeft = screenToWorld(Offset.zero);
    final bottomRight = screenToWorld(Offset(viewportSize.width, viewportSize.height));
    return Rect.fromPoints(topLeft, bottomRight);
  }

  @pragma('vm:prefer-inline')
  Offset screenToWorld(Offset screenPoint) {
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
    final inverse = Matrix4.inverted(matrix);
    // 2. Преобразуем Offset в Vector3
    // Вектор = Матрица * Вектор
    final world = inverse.transform3(Vector3(screenPoint.dx, screenPoint.dy, 0));
    return Offset(world.x, world.y);
  }
}
