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
        _refueling = refueling ?? Refueling(carId: 1) {//TODO get the right id
    _car = _cars.get(_refueling.carId);
    _sanitizeFuelInfo();
    _fetchFuelInfo();
  }

  bool isFuelTypeValid() {
    if (_refueling.fuelTypeId == null) {
      return false;
    }
    return _carFuelIndex >= 0;
  }

  bool isFuelUnitValid() {
    return _refueling.fuelUnitId != null && _fuelType.unitType == _fuelUnits.get(_refueling.fuelUnitId).unitType;
  }

  void _sanitizeFuelInfo() {
    if (!isFuelTypeValid()) {
      _refueling.fuelTypeId = _car.fuelTypes[0].type;
      _refueling.fuelUnitId = _car.fuelTypes[0].unit;
    } else if (!isFuelUnitValid()) {
      _refueling.fuelUnitId = _car.fuelTypes[0].unit;
    }
  }

  void _fetchFuelInfo() {
    _fuelType = _fuelTypes.get(_refueling.fuelTypeId);
    _fuelUnit = _fuelUnits.get(_refueling.fuelUnitId);
  }

  void setFuelType(int id) {
    _refueling.fuelTypeId = id;
    var idx = _carFuelIndex;
    if (idx < 0) {
      idx = 0;
      _refueling.fuelTypeId = _car.fuelTypes[idx].type;
    }
    _refueling.fuelUnitId = _car.fuelTypes[idx].unit;
    _fetchFuelInfo();
  }

  void setMileage(double value, {int previous}) {
    _refueling.mileage = value == null ? null : _car.distanceUnit.toSi(value).round() - previous??0;
  }
  void setStringMileage(String value) {setMileage(toDouble(value)); }
  double displayedDistance(int distance) => distance == null ? null : _car?.distanceUnit?.toUnit(distance.toDouble());
  double get displayedMileage => displayedDistance(_refueling.mileage);
  int get _carFuelIndex => _car.fuelTypes.indexWhere((i) => i.type == _refueling.fuelTypeId);
  Refueling get() => _refueling;
  String get mileageUnitString => _loc.ttr(_car.distanceUnit?.abbreviated());
  String get totalMileageString => "${(displayedMileage).toStringAsFixed(0)} $mileageUnitString"; 
  double get pricePerUnitInHomeCurrency => _refueling.pricePerUnit * _refueling.exchangeRate;
  double get totalPriceInHomeCurrency => pricePerUnitInHomeCurrency * _refueling.quantity;
  String get quantityUnitStringId => _fuelUnit.name;
  FuelType get fuelType => _fuelType;
  FuelUnit get fuelUnit => _fuelUnit;
  List<FuelType> get fuelTypes => _car.fuelTypes.map((i) => _fuelTypes.get(i.type)).toList();
  List<FuelUnit> get fuelUnits => _fuelUnits.where(_fuelUnit.unitType).toList();
  int get carInitialMileage => _car.initialMileage;

}
