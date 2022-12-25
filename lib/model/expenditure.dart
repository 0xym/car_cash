import '../utils/db_names.dart';

enum ExpenditureType {
  Refueling,
  OtherExpenditure,
}

enum DiscountType {
  none,
  percent,
  amount,
  pricePerUnit,
}

enum CostType {
  timDependent,
  distanceDependent,
}

enum ExpenditureDbKeys {//r == refueling
  timestamp('$INT $PRIMARY_KEY'),
  carId(INT),
  exchangeRate(REAL),
  pricePerUnit(REAL),
  quantity(REAL),
  fuelUnitId(INT),//r
  fuelTypeId(INT),//r
  mileage(REAL),//or rename to tripMileage
  currency(TEXT),
  discountType(INT),
  discountValue(REAL),
  costType(INT),//!r
  note(TEXT),
  expenditureType(INT),
  fillLevel(REAL),//r
  ;
  final String _dbProps;

  const ExpenditureDbKeys(this._dbProps);

  String get _dbInfo => '${this.name} $_dbProps';

  static String get dbLayout => ExpenditureDbKeys.values.map((e) => e._dbInfo).join(', ');
}

class Expenditure {
  final double? pricePerUnit;
  final double? quantity; //in SI unit of a given UnitType
  final int? tripMileage; //in meters
  int? totalMileage;
  final DateTime? timestamp;
  final int? fuelTypeId;
  final int? fuelUnitId;
  final double? exchangeRate;
  final String note;
  final String currency;
  final int? carId;
  final ExpenditureType expenditureType;
  final DiscountType discountType;
  final double? discountValue;
  final CostType costType;
  final double? fillLevel;

  double? get totalPrice => (pricePerUnit == null || quantity == null)
      ? null
      : quantity! * pricePerUnit!;

  static String get dbLayout => '(${ExpenditureDbKeys.dbLayout})';

  Expenditure(
      {this.carId = -1,
      this.exchangeRate = 1.0,
      this.fuelTypeId,
      this.totalMileage,
      this.tripMileage,
      this.note = '',
      this.currency = '',
      this.pricePerUnit,
      this.quantity,
      this.timestamp,
      this.fuelUnitId,
      this.expenditureType = ExpenditureType.Refueling,
      this.discountType = DiscountType.none,
      this.discountValue,
      this.costType = CostType.distanceDependent,
      this.fillLevel});

  Expenditure.copy(Expenditure other,
      {int? carId,
      double? exchangeRate,
      int? fuelTypeId,
      int? fuelUnitId,
      int? tripMileage,
      String? note,
      String? currency,
      double? pricePerUnit,
      double? quantity,
      DateTime? timestamp,
      ExpenditureType? expenditureType,
      DiscountType? discountType,
      double? discountValue,
      CostType? costType,
      double? fillLevel})
      : this.carId = carId ?? other.carId,
        this.exchangeRate = exchangeRate ?? other.exchangeRate,
        this.fuelTypeId = fuelTypeId ?? other.fuelTypeId,
        this.fuelUnitId = fuelUnitId ?? other.fuelUnitId,
        this.tripMileage = tripMileage ?? other.tripMileage,
        this.note = note ?? other.note,
        this.currency = currency ?? other.currency,
        this.pricePerUnit = pricePerUnit ?? other.pricePerUnit,
        this.quantity = quantity ?? other.quantity,
        this.timestamp = timestamp ?? other.timestamp,
        this.expenditureType = expenditureType ?? other.expenditureType,
        this.discountType = discountType ?? other.discountType,
        this.discountValue = discountValue ?? other.discountValue,
        this.costType = costType ?? other.costType,
        this.totalMileage = other.totalMileage,
        this.fillLevel = fillLevel ?? other.fillLevel;

