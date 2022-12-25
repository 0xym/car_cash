import 'dart:ui';

import './distance.dart';
import './preferences.dart';
import '../utils/common.dart';
import '../utils/db_names.dart';

class FuelTank {
  final int? type;
  final int? unit;
  final double? capacity;

  FuelTank(this.type, this.unit, this.capacity);

  FuelTank withType(int type) => FuelTank(type, this.unit, this.capacity);
  FuelTank withUnit(int unit) => FuelTank(this.type, unit, this.capacity);
  FuelTank withCapacity(double? capacity) => FuelTank(this.type, this.unit, capacity);
}

const DEFAULT_CAR = Preference('defaultCar', int, -1);

class Car {
  static const ID = 'id';
  static const BRAND = 'brand';
  static const MODEL = 'model';
  static const NAME = 'name';
  static const DISTANCE_UNIT = 'distanceUnit';
  static const INITIAL_MILEAGE = 'initialMeleage';
  static const FUEL_TYPE = 'fuelType';
  static const FUEL_UNIT = 'fuelUnit';
  static const FUEL_CAPACITY = 'fuelCapacity';
  static const COLOR = 'color';
  static const MAX_FUEL_TYPES = 3;

  final int? id;
  final String? brand;
  final String? model;
  final String? name;
  final Distance? distanceUnit;
  final int? initialMileage;
  final List<FuelTank> _fuelTanks;
  final Color? color;

  static String get dbLayout {
    return '($ID $PRIMARY_KEY, $BRAND $TEXT, $MODEL $TEXT, $NAME $TEXT, $DISTANCE_UNIT $TEXT, $INITIAL_MILEAGE $INT, $COLOR $INT, ' +
        List<String>.generate(
                MAX_FUEL_TYPES, (i) => '$FUEL_TYPE$i $INT, $FUEL_UNIT$i $INT, $FUEL_CAPACITY$i $REAL')
            .join(',') +
        ')';
  }

  Car.copy(Car other,
      {int? id,
      String? brand,
      String? model,
      String? name,
      Distance? distanceUnit,
      int? initialMileage,
      Color? color,
      List<FuelTank>? fuelTypes})
      : this.id = id ?? other.id,
        this.brand = brand ?? other.brand,
        this.model = model ?? other.model,
        this.name = name ?? other.name,
        this.distanceUnit = distanceUnit ?? other.distanceUnit,
        this.initialMileage = initialMileage ?? other.initialMileage,
        this.color = color ?? other.color,
        this._fuelTanks = fuelTypes ?? other.fuelTanks;

  Car copyWith(
          {int? id,
          String? brand,
          String? model,
          String? name,
          Distance? distanceUnit,
          int? initialMileage,
          Color? color,
          List<FuelTank>? fuelTypes}) =>
      Car.copy(this, id: id, brand: brand, model: model, name: name, distanceUnit: distanceUnit, initialMileage: initialMileage, fuelTypes: fuelTypes, color: color);

  Map<String, Object?> serialize() => {
        ID: id,
        BRAND: brand,
        MODEL: model,
        NAME: name,
        DISTANCE_UNIT: distanceUnit.toString(),
        INITIAL_MILEAGE: initialMileage,
        COLOR: color?.value,
      }
        ..addAll(Map<String, Object?>.fromIterable(
            List<int>.generate(MAX_FUEL_TYPES, (i) => i),
            key: (i) => '$FUEL_CAPACITY$i',
            value: (i) => _fuelTanks.length > i ? _fuelTanks[i].capacity : null))
        ..addAll(Map<String, Object?>.fromIterable(
            List<int>.generate(MAX_FUEL_TYPES, (i) => i),
            key: (i) => '$FUEL_TYPE$i',
            value: (i) => _fuelTanks.length > i ? _fuelTanks[i].type : null))
        ..addAll(Map<String, Object?>.fromIterable(
            List<int>.generate(MAX_FUEL_TYPES, (i) => i),
            key: (i) => '$FUEL_UNIT$i',
            value: (i) => _fuelTanks.length > i ? _fuelTanks[i].unit : null));

  Car()
      : id = null,
        brand = null,
        model = null,
        name = null,
        distanceUnit = Distance.km,
        initialMileage = null,
        color = null,
        _fuelTanks = [FuelTank(0, 0, null)];

  Car.deserialize(Map<String, dynamic> json)
      : id = json[ID],
        brand = nullify(json[BRAND]),
        model = nullify(json[MODEL]),
        name = json[NAME],
        distanceUnit = json[DISTANCE_UNIT] == null ? null : Distance.fromString(json[DISTANCE_UNIT]),
        initialMileage = json[INITIAL_MILEAGE],
        color = json[COLOR] == null ? null : Color(json[COLOR]),
        _fuelTanks = List<FuelTank>.generate(MAX_FUEL_TYPES,
            (i) => FuelTank(json['$FUEL_TYPE$i'], json['$FUEL_UNIT$i'], json['$FUEL_CAPACITY$i'])) {
    sanitize();
  }

  void sanitize() {
    _fuelTanks.removeWhere((item) => item.type == null || item.unit == null);
    //TODO - remove duplicated fuel types
    if (_fuelTanks.length == 0) {
      _fuelTanks.add(FuelTank(null, null, null));
    }
  }

  List<FuelTank> get fuelTanks => _fuelTanks.toList();

  String? get brandAndModel {
    return brand == null ? model : model == null ? brand : '$brand $model';
  }
}
