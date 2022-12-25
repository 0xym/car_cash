import 'package:carsh/providers/refuelings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/localization.dart';
import '../providers/cars.dart';
import '../providers/fuel_units.dart';
import '../providers/fuel_types.dart';
import '../model/car.dart';
import '../model/fuel_type.dart';
import '../model/fuel_unit.dart';
import '../model/preferences.dart';
import '../model/expenditure.dart';

enum PriceSet { Quantity, PricePerUnit, TotalPrice, None }

enum MileageType { Trip, Total }

class RefuelingAdapter {
  // final _prefs = Preferences();
  final Localization _loc;
  Expenditure _refueling;
  final Cars _cars;
  final FuelUnits _fuelUnits;
  final FuelTypes _fuelTypes;
  Car? _car;
  FuelUnit? _fuelUnit;
  FuelType? _fuelType;
  double? _totalPrice;
  PriceSet? _autoSet;
  PriceSet? _lastSet;
  PriceSet? _remainingSet;

  RefuelingAdapter(BuildContext context, Expenditure? refueling)
      : _loc = Localization.of(context),
        _cars = Provider.of(context, listen: false),
        _fuelTypes = Provider.of(context, listen: false),
        _fuelUnits = Provider.of(context, listen: false),
        _refueling = refueling ??
            Expenditure(
                carId: Preferences().get(DEFAULT_CAR),
                timestamp: DateTime.now(),
                expenditureType: ExpenditureType.Refueling) {
    if (refueling?.totalPrice != null) {
      _totalPrice = refueling!.totalPrice;
      //TODO - move it to settings
      _autoSet = PriceSet.TotalPrice;
      _remainingSet = PriceSet.Quantity;
      _lastSet = PriceSet.PricePerUnit;
    }
    _car = _cars.get(_refueling.carId);
    _fetchFuelInfo();
    _sanitizeFuelInfo();
  }

  void set(
      {int? carId,
      double? exchangeRate,
      int? fuelTypeId,
      int? fuelUnitId,
      int? tripMileage,
      String? note,
      double? pricePerUnit,
      double? quantity,
      DateTime? timestamp}) {
    _refueling = _refueling.copyWith(
        carId: carId,
        exchangeRate: exchangeRate,
        fuelTypeId: fuelTypeId,
        fuelUnitId: fuelUnitId,
        tripMileage: tripMileage,
        note: note,
        pricePerUnit: pricePerUnit,
        quantity: quantity,
        timestamp: timestamp);
    if (carId != null) {
      _car = _cars.get(carId);
    }
    if (fuelTypeId != null) {
      _fuelType = _fuelTypes.get(fuelTypeId);
    }
    if (fuelUnitId != null) {
      _fuelUnit = _fuelUnits.get(fuelUnitId);
    }
  }

  void nullify(
      {bool? exchangeRate,
      bool? tripMileage,
      bool? pricePerUnit,
      bool? quantity}) {
    _refueling = Expenditure.nullify(_refueling,
        exchangeRate: exchangeRate,
        tripMileage: tripMileage,
        pricePerUnit: pricePerUnit,
        quantity: quantity);
  }

  bool isFuelTypeValid() => _carFuelIndex >= 0;
  bool isFuelUnitValid() =>
      _fuelUnit != null && _fuelType?.unitType == _fuelUnit?.unitType;

  void _sanitizeFuelInfo() {
    if (!isFuelTypeValid()) {
      set(
          fuelTypeId: _car?.fuelTanks[0].type,
          fuelUnitId: _car?.fuelTanks[0].unit);
    } else if (!isFuelUnitValid()) {
      set(fuelUnitId: _car?.fuelTanks[_carFuelIndex].unit);
    }
  }

  void _fetchFuelInfo() {
    _fuelType = _fuelTypes.get(_refueling.fuelTypeId);
    _fuelUnit = _fuelUnits.get(_refueling.fuelUnitId);
  }

  void setFuelType(int? id) {
    final fuelIdx = _getFuelIndex(id);
    final idx = fuelIdx < 0 ? 0 : fuelIdx;
    set(
        fuelTypeId: _car?.fuelTanks[idx].type,
        fuelUnitId: _car?.fuelTanks[idx].unit);
  }

  void setTripMileage(double? value) {
    final tripMileage =
        value == null ? null : _car?.distanceUnit?.toSi(value)?.round();
    tripMileage == null
        ? nullify(tripMileage: true)
        : set(tripMileage: tripMileage);
  }

  void setTotalMileage(double? value, {required int prevMileage}) {
    _refueling.totalMileage = _car?.distanceUnit?.toSi(value)?.round();
    _refueling.totalMileage == null
        ? nullify(tripMileage: true)
        : set(tripMileage: _refueling.totalMileage! - prevMileage);
  }

  void _updateLastSet(PriceSet? lastSet) {
    if (lastSet == null || lastSet == _lastSet) {
      return;
    }
    if (lastSet == _autoSet) {
      _autoSet = _remainingSet;
      _remainingSet = _lastSet;
      _lastSet = lastSet;
    } else if (_lastSet == null) {
      _lastSet = lastSet;
    } else if (_remainingSet == null) {
      _remainingSet = _lastSet;
      _lastSet = lastSet;
      _autoSet = PriceSet.values
          .firstWhere((x) => x != _remainingSet && x != _lastSet);
    } else {
      _remainingSet = _lastSet;
      _lastSet = lastSet;
    }
  }

