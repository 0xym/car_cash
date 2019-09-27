import 'dart:math';

import 'package:flutter/material.dart';
import '../model/car.dart';
import '../utils/db_access.dart';

class Cars extends ChangeNotifier {
  static const TABLE_NAME = 'cars';
  static bool _dbCreationSubscribed = false;
  int _maxCarIndex = 0;

  Cars() {
    if (!_dbCreationSubscribed) {
      _dbCreationSubscribed = true;
      DbAccess.addOnCreateCommand('CREATE TABLE $TABLE_NAME${Car.dbLayout}');
    }
  }


  Map<int, Car> _items;

  Car get(int id) => _items.containsKey(id) ? _items[id] : null;

  Iterable<int> get keys {
    return _items.keys;
  }

  Map<int, int> get initialMileages => _items.map((_, car) => MapEntry<int, int>(car.id, car.initialMileage));

  Future<void> fetchCars() async {
    if (_items != null) {
      return;
    }
    final dataList = await DbAccess.getData(TABLE_NAME);
    _items = dataList.asMap().map((k, v) {final car = Car.deserialize(v); _maxCarIndex = max(_maxCarIndex, car.id); return MapEntry(car.id, car);});//TODO - add error handling
  }

  Future<void> addCar(Car car) async {
    final updateDb = _items.containsKey(car.id);
    if (car.id == null) {
      car = car.copyWith(id: ++_maxCarIndex);
    }
    //if (updateDb && _items[car.id].initialMileage != car.initialMileage) { recalculate totals }
    _items[car.id] = car;
    notifyListeners();
    if (updateDb) {
      DbAccess.update(TABLE_NAME, car.serialize(), Car.ID, car.id);
    } else {
      DbAccess.insert(TABLE_NAME, car.serialize());
    }
  }

  Future<void> delete(int id) async {
    if (id == null) {
      return;
    }
    _items.remove(id);
    notifyListeners();
    DbAccess.delete(TABLE_NAME, Car.ID, id);
  }

}