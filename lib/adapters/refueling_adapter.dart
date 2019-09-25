import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/localization.dart';
import '../providers/cars.dart';
import '../providers/fuel_units.dart';
import '../providers/fuel_types.dart';
import '../model/car.dart';
import '../model/fuel_type.dart';
import '../model/fuel_unit.dart';
import '../model/refueling.dart';
import '../utils/common.dart';

class RefuelingAdapter {
  final Localization _loc;
  final Refueling _refueling;
  final Cars _cars;
  final FuelUnits _fuelUnits;
  final FuelTypes _fuelTypes;
  Car _car;
  FuelUnit _fuelUnit;
  FuelType _fuelType;

  RefuelingAdapter(BuildContext context, Refueling refueling)
      : _loc = Localization.of(context),
        _cars = Provider.of(context, listen: false),
        _fuelTypes = Provider.of(context, listen: false),
        _fuelUnits = Provider.of(context, listen: false),
        _refueling = refueling ?? Refueling(carId: 1) {//todo get the right id
    _car = _cars.get(_refueling.carId);
    _initFuelType();
    _initFuelUnit();
  }

  bool isFuelTypeValid() {
    if (_refueling.fuelTypeId == null) {
      return false;
    }
    return _car.fuelTypes.indexWhere((i) => i.type == _refueling.fuelTypeId) >= 0;
  }

  bool isFuelUnitValid() {
    return _refueling.fuelUnitId != null && _fuelType.unitType == _fuelUnits.get(_refueling.fuelUnitId).unitType;
  }

  void _initFuelType() {
    if (!isFuelTypeValid()) {
      _refueling.fuelTypeId = _car.fuelTypes[0].type;
      _refueling.fuelUnitId = _car.fuelTypes[0].unit;
    }
      _fuelType = _fuelTypes.get(_refueling.fuelTypeId);
  }

  void _initFuelUnit() {
    if (!isFuelUnitValid()) {
      _refueling.fuelUnitId = _car.fuelTypes[0].unit;
    }
    _fuelUnit = _fuelUnits.get(_refueling.fuelUnitId);
  }


  Refueling get() {
    return _refueling;
  }

  void setMileage(String value) {
    final nativeMileage = toDouble(value);
    _refueling.mileage = nativeMileage == null
        ? null
        : _car.distanceUnit.toSi(nativeMileage).round();
  }

  double get displayedMileage {
    return _refueling.mileage == null
        ? null
        : _car.distanceUnit.toUnit(_refueling.mileage.toDouble());
  }

  String get mileageUnitString {
    return _loc.tr(_car.distanceUnit.toString());
  }

  String get totalMileageString {
    return "${(displayedMileage).toStringAsFixed(0)} $mileageUnitString";
  }

  double get pricePerUnitInHomeCurrency {
    return _refueling.pricePerUnit * _refueling.exchangeRate;
  }

  double get totalPriceInHomeCurrency {
    return pricePerUnitInHomeCurrency * _refueling.quantity;
  }

  String get quantityUnitStringId {
    return _fuelUnit.name;
  }

}
