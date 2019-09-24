import 'package:flutter/material.dart';
import '../model/fuel_unit.dart';
import '../model/fuel_type.dart';
import '../utils/db_access.dart';

class FuelTypes extends ChangeNotifier {
  Map<int, FuelType> _items = {
    0: FuelType(0, 'petrol', UnitType.Volume),
    1: FuelType(1, 'diesel', UnitType.Volume),
    2: FuelType(2, 'LPG', UnitType.Volume),
    3: FuelType(3, 'CNG', UnitType.Volume),
    4: FuelType(4, 'hydrogen', UnitType.Mass),
    5: FuelType(5, 'electricity', UnitType.Energy),
  };

  FuelType get(int id) {
    return _items[id];
  }

  Iterable<int> get keys {
    return _items.keys;
  }

}