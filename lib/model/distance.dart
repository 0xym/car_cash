import '../utils/common.dart';

enum DistanceUnit {
  km,
  mile
}

class Distance {
  final DistanceUnit unit;
  Distance.internal(this.unit);
  static Distance? fromString(String value) {
    return EnumParser<Distance>([km, mile]).fromString(value);
  }

  static Map<DistanceUnit, double> factor = {
    DistanceUnit.km: 1000,
    DistanceUnit.mile: 1609.344,
  };
  static final Distance km = Distance.internal(DistanceUnit.km);
  static final Distance mile = Distance.internal(DistanceUnit.mile);

  double? toSi(double? distance) => distance == null ? null : distance * factor[unit]!;
  double? toUnit(double? distance) => distance == null ? null : distance / factor[unit]!;

  String abbreviated() {
    return {DistanceUnit.km: 'km', DistanceUnit.mile: 'mile'}[unit]!;
  }

  @override
  String toString() {
    return {DistanceUnit.km: 'unitKm', DistanceUnit.mile: 'unitMile'}[unit]!;
  }

  @override
  bool operator ==(other) {
    return (other is Distance && other.unit == unit) || (other is DistanceUnit && other == unit) ;
  }

  @override
  int get hashCode => unit.hashCode;

}