  void _removeLastSet(PriceSet? lastUnset) {
    if (lastUnset == _autoSet || lastUnset == null) {
      return;
    }
    if (_refueling.quantity == null &&
        _refueling.pricePerUnit == null &&
        _totalPrice == null) {
      _lastSet = null;
      _autoSet = null;
      _remainingSet = null;
      return;
    }
    if (lastUnset == _lastSet) {
      _lastSet = _remainingSet;
      _remainingSet = _autoSet;
      _autoSet = lastUnset;
    }
    if (lastUnset == _remainingSet) {
      _remainingSet = _autoSet;
      _autoSet = lastUnset;
    }
  }

  PriceSet setPricePerUnit(double? ppu) {
    if (ppu == null) {
      _removeLastSet(PriceSet.PricePerUnit);
      nullify(pricePerUnit: true);
      return PriceSet.None;
    } else {
      set(pricePerUnit: ppu);
      _updateLastSet(PriceSet.PricePerUnit);
      return _recalculateAutoSet();
    }
  }

  PriceSet setQuantity(double? quantity) {
    if (quantity == null) {
      _removeLastSet(PriceSet.Quantity);
      nullify(quantity: true);
      return PriceSet.None;
    } else {
      set(quantity: quantity);
      _updateLastSet(PriceSet.Quantity);
      return _recalculateAutoSet();
    }
  }

  PriceSet setTotalPrice(double? total) {
    _totalPrice = total;
    if (total == null) {
      _removeLastSet(PriceSet.TotalPrice);
      return PriceSet.None;
    }
    _updateLastSet(PriceSet.TotalPrice);
    return _recalculateAutoSet();
  }

  PriceSet _recalculateAutoSet() {
    switch (_autoSet) {
      case null:
        break;
      case PriceSet.PricePerUnit:
        if (_totalPrice != null && _refueling.quantity != null) {
          set(pricePerUnit: _totalPrice! / _refueling.quantity!);
          return _autoSet!;
        }
        break;
      case PriceSet.Quantity:
        if (_totalPrice != null && _refueling.pricePerUnit != null) {
          set(quantity: _totalPrice! / _refueling.pricePerUnit!);
          return _autoSet!;
        }
        break;
      case PriceSet.TotalPrice:
        _totalPrice = _refueling.totalPrice;
        return _autoSet!;
      case PriceSet.None:
        break;
    }
    return PriceSet.None;
  }

  double? priceSetValue(PriceSet? priceSet) {
    switch (priceSet) {
      case PriceSet.PricePerUnit:
        return _refueling.pricePerUnit;
      case PriceSet.Quantity:
        return _refueling.quantity;
      case PriceSet.TotalPrice:
        return _totalPrice;
      case PriceSet.None:
        break;
      case null:
        break;
    }
    return null;
  }

//TODO - continue moving here (better use member functions)
  void updateTimestamp(DateTime timestamp, Refuelings refuelings,
      MileageType mileageType, int? oldRefuelingTripMileage) {
    if (timestamp.isAtSameMomentAs(get().timestamp!)) {
      return;
    }
    //TODO handling should be related to trip distance text input controller
    final oldPrev = refuelings.previousRefuelingIndexOfCar(get());
    set(timestamp: timestamp);
    // return;
    final prev = refuelings.previousRefuelingIndexOfCar(get());
    if (mileageType == MileageType.Total) {
      set(
          tripMileage: get().totalMileage! -
              (refuelings.itemAtIndex(prev)?.totalMileage ??
                  car!.initialMileage!));
    } else {
      final toFuture =
          refuelings.isMovedToFuture(prevIdx: oldPrev, nextIdx: prev);
      get().totalMileage =
          (refuelings.itemAtIndex(prev)?.totalMileage ?? car!.initialMileage!) +
              get().tripMileage! -
              (toFuture ? oldRefuelingTripMileage ?? 0 : 0);
    }
  }

  double? displayedDistance(int? distance) =>
      distance == null ? null : _car?.distanceUnit?.toUnit(distance.toDouble());
  double? get displayedTripMileage => displayedDistance(_refueling.tripMileage);
  double? get displayedTotalMileage =>
      displayedDistance(_refueling.totalMileage);
  int _getFuelIndex(int? fuelId) =>
      _car!.fuelTanks.indexWhere((i) => i.type == fuelId);
  int get _carFuelIndex => _getFuelIndex(_refueling.fuelTypeId);
  Expenditure get() => _refueling;
  String get mileageUnitString => _loc.ttr(_car?.distanceUnit?.abbreviated());
  double get pricePerUnitInHomeCurrency =>
      _refueling.pricePerUnit! * _refueling.exchangeRate!;
  double get totalPriceInHomeCurrency =>
      pricePerUnitInHomeCurrency * _refueling.quantity!;
  String? get quantityUnitStringId => _fuelUnit?.name;
  String? get quantityUnitAbbrStringId => _fuelUnit?.nameAbbreviated;
  FuelType? get fuelType => _fuelType;
  FuelUnit? get fuelUnit => _fuelUnit;
  List<FuelType?>? get fuelTypes =>
      _car?.fuelTanks.map((i) => _fuelTypes.get(i.type)).toList();
  List<FuelUnit> get fuelUnits =>
      _fuelUnits.where(_fuelUnit!.unitType).toList();
  int? getCarInitialMileage(int? carId) => _cars.get(carId)?.initialMileage;
  Car? get car => _car;
}
