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

class RefuelingAdapter {
  final Localization _loc;
  Refueling _refueling;
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
        _refueling = refueling ?? Refueling(carId: 1, timestamp: DateTime.now()) {//TODO get the right id
    _car = _cars.get(_refueling.carId);
    _fetchFuelInfo();
    _sanitizeFuelInfo();
  }

  void set({int carId,
    double exchangeRate,
    int fuelTypeId,
    int fuelUnitId,
    int tripMileage,
    String note,
    double pricePerUnit,
    double quantity,
    DateTime timestamp}) {
      _refueling = _refueling.copyWith(carId: carId, exchangeRate: exchangeRate, fuelTypeId: fuelTypeId, fuelUnitId: fuelUnitId, tripMileage: tripMileage, note: note, pricePerUnit: pricePerUnit, quantity: quantity, timestamp: timestamp);
      if (carId != null) { _car = _cars.get(_refueling.carId); }
      if (fuelTypeId != null) { _fuelType = _fuelTypes.get(_refueling.fuelTypeId); }
      if (fuelUnitId != null) { _fuelUnit = _fuelUnits.get(_refueling.fuelUnitId); }
    }

  void nullify({bool exchangeRate, bool tripMileage, bool pricePerUnit, bool quantity}) {
    _refueling = Refueling.nullify(_refueling, exchangeRate: exchangeRate, tripMileage: tripMileage, pricePerUnit: pricePerUnit, quantity: quantity);
  }


  bool isFuelTypeValid() => _carFuelIndex >= 0;
  bool isFuelUnitValid() => _fuelUnit != null && _fuelType?.unitType == _fuelUnit?.unitType;

  void _sanitizeFuelInfo() {
    if (!isFuelTypeValid()) {
      set(fuelTypeId: _car.fuelTypes[0].type, fuelUnitId: _car.fuelTypes[0].unit);
    } else if (!isFuelUnitValid()) {
      set(fuelUnitId: _car.fuelTypes[_carFuelIndex].unit);
    }
  }

  void _fetchFuelInfo() {
    _fuelType = _fuelTypes.get(_refueling.fuelTypeId);
    _fuelUnit = _fuelUnits.get(_refueling.fuelUnitId);
  }

  void setFuelType(int id) {
    final fuelIdx = _getFuelIndex(id);
    final idx = fuelIdx < 0 ? 0 : fuelIdx;
    set(fuelTypeId: _car.fuelTypes[idx].type, fuelUnitId: _car.fuelTypes[idx].unit);
  }

  void setTripMileage(double value) {
    final tripMileage = value == null ? null : _car.distanceUnit.toSi(value).round();
    tripMileage == null ? nullify(tripMileage: true) : set(tripMileage: tripMileage);
  }
  void setTotalMileage(double value, {@required int prevMileage}) {
    _refueling.totalMileage = _car.distanceUnit.toSi(value)?.round();
    _refueling.totalMileage == null ? nullify(tripMileage: true) : set(tripMileage: _refueling.totalMileage - prevMileage);
  }
  set pricePerUnit(double ppu) => ppu == null ? nullify(pricePerUnit: true) : set(pricePerUnit: ppu);
  set quantity(double quantity) => quantity == null ? nullify(quantity: true) : set(quantity: quantity);
  double displayedDistance(int distance) => distance == null ? null : _car?.distanceUnit?.toUnit(distance.toDouble());
  double get displayedTripMileage => displayedDistance(_refueling.tripMileage);
  double get displayedTotalMileage => displayedDistance(_refueling.totalMileage);
  int _getFuelIndex(int fuelId) => _car.fuelTypes.indexWhere((i) => i.type == fuelId);
  int get _carFuelIndex => _getFuelIndex(_refueling.fuelTypeId);
  Refueling get() => _refueling;
  String get mileageUnitString => _loc.ttr(_car.distanceUnit?.abbreviated());
  String get totalMileageString => "${displayedTotalMileage.toStringAsFixed(0)} $mileageUnitString"; 
  double get pricePerUnitInHomeCurrency => _refueling.pricePerUnit * _refueling.exchangeRate;
  double get totalPriceInHomeCurrency => pricePerUnitInHomeCurrency * _refueling.quantity;
  String get quantityUnitStringId => _fuelUnit.name;
  FuelType get fuelType => _fuelType;
  FuelUnit get fuelUnit => _fuelUnit;
  List<FuelType> get fuelTypes => _car.fuelTypes.map((i) => _fuelTypes.get(i.type)).toList();
  List<FuelUnit> get fuelUnits => _fuelUnits.where(_fuelUnit.unitType).toList();
  int get carInitialMileage => _car.initialMileage;
  int getCarInitialMileage(int carId) => _cars.get(carId).initialMileage;

}
