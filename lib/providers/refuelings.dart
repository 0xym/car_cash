import 'package:carsh/adapters/refueling_adapter.dart';
import 'package:carsh/adapters/total_mileage_counter.dart';
import 'package:flutter/material.dart';
import '../model/expenditure.dart';
import '../utils/db_access.dart';
import './cars.dart';

class SorroundingRefuelingData {
  int prevMileage;
  int? nextMileage;
  int? nextIndex;
  SorroundingRefuelingData(this.prevMileage, this.nextMileage, this.nextIndex);
}

class Refuelings extends ChangeNotifier {
  static const TABLE_NAME = 'expenditures';
  static bool _dbCreationSubscribed = false;

  List<Expenditure>? _refuelings;
  List<Expenditure>? _items;//non refuelings - todo
  Refuelings() {
    if (!_dbCreationSubscribed) {
      _dbCreationSubscribed = true;
      DbAccess.addOnCreateCommand(
          'CREATE TABLE $TABLE_NAME${Expenditure.dbLayout}');
    }
  }

  bool _isIndexValid(int? index) =>
      index != null && index >= 0 && index < _items!.length;
  bool isMovedToFuture({required int prevIdx, required int nextIdx}) =>
      nextIdx < prevIdx;
  Expenditure? itemAtIndex(int index) =>
      _isIndexValid(index) ? _refuelings![index] : null;
  int get itemCount => _refuelings!.length;
  // Refueling lastOfCar(int id) => _items.firstWhere((i) => i.carId == id);
  int _previousRefuelingIndex(Expenditure refueling) {
    //TODO - use binary search
    final idx = _refuelings!
        .indexWhere((item) => item.timestamp!.isBefore(refueling.timestamp!));
    return idx == -1 ? _refuelings!.length : idx;
  }

  int previousRefuelingIndexOfCar(Expenditure refueling) {
    final idx = _previousRefuelingIndex(refueling);
    return idx == _items!.length
        ? -1
        : _refuelings!.indexWhere((item) => item.carId == refueling.carId, idx);
  }

  int _nextRefuelingIndex(Expenditure refueling) =>
      _items!.lastIndexWhere((item) => item.timestamp!
          .isAfter(refueling.timestamp!)); // TODO - use binary search
  int nextRefuelingIndexOfCar(Expenditure refueling, {int? hint}) {
    final idx = hint ?? _nextRefuelingIndex(refueling);
    final getNext = (int index) =>
        _items!.lastIndexWhere((item) => item.carId == refueling.carId, index);
    final ret = getNext(idx);
    return ((ret != -1) &&
            (_items![ret].timestamp!.isAtSameMomentAs(refueling.timestamp!)))
        ? getNext(ret)
        : ret;
  }

