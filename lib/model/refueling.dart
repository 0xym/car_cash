import 'package:flutter/foundation.dart';
import '../utils/db_names.dart';

class Refueling {
  //keys:
  static const PRICE_PER_UNIT = 'pricePerUnit';
  static const QUANTITY = 'quantity';
  static const FUEL_UNIT_ID = 'fuelUnitId';
  static const MILEAGE = 'mileage';
  static const TIMESTAMP = 'timestamp';
  static const FUEL_TYPE_ID = 'fuelTypeId';
  static const EXCHANGE_RATE = 'exchangeRate';
  static const NOTE = 'note';
  static const CAR_ID = 'carId';

  double pricePerUnit;
  double quantity; //in SI unit of a given UnitType
  int mileage; //in meters
  DateTime timestamp;
  int fuelTypeId;
  int fuelUnitId;
  double exchangeRate;
  String note;
  int carId;

  static String get dbLayout {
    return '($TIMESTAMP $INT $PRIMARY_KEY, $CAR_ID $INT, $EXCHANGE_RATE $REAL, $FUEL_TYPE_ID $INT, $MILEAGE $INT, $NOTE $TEXT, $PRICE_PER_UNIT $REAL, $QUANTITY REAL, $FUEL_UNIT_ID INT)';
  }

  Refueling(
      {@required this.carId,
      this.exchangeRate = 1.0,
      this.fuelTypeId,
      this.mileage,
      this.note = '',
      this.pricePerUnit,
      this.quantity,
      this.timestamp,
      this.fuelUnitId
      });

  Refueling.deserialize(Map<String, Object> json)
      : carId = json[CAR_ID],
        exchangeRate = json[EXCHANGE_RATE],
        fuelTypeId = json[FUEL_TYPE_ID],
        mileage = json[MILEAGE],
        note = json[NOTE],
        pricePerUnit = json[PRICE_PER_UNIT],
        quantity = json[QUANTITY],
        timestamp = DateTime.fromMillisecondsSinceEpoch(json[TIMESTAMP]),
        fuelUnitId = json[FUEL_UNIT_ID];

  Map<String, Object> serialize() => {
    CAR_ID: carId,
    EXCHANGE_RATE: exchangeRate,
    FUEL_TYPE_ID: fuelTypeId,
    MILEAGE: mileage,
    NOTE: note,
    PRICE_PER_UNIT: pricePerUnit,
    QUANTITY: quantity,
    TIMESTAMP: serializedTimestamp,
    FUEL_UNIT_ID: fuelUnitId
  };

  static int serializeTimestamp(DateTime time) {
    return time.millisecondsSinceEpoch;
  }

  int get serializedTimestamp {
    return serializeTimestamp(timestamp);
  }
}
