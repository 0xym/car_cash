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

class Expenditures extends ChangeNotifier {
  static const TABLE_NAME = 'expenditures';
  static bool _dbCreationSubscribed = false;

  bool _itemsFetched = false;
  List<Expenditure> _items = [];
  Expenditures() {
    if (!_dbCreationSubscribed) {
      _dbCreationSubscribed = true;
      DbAccess.addOnCreateCommand(
          'CREATE TABLE $TABLE_NAME${Expenditure.dbLayout}');
    }
  }

  bool _isIndexValid(int? index) =>
      index != null && index >= 0 && index < _items.length;
  bool isMovedToFuture({required int prevIdx, required int nextIdx}) =>
      nextIdx < prevIdx;
  Expenditure? itemAtIndex(int index) =>
      _isIndexValid(index) ? _items[index] : null;
  int get itemCount => _items.length;
  // Refueling lastOfCar(int id) => _items.firstWhere((i) => i.carId == id);
  int _previousExpenditureIndex(Expenditure expenditure, List<Expenditure> items) {
    //TODO - use binary search
    final idx = items
        .indexWhere((item) => item.timestamp!.isBefore(expenditure.timestamp!));
    return idx == -1 ? _items.length : idx;
  }

  int previousRefuelingIndexOfCar(Expenditure refueling) {
    final idx = _previousExpenditureIndex(refueling, _items);
    return idx == _items.length
        ? -1
        : _items.indexWhere((item) => (item.carId == refueling.carId && item.costType == ExpenditureType.Refueling), idx);
  }

  int _nextRefuelingIndex(Expenditure refueling) =>
      _items.lastIndexWhere((item) => item.timestamp!
          .isAfter(refueling.timestamp!) && item.expenditureType == ExpenditureType.Refueling); // TODO - use binary search

  int nextRefuelingIndexOfCar(Expenditure refueling, {int? hint}) {
    final idx = hint ?? _nextRefuelingIndex(refueling);
    final getNext = (int index) =>
        _items.lastIndexWhere((item) => item.carId == refueling.carId && item.expenditureType == ExpenditureType.Refueling, index);
    final ret = getNext(idx);
    return ((ret != -1) &&
            (_items[ret].timestamp!.isAtSameMomentAs(refueling.timestamp!)))
        ? getNext(ret)
        : ret;
  }