  SorroundingRefuelingData sorouningRefuelingData(
      Expenditure refueling, int initial) {
    var prev = initial;
    int next = prev;
    for (var idx = _refuelings!.length - 1; idx >= 0; --idx) {
      if (_refuelings![idx].carId == refueling.carId) {
        if (_refuelings![idx].timestamp!.isAfter(refueling.timestamp!)) {
          return SorroundingRefuelingData(
              prev, next + _refuelings![idx].tripMileage!, idx);
        } else if (_refuelings![idx].timestamp!.isBefore(refueling.timestamp!)) {
          prev += _refuelings![idx].tripMileage!;
          next = prev;
        } else {
          next += _refuelings![idx].tripMileage!;
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
    if (_refuelings != null) {
      return;
    }
    await cars.fetchCars();
    final dataList =
        await DbAccess.getData(TABLE_NAME, orderBy: Expenditure.TIMESTAMP);
    List<DateTime> toRemove = [];
    final checkRemove = (Expenditure i) {
      if (cars.keys!.contains(i.carId)) {
        return false;
      }
      toRemove.add(i.timestamp!);
      return true;
    };
    _items = dataList.map((item) => Expenditure.deserialize(item)).toList();
    _refuelings = _items!.where((element) => element.expenditureType == ExpenditureType.Refueling).toList()
      ..removeWhere(checkRemove);
    _items!.removeWhere((element) => element.expenditureType == ExpenditureType.Refueling);
    TotalMileageCounter mileageCounter =
        TotalMileageCounter(cars.initialMileages);
    _refuelings!.forEach((refueling) => mileageCounter.updateRefueling(refueling));
    _refuelings = _refuelings!.reversed.toList();
    _deleteRefuelings(toRemove);
  }

  Future<void> _addRefueling(Expenditure refueling) async {
    final idx = _previousRefuelingIndex(refueling);
    if (idx > 0 &&
        _refuelings![idx - 1].timestamp!.isAtSameMomentAs(refueling.timestamp!)) {
      _refuelings![idx - 1] = refueling;
      DbAccess.update(TABLE_NAME, refueling.serialize(), Expenditure.TIMESTAMP,
          refueling.serializedTimestamp);
    } else {
      _refuelings!.insert(idx, refueling);
      DbAccess.insert(TABLE_NAME, refueling.serialize());
    }
  }

  Future<void> clear() async {
    _refuelings = [];
    notifyListeners();
    DbAccess.delete(TABLE_NAME, null, null);
  }

  Future<void> _deleteRefueling(DateTime? timestamp) async {
    if (timestamp == null) {
      return;
    }
    _refuelings!.removeWhere((item) =>
        item.timestamp!.millisecondsSinceEpoch ==
        timestamp.millisecondsSinceEpoch);
    DbAccess.delete(TABLE_NAME, Expenditure.TIMESTAMP,
        Expenditure.serializeTimestamp(timestamp));
  }

  Future<void> _deleteRefuelings(List<DateTime> timestamps) async {
    timestamps.forEach((t) => _deleteRefueling(t));
  }

  Future<void> deleteRefuelingAndExtendNext(Expenditure? oldRefueling) async {
    final nextOfOld =
        oldRefueling == null ? -1 : nextRefuelingIndexOfCar(oldRefueling);
    _updateRefuelingTripMileage(nextOfOld,
        increaseBy: oldRefueling?.tripMileage);
    _deleteRefueling(oldRefueling?.timestamp);
    notifyListeners();
  }

  Future<void> deleteRefuelingAndReduceTotalMileage(
      Expenditure oldRefueling, RefuelingAdapter refuelingAdapter) async {
    _deleteRefueling(oldRefueling.timestamp);
    _recalculateTotalMileage(oldRefueling.carId,
        refuelingAdapter.getCarInitialMileage(oldRefueling.carId!)!);
    notifyListeners();
  }

  Future<void> updateRefueling(Expenditure? oldRefueling,
      RefuelingAdapter refuelingAdapter, MileageType mileageType) async {
    DateTime? timestamp = oldRefueling?.timestamp;
    Expenditure refueling = refuelingAdapter.get();
    if (refueling.timestamp!.millisecondsSinceEpoch !=
        timestamp?.millisecondsSinceEpoch) {
      _deleteRefueling(timestamp);
    }
    _addRefueling(refueling);
    if (mileageType == MileageType.Trip) {
      if (oldRefueling?.carId != null &&
          refuelingAdapter.get().carId != oldRefueling?.carId) {
        _recalculateTotalMileage(oldRefueling?.carId,
            refuelingAdapter.getCarInitialMileage(oldRefueling?.carId)!);
      }
      _recalculateTotalMileage(
          refuelingAdapter.get().carId, refuelingAdapter.car!.initialMileage!);
    }
    notifyListeners();
  }

  Future<void> _updateRefuelingTripMileage(int index,
      {int? increaseBy, int? decreaseBy}) async {
    final item = itemAtIndex(index);
    if (item != null) {
      _refuelings![index] = item.copyWith(
          tripMileage:
              item.tripMileage! + (increaseBy ?? 0) - (decreaseBy ?? 0));
      DbAccess.update(
          TABLE_NAME,
          {Expenditure.MILEAGE: _refuelings![index].tripMileage},
          Expenditure.TIMESTAMP,
          Expenditure.serializeTimestamp(item.timestamp));
    }
  }

  void _recalculateTotalMileage(int? carId, int initialCarMileage) {
    var total = initialCarMileage;
    for (var i = _refuelings!.length - 1; i >= 0; --i) {
      final item = _refuelings![i];
      if (item.carId == carId) {
        total += item.tripMileage!;
        item.totalMileage = total;
      }
    }
  }

  void recalculateTotalMileage(int carId, int initialCarMileage) {
    _recalculateTotalMileage(carId, initialCarMileage);
    notifyListeners();
  }

  Future<void> saveRefuelingDistance(double? distance, MileageType mileageType,
      Expenditure? oldRefueling, RefuelingAdapter refuelingAdapter) async {
    if (mileageType == MileageType.Total) {
      final nextOfOld =
          oldRefueling == null ? -1 : nextRefuelingIndexOfCar(oldRefueling);
      await _updateRefuelingTripMileage(nextOfOld,
          increaseBy: oldRefueling?.tripMileage);
      final prevOfThis = previousRefuelingIndexOfCar(refuelingAdapter.get());
      final prevMileage = itemAtIndex(prevOfThis)?.totalMileage;
      refuelingAdapter.setTotalMileage(distance, prevMileage: prevMileage ?? 0);
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
