import 'package:flutter/material.dart';
import '../model/fuel_unit.dart';
import '../utils/db_access.dart';

class FuelUnits extends ChangeNotifier {
  Map<int, FuelUnit> _items = {
    0: FuelUnit(0, 'liter', UnitType.Volume, 1.0),
    // 1: FuelUnit(1, 'dm3', UnitType.Volume, 1.0),
    2: FuelUnit(2, 'gallon_us', UnitType.Volume, 3.785411784),
    3: FuelUnit(3, 'gallon_uk', UnitType.Volume, 4.54609),
    4: FuelUnit(4, 'cubicMeter', UnitType.Volume, 1000),
    5: FuelUnit(5, 'kilogram', UnitType.Mass, 1.0),
    6: FuelUnit(6, 'kiloWattHour', UnitType.Energy, 3600*1000.0),

  };

  FuelUnit get(int id) {
    return _items[id];
  }

Iterable<int> get keys {
    return _items.keys;
  }

Iterable<int> keysWhere(UnitType type) {
  return _items.keys.where((i) => _items[i].unitType == type);
}

int firstWhere(UnitType type) {
  return _items.keys.firstWhere((i) => _items[i].unitType == type);
}


}