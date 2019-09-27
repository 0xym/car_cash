import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/localization.dart';
import '../model/refueling.dart';
import '../providers/refuelings.dart';
import '../utils/common.dart';
import '../adapters/refueling_adapter.dart';
import '../widgets/refueling_datetime.dart';
import '../widgets/two_item_line.dart';

class AddExpenseScreen extends StatefulWidget {
  static const routeName = '/add-expense';

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

enum MileageType { Trip, Total }

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _homeCurency = 'PLN';
  RefuelingAdapter _refuelingAdapter;
  Refueling _oldRefueling;
  MileageType _mileageType = MileageType.Trip;
  bool _validationFailed = false;
  Refuelings _refuelings;

   void _saveRefueling() {
    if (_validateForm()) {
      _formKey.currentState.save();
      final refuelings = Provider.of<Refuelings>(context, listen: false);
      refuelings.changeRefueling(_oldRefueling.timestamp, _refuelingAdapter.get());
      if (_mileageType == MileageType.Trip) {
        if (_oldRefueling?.carId != null && _refuelingAdapter.get().carId != _oldRefueling.carId) {
          _refuelings.recalculateTotalMileage(_oldRefueling.carId, _refuelingAdapter.getCarInitialMileage(_oldRefueling.carId));
        }
        _refuelings.recalculateTotalMileage(_refuelingAdapter.get().carId, _refuelingAdapter.carInitialMileage);
      }
      Navigator.of(context).pop();
    }
  }

  String _validateNumber(String value) {
    final loc = Localization.of(context);
    double parsed = toDouble(value);
    return value.isEmpty ? loc.tr('errorValueEmpty') : parsed == null
        ? loc.tr('errorInvalidNumber') 
        : parsed <= 0.0 ? loc.tr('errorMustBePositive') : null;
  }

  String _validateRefuelingDistance(String value) {
    final preValidation = _validateNumber(value);
    if (_mileageType == MileageType.Trip || preValidation != null) {
      return preValidation;
    }
    final minMax = _refuelings.sorouningRefuelingData(_refuelingAdapter.get(), _refuelingAdapter.carInitialMileage);
    final minValue = minMax.prevMileage;
    final maxValue = minMax.nextMileage;
    return (toDouble(value) < minValue) || (maxValue != null && toDouble(value) > maxValue)  ? 'Must be greater than ${_refuelingAdapter.displayedDistance(minValue)}${maxValue == null ?"" : " and smaller than " + _refuelingAdapter.displayedDistance(maxValue).toString()}' : null;
  }

  void _saveRefuelingDistence(String value) {
    if (_mileageType == MileageType.Total) {
      final nextOfOld = _oldRefueling == null ? -1 : _refuelings.nextRefuelingIndexOfCar(_oldRefueling);
      _refuelings.updateRefuelingTripMileage(nextOfOld, increaseBy: _oldRefueling?.tripMileage);
      final prevOfThis = _refuelings.previousRefuelingIndexOfCar(_refuelingAdapter.get());
      final prevMileage = _refuelings.itemAtIndex(prevOfThis)?.totalMileage;
      _refuelingAdapter.setTotalMileage(toDouble(value), prevMileage: prevMileage);
      final nextOfThis = _refuelings.nextRefuelingIndexOfCar(_refuelingAdapter.get(), hint: prevOfThis);
      _refuelings.updateRefuelingTripMileage(nextOfThis, decreaseBy: _refuelingAdapter.get().tripMileage);
    } else {
      _refuelingAdapter.setTripMileage(toDouble(value));
    }
  }

  bool _validateForm() {
    _validationFailed = !_formKey.currentState.validate();
    return !_validationFailed;
  }

  void _validateOnEditingIfNeeded(){
    if (_validationFailed) {
      _validateForm();
    }
  }

  void _deleteAndExtendNext() {
    final nextOfOld = _oldRefueling == null ? -1 : _refuelings.nextRefuelingIndexOfCar(_oldRefueling);
    _refuelings.updateRefuelingTripMileage(nextOfOld, increaseBy: _oldRefueling?.tripMileage);
    _refuelings.deleteRefueling(_oldRefueling.timestamp);
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  void _deleteAndReduceTotal() {
    _refuelings.deleteRefueling(_oldRefueling.timestamp);
    _refuelings.recalculateTotalMileage(_oldRefueling.carId, _refuelingAdapter.getCarInitialMileage(_oldRefueling.carId));
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  void _deleteRequested() {
    final loc = Localization.of(context);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(loc.tr('deleteRefuelingQuestion')), 
      content: Text(loc.tr('deleteRefuelingDetails')),
      actions: <Widget>[
        FlatButton(child: Text(loc.tr('extendNextAction')), onPressed: _deleteAndExtendNext,),
        FlatButton(child: Text(loc.tr('reduceTotalAction')), onPressed: _deleteAndReduceTotal,),
      ]
    ,));
  }

