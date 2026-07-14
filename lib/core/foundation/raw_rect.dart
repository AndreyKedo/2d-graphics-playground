import 'dart:typed_data';

extension type const RawRect(Float64List _raw) {
  double get left => _raw[0];
  double get top => _raw[1];
  double get right => _raw[2];
  double get bottom => _raw[3];
}
