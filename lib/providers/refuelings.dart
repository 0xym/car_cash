import 'package:flutter/material.dart';
import '../model/refueling.dart';
import '../utils/db_access.dart';
import './cars.dart';

class SorroundingRefuelingData {
  int prevMileage;
  int nextMileage;
  int nextIndex;
  SorroundingRefuelingData(this.prevMileage, this.nextMileage, this.nextIndex);
}

class Refuelings extends ChangeNotifier {
  static const TABLE_NAME = 'refuelings';
  static bool _dbCreationSubscribed = false;

  final Cars _cars;
  List<Refueling> _items = [];
  Refuelings(this._cars) {
    if (!_dbCreationSubscribed) {
      _dbCreationSubscribed = true;
      DbAccess.addOnCreateCommand('CREATE TABLE $TABLE_NAME${Refueling.dbLayout}');
    }
  }

  Refueling _itemAtNotNull(int index) => index >= 0 && index < _items.length ? _items[index] : null;
  Refueling itemAtIndex(int index) => _itemAtNotNull(index ?? -1);
  int get itemCount => _items.length;
  Refueling lastOfCar(int id) => _items.firstWhere((i) => i.carId == id);
  Refueling previousOfCar(Refueling refueling) {
    var idx = _items.indexWhere((item) => item.timestamp.isAfter(refueling.timestamp));
    idx = idx == -1 ? -1 : _items.indexWhere((item) => item.carId == refueling.carId, idx);
    return itemAtIndex(idx);
  }
  SorroundingRefuelingData sorouningRefuelingData(Refueling refueling, int initial) {
    var prev = initial;
    int next = prev;
    for (var idx = _items.length - 1; idx >= 0; --idx) {
      if (_items[idx].carId == refueling.carId) {
        if (_items[idx].timestamp.isAfter(refueling.timestamp)) {
          return SorroundingRefuelingData(prev, next + _items[idx].mileage, idx);
        } else if (_items[idx].timestamp.isBefore(refueling.timestamp)) {
          prev += _items[idx].mileage;
          next = prev;
        } else {
          next += _items[idx].mileage;
        }
      }
    }
    return SorroundingRefuelingData(prev, null, null);
  }
  List<Refueling> sorouningRefuelingsOfCar(Refueling refueling) {
    var idx = _items.indexWhere((item) => item.timestamp.isBefore(refueling.timestamp));
    if (idx == -1) idx = _items.length;
    final previousIdx = _items.indexWhere((item) => item.carId == refueling.carId, idx);
    var backIdx = idx - 1;
    if (idx > 0 && _items[idx - 1].timestamp.isAtSameMomentAs(refueling.timestamp)) {
      --backIdx;
    }
    final nextIdx = backIdx < 0 ? -1 : _items.lastIndexWhere((item) => item.carId == refueling.carId, backIdx);
    return [itemAtIndex(previousIdx), itemAtIndex(nextIdx)];
  }

  Future<void> fetchRefuelings() async {
    if (_items != null) {
      return;
    }
    await _cars.fetchCars();
    final dataList = await DbAccess.getData(TABLE_NAME, orderBy: Refueling.TIMESTAMP);
    List<DateTime> toRemove = [];
    final checkRemove = (Refueling i) {
      if (_cars.keys.contains(i.carId)) {
        return false;
      }
      toRemove.add(i.timestamp);
      return true;
    };
    _items = (dataList.map((item) => Refueling.deserialize(item)).toList()..removeWhere(checkRemove)).reversed.toList();
    _deleteRefuelings(toRemove);
  }

  Future<void> _addRefueling(Refueling refueling) async {
    var idx = _items.indexWhere((item) => item.timestamp.isBefore(refueling.timestamp));
    if (idx == -1) idx = _items.length;
    print(idx);
    if (idx > 0 && _items[idx - 1].timestamp.isAtSameMomentAs(refueling.timestamp)) {
      _items[idx - 1] = refueling;
      DbAccess.update(TABLE_NAME, refueling.serialize(), Refueling.TIMESTAMP, refueling.serializedTimestamp);
    } else {
      _items.add(refueling);
      DbAccess.insert(TABLE_NAME, refueling.serialize());
    }
  }

  Future<void> clear() async {
    _items = [];
    notifyListeners();
    DbAccess.delete(TABLE_NAME, null, null);
  }

  Future<void> _deleteRefueling(DateTime timestamp) async {
    if (timestamp == null) {
      return;
    }
    _items.removeWhere((item) => item.timestamp == timestamp);
    DbAccess.delete(TABLE_NAME, Refueling.TIMESTAMP, Refueling.serializeTimestamp(timestamp));
  }

  Future<void> _deleteRefuelings(List<DateTime> timestamps) async {
    timestamps.forEach((t) => _deleteRefueling(t));
  }

  Future<void> deleteRefueling(DateTime timestamp) async {
    _deleteRefueling(timestamp);
    notifyListeners();
  }

  Future<void> changeRefueling(DateTime timestamp, Refueling refueling) async {
    if (refueling.timestamp != timestamp) {
      _deleteRefueling(timestamp);
    } 
    _addRefueling(refueling);
    notifyListeners();
  }

}