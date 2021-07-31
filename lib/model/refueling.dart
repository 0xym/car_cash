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
  static const CURRENCY = 'currency';
  static const DISCOUNT = 'discount';
  static const DISCOUNT_TYPE = 'discount_type';
  //shouldn't costType be moved to the expenditure?
  static const COST_TYPE = 'cost_type'; //timeDependent or distanceDependeent
  static const NOTE = 'note';
  static const CAR_ID = 'carId';

  final double pricePerUnit;
  final double quantity; //in SI unit of a given UnitType
  final int tripMileage; //in meters
  int totalMileage;
  final DateTime timestamp;
  final int fuelTypeId;
  final int fuelUnitId;
  final double exchangeRate;
  final String note;
  final int carId;

  double get totalPrice => (pricePerUnit == null || quantity == null)
      ? null
      : quantity * pricePerUnit;

  static String get dbLayout {
    return '($TIMESTAMP $INT $PRIMARY_KEY, $CAR_ID $INT, $EXCHANGE_RATE $REAL, $FUEL_TYPE_ID $INT, $MILEAGE $INT, $NOTE $TEXT, $PRICE_PER_UNIT $REAL, $QUANTITY REAL, $FUEL_UNIT_ID INT)';
  }

  Refueling(
      {this.carId = -1,
      this.exchangeRate = 1.0,
      this.fuelTypeId,
      this.totalMileage,
      this.tripMileage,
      this.note = '',
      this.pricePerUnit,
      this.quantity,
      this.timestamp,
      this.fuelUnitId});

  Refueling.copy(Refueling other,
      {int carId,
      double exchangeRate,
      int fuelTypeId,
      int fuelUnitId,
      int tripMileage,
      String note,
      double pricePerUnit,
      double quantity,
      DateTime timestamp})
      : this.carId = carId ?? other.carId,
        this.exchangeRate = exchangeRate ?? other.exchangeRate,
        this.fuelTypeId = fuelTypeId ?? other.fuelTypeId,
        this.fuelUnitId = fuelUnitId ?? other.fuelUnitId,
        this.tripMileage = tripMileage ?? other.tripMileage,
        this.note = note ?? other.note,
        this.pricePerUnit = pricePerUnit ?? other.pricePerUnit,
        this.quantity = quantity ?? other.quantity,
        this.timestamp = timestamp ?? other.timestamp,
        this.totalMileage = other.totalMileage;

  Refueling.nullify(Refueling other,
      {bool carId,
      bool exchangeRate,
      bool fuelTypeId,
      bool fuelUnitId,
      bool tripMileage,
      bool note,
      bool pricePerUnit,
      bool quantity,
      bool timestamp})
      : this.carId = carId == true ? null : other.carId,
        this.exchangeRate = exchangeRate == true ? null : other.exchangeRate,
        this.fuelTypeId = fuelTypeId == true ? null : other.fuelTypeId,
        this.fuelUnitId = fuelUnitId == true ? null : other.fuelUnitId,
        this.tripMileage = tripMileage == true ? null : other.tripMileage,
        this.note = note == true ? null : other.note,
        this.pricePerUnit = pricePerUnit == true ? null : other.pricePerUnit,
        this.quantity = quantity == true ? null : other.quantity,
        this.timestamp = timestamp == true ? null : other.timestamp,
        this.totalMileage = other.totalMileage;

  Refueling copyWith(
      {int carId,
      double exchangeRate,
      int fuelTypeId,
      int fuelUnitId,
      int tripMileage,
      String note,
      double pricePerUnit,
      double quantity,
      DateTime timestamp}) {
    return Refueling.copy(this,
        carId: carId,
        exchangeRate: exchangeRate,
        fuelTypeId: fuelTypeId,
        fuelUnitId: fuelUnitId,
        tripMileage: tripMileage,
        note: note,
        pricePerUnit: pricePerUnit,
        quantity: quantity,
        timestamp: timestamp);
  }

  Refueling.deserialize(Map<String, Object> json)
      : carId = json[CAR_ID],
        exchangeRate = json[EXCHANGE_RATE],
        fuelTypeId = json[FUEL_TYPE_ID],
        tripMileage = json[MILEAGE],
        note = json[NOTE],
        pricePerUnit = json[PRICE_PER_UNIT],
        quantity = json[QUANTITY],
        timestamp = DateTime.fromMillisecondsSinceEpoch(json[TIMESTAMP]),
        fuelUnitId = json[FUEL_UNIT_ID];

  Map<String, Object> serialize() => {
        CAR_ID: carId,
        EXCHANGE_RATE: exchangeRate,
        FUEL_TYPE_ID: fuelTypeId,
        MILEAGE: tripMileage,
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