  Expenditure.nullify(Expenditure other,
      {bool? carId,
      bool? exchangeRate,
      bool? fuelTypeId,
      bool? fuelUnitId,
      bool? tripMileage,
      bool? pricePerUnit,
      bool? quantity,
      bool? timestamp,
      bool? discountValue,
      bool? fillLevel})
      : this.carId = carId == true ? null : other.carId,
        this.exchangeRate = exchangeRate == true ? null : other.exchangeRate,
        this.fuelTypeId = fuelTypeId == true ? null : other.fuelTypeId,
        this.fuelUnitId = fuelUnitId == true ? null : other.fuelUnitId,
        this.tripMileage = tripMileage == true ? null : other.tripMileage,
        this.note = other.note,
        this.currency = other.currency,
        this.pricePerUnit = pricePerUnit == true ? null : other.pricePerUnit,
        this.quantity = quantity == true ? null : other.quantity,
        this.timestamp = timestamp == true ? null : other.timestamp,
        this.expenditureType = other.expenditureType,
        this.discountType = other.discountType,
        this.discountValue = discountValue == true ? null : other.discountValue,
        this.costType = other.costType,
        this.totalMileage = other.totalMileage,
        this.fillLevel = fillLevel == true ? null : other.fillLevel;

  Expenditure copyWith(
      {int? carId,
      double? exchangeRate,
      int? fuelTypeId,
      int? fuelUnitId,
      int? tripMileage,
      String? note,
      String? currency,
      double? pricePerUnit,
      double? quantity,
      DateTime? timestamp,
      ExpenditureType? expenditureType,
      DiscountType? discountType,
      double? discountValue,
      CostType? costType,
      double? fillLevel}) {
    return Expenditure.copy(this,
        carId: carId,
        exchangeRate: exchangeRate,
        fuelTypeId: fuelTypeId,
        fuelUnitId: fuelUnitId,
        tripMileage: tripMileage,
        note: note,
        currency: currency,
        pricePerUnit: pricePerUnit,
        quantity: quantity,
        timestamp: timestamp,
        expenditureType: expenditureType,
        discountType: discountType,
        discountValue: discountValue,
        costType: costType,
        fillLevel: fillLevel);
  }

  Expenditure.deserialize(Map<String, dynamic> json)
      : carId = json[ExpenditureDbKeys.carId.name],
        exchangeRate = json[ExpenditureDbKeys.exchangeRate.name],
        fuelTypeId = json[ExpenditureDbKeys.fuelTypeId.name],
        tripMileage = json[ExpenditureDbKeys.mileage.name],
        note = json[ExpenditureDbKeys.note.name],
        currency = json[ExpenditureDbKeys.currency.name],
        pricePerUnit = json[ExpenditureDbKeys.pricePerUnit.name],
        quantity = json[ExpenditureDbKeys.quantity.name],
        timestamp = DateTime.fromMillisecondsSinceEpoch(json[ExpenditureDbKeys.timestamp.name]),
        fuelUnitId = json[ExpenditureDbKeys.fuelUnitId.name],
        expenditureType = ExpenditureType.values[json[ExpenditureDbKeys.expenditureType.name]],
        discountType = DiscountType.values[json[ExpenditureDbKeys.discountType.name]],
        discountValue = json[ExpenditureDbKeys.discountValue.name],
        costType = CostType.values[json[ExpenditureDbKeys.costType.name]],
        fillLevel = json[ExpenditureDbKeys.fillLevel.name];

  Map<String, Object?> serialize() => {
        ExpenditureDbKeys.carId.name: carId,
        ExpenditureDbKeys.exchangeRate.name: exchangeRate,
        ExpenditureDbKeys.fuelTypeId.name: fuelTypeId,
        ExpenditureDbKeys.mileage.name: tripMileage,
        ExpenditureDbKeys.note.name: note,
        ExpenditureDbKeys.currency.name: currency,
        ExpenditureDbKeys.pricePerUnit.name: pricePerUnit,
        ExpenditureDbKeys.quantity.name: quantity,
        ExpenditureDbKeys.timestamp.name: serializedTimestamp,
        ExpenditureDbKeys.fuelUnitId.name: fuelUnitId,
        ExpenditureDbKeys.expenditureType.name : expenditureType.index,
        ExpenditureDbKeys.discountType.name : discountType.index,
        ExpenditureDbKeys.discountValue.name : discountValue,
        ExpenditureDbKeys.costType.name : costType.index,
        ExpenditureDbKeys.fillLevel.name : fillLevel,
      };

  static int? serializeTimestamp(DateTime? time) {
    return time?.millisecondsSinceEpoch;
  }

  int? get serializedTimestamp {
    return serializeTimestamp(timestamp);
  }
}
