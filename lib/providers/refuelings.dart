import 'package:car_cash/adapters/refueling_adapter.dart';
import 'package:car_cash/adapters/total_mileage_counter.dart';
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

  List<Refueling> _items;
  Refuelings() {
    if (!_dbCreationSubscribed) {
      _dbCreationSubscribed = true;
      DbAccess.addOnCreateCommand(
          'CREATE TABLE $TABLE_NAME${Refueling.dbLayout}');
    }
  }

  bool _isIndexValid(int index) =>
      index != null && index >= 0 && index < _items.length;
  bool isMovedToFuture({int prevIdx, int nextIdx}) => nextIdx < prevIdx;
  Refueling itemAtIndex(int index) =>
      _isIndexValid(index) ? _items[index] : null;
  int get itemCount => _items.length;
  // Refueling lastOfCar(int id) => _items.firstWhere((i) => i.carId == id);
  int _previousRefuelingIndex(Refueling refueling) {
    //TODO - use binary search
    final idx = _items
        .indexWhere((item) => item.timestamp.isBefore(refueling.timestamp));
    return idx == -1 ? _items.length : idx;
  }

  int previousRefuelingIndexOfCar(Refueling refueling) {
    final idx = _previousRefuelingIndex(refueling);
    return idx == _items.length
        ? -1
        : _items.indexWhere((item) => item.carId == refueling.carId, idx);
  }

  int _nextRefuelingIndex(Refueling refueling) =>
      _items.lastIndexWhere((item) => item.timestamp
          .isAfter(refueling.timestamp)); // TODO - use binary search
  int nextRefuelingIndexOfCar(Refueling refueling, {int hint}) {
    final idx = hint ?? _nextRefuelingIndex(refueling);
    final getNext = (int index) =>
        _items.lastIndexWhere((item) => item.carId == refueling.carId, index);
    final ret = getNext(idx);
    return ((ret != -1) &&
            (_items[ret].timestamp.isAtSameMomentAs(refueling.timestamp)))
        ? getNext(ret)
        : ret;
  }

  SorroundingRefuelingData sorouningRefuelingData(
      Refueling refueling, int initial) {
    var prev = initial;
    int next = prev;
    for (var idx = _items.length - 1; idx >= 0; --idx) {
      if (_items[idx].carId == refueling.carId) {
        if (_items[idx].timestamp.isAfter(refueling.timestamp)) {
          return SorroundingRefuelingData(
              prev, next + _items[idx].tripMileage, idx);
        } else if (_items[idx].timestamp.isBefore(refueling.timestamp)) {
          prev += _items[idx].tripMileage;
          next = prev;
        } else {
          next += _items[idx].tripMileage;
        }
      }
    }
    return SorroundingRefuelingData(prev, null, null);
  }
  /*List<Refueling> sorouningRefuelingsOfCar(Refueling refueling) {
    var idx = _items.indexWhere((item) => item.timestamp.isBefore(refueling.timestamp));
    if (idx == -1) idx = _items.length;
    final previousIdx = _items.indexWhere((item) => item.carId == refueling.carId, idx);
    var backIdx = idx - 1;
    if (idx > 0 && _items[idx - 1].timestamp.isAtSameMomentAs(refueling.timestamp)) {
      --backIdx;
    }
    final nextIdx = backIdx < 0 ? -1 : _items.lastIndexWhere((item) => item.carId == refueling.carId, backIdx);
    return [itemAtIndex(previousIdx), itemAtIndex(nextIdx)];
  }*/

  Future<void> fetchRefuelings(Cars cars) async {
    if (_items != null) {
      return;
    }
    await cars.fetchCars();
    final dataList =
        await DbAccess.getData(TABLE_NAME, orderBy: Refueling.TIMESTAMP);
    List<DateTime> toRemove = [];
    final checkRemove = (Refueling i) {
      if (cars.keys.contains(i.carId)) {
        return false;
      }
      toRemove.add(i.timestamp);
      return true;
    };
    _items = dataList.map((item) => Refueling.deserialize(item)).toList()
      ..removeWhere(checkRemove);
    TotalMileageCounter mileageCounter =
        TotalMileageCounter(cars.initialMileages);
    _items.forEach((refueling) => mileageCounter.updateRefueling(refueling));
    _items = _items.reversed.toList();
    _deleteRefuelings(toRemove);
  }

  Future<void> _addRefueling(Refueling refueling) async {
    final idx = _previousRefuelingIndex(refueling);
    if (idx > 0 &&
        _items[idx - 1].timestamp.isAtSameMomentAs(refueling.timestamp)) {
      _items[idx - 1] = refueling;
      DbAccess.update(TABLE_NAME, refueling.serialize(), Refueling.TIMESTAMP,
          refueling.serializedTimestamp);
    } else {
      _items.insert(idx, refueling);
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
    _items.removeWhere((item) =>
        item.timestamp.millisecondsSinceEpoch ==
        timestamp.millisecondsSinceEpoch);
    DbAccess.delete(TABLE_NAME, Refueling.TIMESTAMP,
        Refueling.serializeTimestamp(timestamp));
  }

  Future<void> _deleteRefuelings(List<DateTime> timestamps) async {
    timestamps.forEach((t) => _deleteRefueling(t));
  }

  Future<void> deleteRefuelingAndExtendNext(Refueling oldRefueling) async {
    final nextOfOld =
        oldRefueling == null ? -1 : nextRefuelingIndexOfCar(oldRefueling);
    _updateRefuelingTripMileage(nextOfOld,
        increaseBy: oldRefueling?.tripMileage);
    _deleteRefueling(oldRefueling.timestamp);
    notifyListeners();
  }

  Future<void> deleteRefuelingAndReduceTotalMileage(
      Refueling oldRefueling, RefuelingAdapter refuelingAdapter) async {
    _deleteRefueling(oldRefueling.timestamp);
    _recalculateTotalMileage(oldRefueling.carId,
        refuelingAdapter.getCarInitialMileage(oldRefueling.carId));
    notifyListeners();
  }

  Future<void> updateRefueling(Refueling oldRefueling,
      RefuelingAdapter refuelingAdapter, MileageType mileageType) async {
    DateTime timestamp = oldRefueling?.timestamp;
    Refueling refueling = refuelingAdapter.get();
    if (refueling.timestamp.millisecondsSinceEpoch !=
        timestamp?.millisecondsSinceEpoch) {
      _deleteRefueling(timestamp);
    }
    _addRefueling(refueling);
    if (mileageType == MileageType.Trip) {
      if (oldRefueling?.carId != null &&
          refuelingAdapter.get().carId != oldRefueling.carId) {
        _recalculateTotalMileage(oldRefueling.carId,
            refuelingAdapter.getCarInitialMileage(oldRefueling.carId));
      }
      _recalculateTotalMileage(
          refuelingAdapter.get().carId, refuelingAdapter.car.initialMileage);
    }
    notifyListeners();
  }

  Future<void> _updateRefuelingTripMileage(int index,
      {int increaseBy, int decreaseBy}) async {
    final item = itemAtIndex(index);
    if (item != null) {
      _items[index] = item.copyWith(
          tripMileage:
              item.tripMileage + (increaseBy ?? 0) - (decreaseBy ?? 0));
      DbAccess.update(
          TABLE_NAME,
          {Refueling.MILEAGE: _items[index].tripMileage},
          Refueling.TIMESTAMP,
          Refueling.serializeTimestamp(item.timestamp));
    }
  }

  void _recalculateTotalMileage(int carId, int initialCarMileage) {
    var total = initialCarMileage;
    for (var i = _items.length - 1; i >= 0; --i) {
      final item = _items[i];
      if (item.carId == carId) {
        total += item.tripMileage;
        item.totalMileage = total;
      }
    }
  }

  void recalculateTotalMileage(int carId, int initialCarMileage) {
    _recalculateTotalMileage(carId, initialCarMileage);
    notifyListeners();
  }

  Future<void> saveRefuelingDistance(double distance, MileageType mileageType,
      Refueling oldRefueling, RefuelingAdapter refuelingAdapter) async {
    if (mileageType == MileageType.Total) {
      final nextOfOld =
          oldRefueling == null ? -1 : nextRefuelingIndexOfCar(oldRefueling);
      await _updateRefuelingTripMileage(nextOfOld,
          increaseBy: oldRefueling?.tripMileage);
      final prevOfThis = previousRefuelingIndexOfCar(refuelingAdapter.get());
      final prevMileage = itemAtIndex(prevOfThis)?.totalMileage;
      refuelingAdapter.setTotalMileage(distance, prevMileage: prevMileage);
      final nextOfThis =
          nextRefuelingIndexOfCar(refuelingAdapter.get(), hint: prevOfThis);
      _updateRefuelingTripMileage(nextOfThis,
          decreaseBy: refuelingAdapter.get().tripMileage);
      notifyListeners();
    } else {
      refuelingAdapter.setTripMileage(distance);
    }
  }

/*  void _updateFollowingTotalMileages(int carId, DateTime timestamp, int initialCarMileage) {
    if (carId != null && timestamp != null) {
      final tmp = Refueling(carId: carId, timestamp: timestamp);
      final prevIdx = previousRefuelingIndexOfCar(tmp);
      var total = itemAtIndex(prevIdx)?.totalMileage ?? initialCarMileage;
      for (int index = prevIdx - 1; index >= 0; --index) {
        if (_items[index].carId == carId) {
          total += _items[index].tripMileage;
          _items[index].totalMileage = total;
        }
      }
      // int totalMileage = refueling.totalMileage;
      // for (var idx = nextIndex; idx >= 0; --idx) {
      //   if (_items[idx].carId == refueling.carId) {
      //     totalMileage += _items[idx].tripMileage;
      //     _items[idx].totalMileage = totalMileage;
      //   }
      // }
    }
  }*/

}
