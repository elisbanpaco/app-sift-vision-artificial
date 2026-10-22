/// Rectángulo del objeto en coordenadas normalizadas de la imagen (0 a 1).
class ObjectRegion {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const ObjectRegion(this.left, this.top, this.right, this.bottom);

  bool get isValid =>
      [left, top, right, bottom].every((v) => v.isFinite && v >= 0 && v <= 1) &&
      right > left &&
      bottom > top;

  List<double> toJson() => [left, top, right, bottom];

  factory ObjectRegion.fromJson(List<dynamic> values) => ObjectRegion(
    (values[0] as num).toDouble(),
    (values[1] as num).toDouble(),
    (values[2] as num).toDouble(),
    (values[3] as num).toDouble(),
  );
}
