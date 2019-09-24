import 'package:flutter/foundation.dart';
import './fuel_unit.dart';
import '../utils/common.dart';



 
class Refueling {
  //keys:
  static const PRICE_PER_UNIT = 'pricePerUnit';
  static const QUANTITY = 'quantity';
  static const UNIT_TYPE = 'unitType';
  static const MILEAGE = 'mileage';
  static const TIMESTAMP = 'timestamp';
  static const FUEL_ID = 'fuelId';
  static const EXCHANGE_RATE = 'exchangeRate';
  static const NOTE = 'note';
  static const CAR_ID = 'carId';

  double pricePerUnit;
  double quantity; //in SI unit of a given UnitType
  UnitType unitType;
  int mileage; //in meters
  DateTime timestamp;
  int fuelId;
  double exchangeRate;
  String note;
  int carId;

  Refueling(
      {@required this.carId,
      this.exchangeRate = 1.0,
      @required this.fuelId,
      this.mileage,
      this.note = '',
      this.pricePerUnit,
      this.quantity,
      this.timestamp,
      @required this.unitType});

  Refueling.deserialize(Map<String, Object> json)
      : carId = json[CAR_ID],
        exchangeRate = json[EXCHANGE_RATE],
        fuelId = json[FUEL_ID],
        mileage = json[MILEAGE],
        note = json[NOTE],
        pricePerUnit = json[PRICE_PER_UNIT],
        quantity = json[QUANTITY],
        timestamp = DateTime.fromMillisecondsSinceEpoch(json[TIMESTAMP]),
        unitType = unitTypeFromString(json[UNIT_TYPE]);

  Map<String, Object> serialize() => {
    CAR_ID: carId,
    EXCHANGE_RATE: exchangeRate,
    FUEL_ID: fuelId,
    MILEAGE: mileage,
    NOTE: note,
    PRICE_PER_UNIT: pricePerUnit,
    QUANTITY: quantity,
    TIMESTAMP: serializedTimestamp,
    UNIT_TYPE: unitType.toString()
  };

  int get serializedTimestamp {
    return timestamp.millisecondsSinceEpoch;
  }

  double get unitConversionFactor {
    return 1000;
  }

  void setMileage(String value) {
    final nativeMileage = toDouble(value);
    mileage = nativeMileage == null ? null : (nativeMileage * unitConversionFactor).round();
  }
  
  double get displayedMileage {
    return mileage == null ? null : (mileage / unitConversionFactor);
  }

  String get mileageUnitString {
    return "km";
  }

  String get totalMileageString {
    return "${(displayedMileage).toStringAsFixed(1)} $mileageUnitString";
  }

  double get privePerUnitInHomeCurrency {
    return pricePerUnit * exchangeRate;
  }

  double get totalPriceInHomeCurrenct {
    return pricePerUnit * quantity * exchangeRate;
  }

  String get quantityUnitStringId {
    return 'litreSymbol';
  }
}
