import 'package:flutter/material.dart';
import '../model/refueling.dart';
import '../utils/db_access.dart';

class Refuelings extends ChangeNotifier {
  static const TABLE_NAME = 'refuelings';
  static bool _dbCreationSubscribed = false;
  List<Refueling> _items = [];
  Refuelings() {
    if (!_dbCreationSubscribed) {
      _dbCreationSubscribed = true;
      DbAccess.addOnCreateCommand('CREATE TABLE $TABLE_NAME(${Refueling.TIMESTAMP} INT PRIMARY_KEY, ${Refueling.CAR_ID} INT, ${Refueling.EXCHANGE_RATE} REAL, ${Refueling.FUEL_ID} INT, ${Refueling.MILEAGE} INT, ${Refueling.NOTE} TEXT, ${Refueling.PRICE_PER_UNIT} REAL, ${Refueling.QUANTITY} REAL, ${Refueling.UNIT_TYPE} TEXT)');
    }
  }

  Refueling itemAtIndex(int index) {
    return _items[index];//consider reversing indexes
  }

  Future<void> fetchRefuelings() async {
    final dataList = await DbAccess.getData(TABLE_NAME, orderBy: Refueling.TIMESTAMP);
    _items = dataList.map((item) => Refueling.deserialize(item)).toList().reversed.toList();
  }

  int get itemCount {
    return _items.length;
  }

  Future<void> _addRefueling(Refueling refueling) async {
    var idx = _items.indexWhere((item) => item.timestamp.isBefore(refueling.timestamp));
    if (idx == -1) idx = _items.length;
    print(idx);
    if (idx > 0 && _items[idx - 1].timestamp.isAtSameMomentAs(refueling.timestamp)) {
      _items[idx - 1] = refueling;
      DbAccess.update(TABLE_NAME, refueling.serialize(), '${Refueling.TIMESTAMP} = ?', [refueling.serializedTimestamp]);
    } else {
      _items.add(refueling);
      // DbAccess.update(TABLE_NAME, refueling.serialize(), '${Refueling.TIMESTAMP} = ?', [refueling.serializedTimestamp]);
      DbAccess.insert(TABLE_NAME, refueling.serialize());
    }
  }

  Future<void> clear() async {
    _items = [];
    notifyListeners();
    DbAccess.delete(TABLE_NAME, null);
  }

  Future<void> _deleteRefueling(DateTime timestamp) async {
    if (timestamp == null) {
      return;
    }
    _items.removeWhere((item) => item.timestamp == timestamp);
    DbAccess.delete(TABLE_NAME, 'WHERE ${Refueling.TIMESTAMP}=${Refueling(carId: null, fuelId: null, unitType: null, timestamp: timestamp).serializedTimestamp}');
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