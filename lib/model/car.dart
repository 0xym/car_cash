import 'package:car_cash/utils/common.dart';
import './distance.dart';
import '../utils/db_names.dart';

class FuelTypeAndUnit {
  static const TYPE = 'type';
  static const UNIT = 'unit';

  int type;
  int unit;
  FuelTypeAndUnit(this.type, this.unit);
}

class Car {
  static const ID = 'id';
  static const BRAND = 'brand';
  static const MODEL = 'model';
  static const NAME = 'name';
  static const DISTANCE_UNIT = 'distanceUnit';
  static const INITIAL_MILEAGE = 'initialMeleage';
  static const FUEL_TYPE = 'fuelType';
  static const FUEL_UNIT = 'fuelUnit';
  static const MAX_FUEL_TYPES = 3;

  //todo - display clolor
  int id;
  String brand;
  String model;
  String name;
  Distance distanceUnit = Distance.km;
  int initialMileage;
  List<FuelTypeAndUnit> fuelTypes = [FuelTypeAndUnit(0, 0)];

  static String get dbLayout {
    return '($ID $PRIMARY_KEY, $BRAND $TEXT, $MODEL $TEXT, $NAME $TEXT, $DISTANCE_UNIT $TEXT, $INITIAL_MILEAGE $INT,' + 
    List<String>.generate(MAX_FUEL_TYPES, (i) => '$FUEL_TYPE$i $INT, $FUEL_UNIT$i $INT').join(',') + ')';
  }

  Map<String, Object> serialize() => {
    ID: id,
    BRAND: brand,
    MODEL: model,
    NAME: name,
    DISTANCE_UNIT: distanceUnit.toString(),
    INITIAL_MILEAGE: initialMileage
  }..addAll(Map<String, Object>.fromIterable(List<int>.generate(MAX_FUEL_TYPES, (i) => i), key: (i) => '$FUEL_TYPE$i', value: (i) => fuelTypes.length > i ? fuelTypes[i].type : null))
  ..addAll(Map<String, Object>.fromIterable(List<int>.generate(MAX_FUEL_TYPES, (i) => i), key: (i) => '$FUEL_UNIT$i', value: (i) => fuelTypes.length > i ? fuelTypes[i].unit : null));

  Car();

  Car.deserialize(Map<String, dynamic> json) : id = json[ID], brand = nullify(json[BRAND]), model = nullify(json[MODEL]), name = json[NAME], 
    distanceUnit = Distance.fromString(json[DISTANCE_UNIT]),
    initialMileage = json[INITIAL_MILEAGE].round(), 
    fuelTypes = List<FuelTypeAndUnit>.generate(MAX_FUEL_TYPES, (i) => FuelTypeAndUnit(json['$FUEL_TYPE$i'], json['$FUEL_UNIT$i']))..removeWhere((item) => item.type == null || item.unit == null);

  void sanitize() {
    fuelTypes.removeWhere((item) => item.type == null || item.unit == null);
  }


  String get brandAndModel {
    return brand == null ? model : model == null ? brand : '$brand $model';
  }
}