import 'dart:typed_data';
import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';

class Viewport2D {
  Matrix4 _view = Matrix4.identity();
  Matrix4 _projection = Matrix4.identity();

  Offset _position = Offset.zero;
  double _scale = 1.0;

  // Видовая матрица (преобразования камеры)
  Matrix4 get view => _view.clone();

  // Проекционная матрица (преобразования в экранные координаты)
  Matrix4 get projection => _projection.clone();

  Float64List get rawMatrix => _view.storage;

  double get zoom => _scale;

  void updateProjection(Size size) {
    // final halfWidth = size.width / 2;
    // final halfHeight = size.height / 2;

    //_projection = makeOrthographicMatrix(-halfWidth, halfWidth, -halfHeight, halfHeight, 0, 100);
    _projection = Matrix4.translation(Vector3(size.width / 2, size.height / 2, 0))
      // Отражение по оси Y
      ..scaleByVector3(Vector3(1, -1, 1));
  }

  void setMatrixRaw(Matrix4 matrix) {
    _view = matrix;
  }

  void reset() {
    _position = Offset.zero;
    _scale = 1.0;
    _view = Matrix4.identity();
  }

  void setPosition(Offset position) {
    _position = position;
    _updateMatrix();
  }

  void translate(Offset delta) {
    _position += delta;
    _updateMatrix();
  }

  void scale(double scale, [Offset? focalPoint]) {
    _scale *= scale;
    _scale = _scale.clamp(1, 10.0) / 10; // Ограничения масштаба
    _updateMatrix();
  }

  @pragma('vm:prefer-inline')
  void _updateMatrix() {
    _view = Matrix4.translation(Vector3(_position.dx, -_position.dy, 0))..scaleByVector3(Vector3.all(_scale));
  }

  Rect getWorldRect(Size size) {
    // Преобразуем углы экрана в мировые координаты
    final topLeft = screenToWorld(Offset.zero, size);

    final bottomRight = screenToWorld(Offset(size.width, size.height), size);

    return Rect.fromPoints(topLeft, bottomRight);
  }

  // Методы для преобразования координат
  Offset worldToScreen(Offset worldPoint, Size viewportSize) {
    final transformed = _view.transform3(Vector3(worldPoint.dx, worldPoint.dy, 0));
    return Offset(transformed.x + viewportSize.width / 2, transformed.y + viewportSize.height / 2);
  }

  Offset screenToWorld(Offset screenPoint, Size viewportSize) {
    // Возвращаем матрицу к исходному состоянию
    // То есть переводим трансформацию в к мировым координатам
    final inverse = Matrix4.inverted(_view);
    final world = inverse.transform3(
      Vector3(screenPoint.dx - viewportSize.width / 2, screenPoint.dy - viewportSize.height / 2, 0),
    );
    return Offset(world.x, world.y);
  }
}
