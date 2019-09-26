import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/localization.dart';
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
  DateTime _oldTimestamp;
  MileageType _mileageType = MileageType.Trip;
  bool _validationFailed = false;
  Refuelings _refuelings;

   void _saveRefueling() {
    if (_validateForm()) {
      _formKey.currentState.save();
      final refuelings = Provider.of<Refuelings>(context, listen: false);
      refuelings.changeRefueling(_oldTimestamp, _refuelingAdapter.get());
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
    // final sorounding = Provider.of<Refuelings>(context, listen: false).sorouningRefuelingsOfCar(_refuelingAdapter.get());
    // final minValue = sorounding[0]?.mileage ?? _refuelingAdapter.carInitialMileage;
    // final maxValue = sorounding[1]?.mileage;
    return (toDouble(value) < minValue) || (maxValue != null && toDouble(value) > maxValue)  ? 'Must be greater than ${_refuelingAdapter.displayedDistance(minValue)}${maxValue == null ?"" : " and smaller than " + _refuelingAdapter.displayedDistance(maxValue).toString()}' : null;
  }

  void _saveRefuelingDistence(String value) {
    if (_mileageType == MileageType.Total) {
      final data = _refuelings.sorouningRefuelingData(_refuelingAdapter.get(), _refuelingAdapter.carInitialMileage);
      _refuelingAdapter.setMileage(toDouble(value), previous: data.prevMileage);
      if (data.nextIndex != null) {
        _refuelings.itemAtIndex(data.nextIndex).mileage = data.nextMileage - data.prevMileage - _refuelingAdapter.get().mileage;
      }
    } else {
      _refuelingAdapter.setMileage(toDouble(value));
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

  @override
  Widget build(BuildContext context) {
    final localization = Localization.of(context);
    if (_refuelingAdapter == null) {
      _refuelings = Provider.of<Refuelings>(context, listen: false);
      _refuelingAdapter = ModalRoute.of(context).settings.arguments ?? RefuelingAdapter(context, null);
      _oldTimestamp = _refuelingAdapter.get().timestamp;
      _refuelingAdapter.get().timestamp ??= DateTime.now();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.addExpenseTitle),
        actions: <Widget>[
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
                  onSaved: (value) =>
                      _refuelingAdapter.get().pricePerUnit = toDouble(value),
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
                  onSaved: (value) =>
                      _refuelingAdapter.get().quantity = toDouble(value),
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
                  initialValue: (_refuelingAdapter.displayedMileage ?? '').toString(),
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
              TwoItemLine(RefuelingDate(_refuelingAdapter.get()), RefuelingTime(_refuelingAdapter.get())),
            ]
          ),
        )
      )
    );
  }
}