  SorroundingRefuelingData sorouningRefuelingData(
      Expenditure refueling, int initial) {
    var prev = initial;
    int next = prev;
    for (var idx = _items.length - 1; idx >= 0; --idx) {
      if (_items[idx].carId == refueling.carId && _items[idx].expenditureType == ExpenditureType.Refueling) {
        if (_items[idx].timestamp!.isAfter(refueling.timestamp!)) {
          return SorroundingRefuelingData(
              prev, next + _items[idx].tripMileage!, idx);
        } else if (_items[idx].timestamp!.isBefore(refueling.timestamp!)) {
          prev += _items[idx].tripMileage!;
          next = prev;
        } else {
          next += _items[idx].tripMileage!;
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

  Future<void> fetchExpenditures(Cars cars) async {
    if (_itemsFetched) {
      return;
    }
    _itemsFetched = true;
    await cars.fetchCars();
    final dataList = await DbAccess.getData(TABLE_NAME, orderBy: ExpenditureDbKeys.timestamp.name);
    _items = dataList.map((item) => Expenditure.deserialize(item)).toList();
    TotalMileageCounter mileageCounter = TotalMileageCounter(cars.initialMileages);
    _items.forEach((refueling) => mileageCounter.updateRefueling(refueling));
    _items = _items.reversed.toList();
    _deleteExpenditures(_items.where((element) => !cars.keys!.contains(element.carId)).map((e) => e.timestamp!));
  }

  Future<void> _addExpenditure(Expenditure expenditure) async {
    final idx = _previousExpenditureIndex(expenditure, _items);
    if (idx > 0 &&
        _items[idx - 1].timestamp!.isAtSameMomentAs(expenditure.timestamp!)) {//update
      _items[idx - 1] = expenditure;
      DbAccess.update(TABLE_NAME, expenditure.serialize(), ExpenditureDbKeys.timestamp.name,
          expenditure.serializedTimestamp);
    } else {
      _items.insert(idx, expenditure);
      DbAccess.insert(TABLE_NAME, expenditure.serialize());
    }
  }

  Future<void> clear() async {
    _items = [];
    notifyListeners();
    DbAccess.delete(TABLE_NAME, null, null);
  }

  Future<void> _deleteExpenditure(DateTime? timestamp) async {
    if (timestamp == null) {
      return;
    }
    _items.removeWhere((item) => item.timestampMatches(timestamp));
    DbAccess.delete(TABLE_NAME, ExpenditureDbKeys.timestamp.name,
        Expenditure.serializeTimestamp(timestamp));
  }

  Future<void> _deleteExpenditures(Iterable<DateTime> timestamps) async {
    timestamps.forEach((t) => _deleteExpenditure(t));
  }

  Future<void> deleteRefuelingAndExtendNext(Expenditure? oldRefueling) async {
    final nextOfOld =
        oldRefueling == null ? -1 : nextRefuelingIndexOfCar(oldRefueling);
    _updateExpenditureTripMileage(nextOfOld,
        increaseBy: oldRefueling?.tripMileage);
    _deleteExpenditure(oldRefueling?.timestamp);
    notifyListeners();
  }

  Future<void> deleteRefuelingAndReduceTotalMileage(
      Expenditure oldRefueling, RefuelingAdapter refuelingAdapter) async {
    _deleteExpenditure(oldRefueling.timestamp);
    _recalculateTotalMileage(oldRefueling.carId,
        refuelingAdapter.getCarInitialMileage(oldRefueling.carId!)!);
    notifyListeners();
  }

  Future<void> updateRefueling(Expenditure? oldRefueling,
      RefuelingAdapter refuelingAdapter, MileageType mileageType) async { //TODO - fix after adding adapter
    DateTime? timestamp = oldRefueling?.timestamp;
    Expenditure refueling = refuelingAdapter.get();
    if (refueling.timestamp!.millisecondsSinceEpoch !=
        timestamp?.millisecondsSinceEpoch) {
      _deleteExpenditure(timestamp);
    }
    _addExpenditure(refueling);
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

  Future<void> _updateExpenditureTripMileage(int index,
      {int? increaseBy, int? decreaseBy}) async {
    final item = itemAtIndex(index);
    if (item != null) {
      _items[index] = item.copyWith(
          tripMileage:
              item.tripMileage! + (increaseBy ?? 0) - (decreaseBy ?? 0));
      DbAccess.update(
          TABLE_NAME,
          {ExpenditureDbKeys.mileage.name: _items[index].tripMileage},
          ExpenditureDbKeys.timestamp.name,
          Expenditure.serializeTimestamp(item.timestamp));
    }
  }

  void _recalculateTotalMileage(int? carId, int initialCarMileage) {
    var total = initialCarMileage;
    for (var i = _items.length - 1; i >= 0; --i) {
      final item = _items[i];
      if (item.carId == carId) {
        if (item.expenditureType == ExpenditureType.Refueling) {
          total += item.tripMileage!;
        }
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
      await _updateExpenditureTripMileage(nextOfOld,
          increaseBy: oldRefueling?.tripMileage);
      final prevOfThis = previousRefuelingIndexOfCar(refuelingAdapter.get());
      final prevMileage = itemAtIndex(prevOfThis)?.totalMileage;
      refuelingAdapter.setTotalMileage(distance, prevMileage: prevMileage ?? 0);
      final nextOfThis =
          nextRefuelingIndexOfCar(refuelingAdapter.get(), hint: prevOfThis);
      _updateExpenditureTripMileage(nextOfThis,
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
