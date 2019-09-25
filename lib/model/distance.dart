import '../utils/common.dart';

enum DistanceUnit {
  km,
  mile
}

class Distance {
  final DistanceUnit unit;
  Distance(this.unit);
  static Distance fromString(String value) {
    final unit = EnumParser<DistanceUnit>(DistanceUnit.values).fromString(value);
    return unit == null ? null : Distance(unit);
  }

  static Map<DistanceUnit, double> factor = {
    DistanceUnit.km: 1000,
    DistanceUnit.mile: 1609
  };
  static final Distance km = Distance(DistanceUnit.km);
  static final Distance mile = Distance(DistanceUnit.mile);

  double toSi(double distance) => distance == null ? null : distance * factor[unit];
  double toUnit(double distance) => distance == null ? null : distance / factor[unit];

  @override
  String toString() {
    return {DistanceUnit.km: 'unitKm', DistanceUnit.mile: 'unitMile'}[unit];
  }

  @override
  bool operator ==(other) {
    return (other is Distance && other.unit == unit) || (other is DistanceUnit && other == unit) ;
  }

}