  void _updateTimestamp(DateTime timestamp) {
    if (timestamp.isAtSameMomentAs(_refuelingAdapter.get().timestamp)) {
      return;
    }
    //TODO handling should be related to trip distance text input controller
    final oldPrev = _refuelings.previousRefuelingIndexOfCar(_refuelingAdapter.get());
    _refuelingAdapter.set(timestamp: timestamp);
    // return;
    final prev = _refuelings.previousRefuelingIndexOfCar(_refuelingAdapter.get());
    if (_mileageType == MileageType.Total) {
      _refuelingAdapter.set(tripMileage: _refuelingAdapter.get().totalMileage - (_refuelings.itemAtIndex(prev)?.totalMileage ?? _refuelingAdapter.carInitialMileage));
    } else {
      final toFuture = _refuelings.isMovedToFuture(prevIdx: oldPrev, nextIdx: prev);
      _refuelingAdapter.get().totalMileage = (_refuelings.itemAtIndex(prev)?.totalMileage ?? _refuelingAdapter.carInitialMileage) + _refuelingAdapter.get().tripMileage - (toFuture ? _oldRefueling?.tripMileage ?? 0 : 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = Localization.of(context);
    if (_refuelingAdapter == null) {
      _refuelings = Provider.of<Refuelings>(context, listen: false);
      _refuelingAdapter = ModalRoute.of(context).settings.arguments;
      _oldRefueling =  _refuelingAdapter?.get();
      _refuelingAdapter ??= RefuelingAdapter(context, null);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.addExpenseTitle),
        actions: <Widget>[
          if (_oldRefueling != null) IconButton(
            icon: Icon(Icons.delete),
            onPressed: _deleteRequested,
          ),
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _saveRefueling,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Text(
                localization.getTranslation('expenseType_Refueling'),
                style: TextStyle(fontSize: 30),
              ),
              Divider(),
              //TODO: add car selection
              TwoItemLine(
                TextFormField(
                  initialValue: (_refuelingAdapter.get().pricePerUnit ?? '').toString(),
                  onSaved: (value) => _refuelingAdapter.pricePerUnit = toDouble(value),
                  validator: _validateNumber,
                  onEditingComplete: _validateOnEditingIfNeeded,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText:
                          localization.getTranslation('pricePerUnit'),),), 
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Text(_homeCurency),
                    Checkbox(
                      value: true,
                      onChanged: (_) {},
                    ),
                  ],
                )),
              TwoItemLine(
                TextFormField(
                  initialValue: (_refuelingAdapter.get().quantity ?? '').toString(),
                  onSaved: (value) => _refuelingAdapter.quantity = toDouble(value),
                  validator: _validateNumber,
                  onEditingComplete: _validateOnEditingIfNeeded,

                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: localization.tr('quantity'),),
                ),
                DropdownButtonFormField<int>(
                  items: _refuelingAdapter.fuelUnits.map((f) => DropdownMenuItem(value: f.id, child: Text(localization.ttr(f.name)),)).toList(),
                  onChanged: (_) {},
                  decoration:
                      InputDecoration(labelText: localization.tr('unit')),
                  value: _refuelingAdapter.fuelUnit.id,
                )
              ),
              TwoItemLine(
                TextFormField(
                  initialValue: '',
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: localization.tr('totalPrice')),
                ),
                DropdownButtonFormField<int>(
                  items: _refuelingAdapter.fuelTypes.map((f) => DropdownMenuItem(value: f.id, child: Text(localization.ttr(f.name)),)).toList() ,
                  value: _refuelingAdapter.fuelType?.id,
                  decoration: InputDecoration(
                      labelText: localization.tr('fuelType')),
                  onChanged: (value) => setState(() => _refuelingAdapter.setFuelType(value)) ,
                )
              ),
              TwoItemLine(
                TextFormField(
                  initialValue: (_mileageType == MileageType.Trip ? _refuelingAdapter.displayedTripMileage : _refuelingAdapter.displayedTotalMileage)?.toString() ?? '',
                  onSaved: _saveRefuelingDistence,
                  onEditingComplete: _validateOnEditingIfNeeded,
                  validator: _validateRefuelingDistance,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText:
                          '${localization.tr(_mileageType == MileageType.Trip ? 'tripDistance' : 'totalDistance')} (${_refuelingAdapter.mileageUnitString})'),
                ),
                DropdownButtonFormField<MileageType>(
                  items: [
                    DropdownMenuItem(
                      value: MileageType.Total,
                      child: Text(localization.tr('mileageTotal')),
                    ),
                    DropdownMenuItem(
                      value: MileageType.Trip,
                      child: Text(localization.tr('mileageTrip')),
                    ),
                  ],
                  value: _mileageType,
                  onChanged: (value) => setState(() => _mileageType = value),
                  decoration: InputDecoration(
                      labelText: localization.tr('distanceMeasurement')),
                )
              ),
              TwoItemLine(RefuelingDate(_refuelingAdapter, _updateTimestamp), RefuelingTime(_refuelingAdapter, _updateTimestamp)),
            ]
          ),
        )
      )
    );
  }
}
