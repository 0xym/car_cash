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


  Map<int, Car> _items;//consider using list and keep deleted items as nulls

  Car get(int id) {
    return _items[id];
  }

  Iterable<int> get keys {
    return _items.keys;
  }

  Future<void> fetchCars() async {
    if (_items != null) {
      return;
    }
    final dataList = await DbAccess.getData(TABLE_NAME);
    _items = dataList.asMap().map((k, v) {final car = Car.deserialize(v); _maxCarIndex = max(_maxCarIndex, car.id); return MapEntry(car.id, car);});
  }

  Future<void> addCar(Car car) async {
    final updateDb = _items.containsKey(car.id);
    if (car.id == null) {
      car.id = ++_maxCarIndex;
    }
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