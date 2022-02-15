import 'dart:math';

import 'package:flutter/material.dart';
import '../model/car.dart';
import '../model/preferences.dart';
import '../utils/db_access.dart';

class Cars extends ChangeNotifier {
  static const TABLE_NAME = 'cars';
  static bool _dbCreationSubscribed = false;
  int _maxCarIndex = 0;
  final _prefs = Preferences();

  Cars() {
    if (!_dbCreationSubscribed) {
      _dbCreationSubscribed = true;
      DbAccess.addOnCreateCommand('CREATE TABLE $TABLE_NAME${Car.dbLayout}');
    }
  }

  Map<int, Car>? _items;

  Iterable<Car>? get cars => _items?.values;

  Car? get(int? id) => _items?.containsKey(id) ?? false ? _items![id] : null;

  Iterable<int>? get keys => _items?.keys;

  Map<int?, int?> get initialMileages =>
      _items!.map((_, car) => MapEntry<int?, int?>(car.id, car.initialMileage));

  Future<void> fetchCars() async {
    if (_items != null) {
      return;
    }
    final dataList = await DbAccess.getData(TABLE_NAME);
    _items = dataList.asMap().map((k, v) {
      final car = Car.deserialize(v);
      _maxCarIndex = max(_maxCarIndex, car.id!);
      return MapEntry(car.id!, car);
    }); //TODO - add error handling
  }

  Future<void> addCar(Car car) async {
    final updateDb = _items!.containsKey(car.id);
    if (car.id == null) {
      car = car.copyWith(id: ++_maxCarIndex);
    }
    //if (updateDb && _items[car.id].initialMileage != car.initialMileage) { recalculate totals }
    _items![car.id!] = car;
    if (_items!.length == 1) {
      _prefs.set(DEFAULT_CAR, car.id);
    }
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
    _items!.remove(id);
    if (id == _prefs.get(DEFAULT_CAR)) {
      _prefs.set(DEFAULT_CAR, _items!.length == 1 ? _items![0]!.id : -1);
    }
    notifyListeners();
    DbAccess.delete(TABLE_NAME, Car.ID, id);
  }
}
