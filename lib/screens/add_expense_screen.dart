import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../l10n/localization.dart';
import '../providers/refuelings.dart';
import '../model/refueling.dart';
import '../model/fuel_unit.dart';
import '../utils/common.dart';

class AddExpenseScreen extends StatefulWidget {
  static const routeName = '/add-expense';

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

enum MileageType { Trip, Total }

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _homeCurency = 'PLN';
  final _distanceUnitString = 'km';
  final _dateFormat = 'yyyy-MM-dd';
  final _timeFormat = 'HH:mm';
  static const _spaceBetween = 10.0;
  Refueling _refueling;
  DateTime _oldTimestamp;
  bool _validationFailed = false;

  void _saveRefueling() {
    if (_validateForm()) {
      _formKey.currentState.save();
      final refuelings = Provider.of<Refuelings>(context, listen: false);
      refuelings.changeRefueling(_oldTimestamp, _refueling);
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
    if (_refueling == null) {
      _refueling = ModalRoute.of(context).settings.arguments ?? Refueling(carId: 0, fuelId: 0, unitType: UnitType.Volume);
      _oldTimestamp = _refueling.timestamp;
      _refueling.timestamp ??= DateTime.now();
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
                Row(
                  children: <Widget>[
                    Expanded(
                        child: TextFormField(
                      initialValue: (_refueling.pricePerUnit ?? '').toString(),
                      onSaved: (value) =>
                          _refueling.pricePerUnit = toDouble(value),
                      validator: _validateNumber,
                      onEditingComplete: _validateOnEditingIfNeeded,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText:
                              localization.getTranslation('pricePerUnit'),),
                    )),
                    SizedBox(
                      width: _spaceBetween,
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(_homeCurency),
                          Checkbox(
                            value: true,
                            onChanged: (_) {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        initialValue: (_refueling.quantity ?? '').toString(),
                        onSaved: (value) =>
                            _refueling.quantity = toDouble(value),
                        validator: _validateNumber,
                        onEditingComplete: _validateOnEditingIfNeeded,

                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            labelText: localization.tr('quantity'),),
                      ),
                    ),
                    SizedBox(
                      width: _spaceBetween,
                    ),
                    Expanded(
                        child: DropdownButtonFormField<String>(
                      items: [
                        DropdownMenuItem(
                          value: 'litre',
                          child: Text(localization.tr('litre')),
                        ),
                        DropdownMenuItem(
                          value: 'gallon_us',
                          child: Text(localization.tr('gallon_us')),
                        )
                      ],
                      onChanged: (_) {},
                      decoration:
                          InputDecoration(labelText: localization.tr('unit')),
                      value: 'litre',
                    ))
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        initialValue: '',
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            labelText: localization.tr('totalPrice')),
                      ),
                    ),
                    SizedBox(
                      width: _spaceBetween,
                    ),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        items: [
                          DropdownMenuItem(
                            value: 0,
                            child: Text('Petrol'),
                          ),
                        ],
                        value: 0,
                        decoration: InputDecoration(
                            labelText: localization.tr('fuelType')),
                      ),
                    )
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        initialValue: (_refueling.displayedMileage ?? '').toString(),
                        onSaved: (value) => _refueling.setMileage(value),
                        onEditingComplete: _validateOnEditingIfNeeded,
                        validator: _validateNumber,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            labelText:
                                '${localization.tr('tripDistance')} ($_distanceUnitString)'),
                      ),
                    ),
                    SizedBox(
                      width: _spaceBetween,
                    ),
                    Expanded(
                        child: DropdownButtonFormField<MileageType>(
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
                      value: MileageType.Trip,
                      decoration: InputDecoration(
                          labelText: localization.tr('distanceMeasurement')),
                    ))
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        initialValue: DateFormat(_dateFormat)
                            .format(_refueling.timestamp),
                        readOnly: true,
                        textAlign: TextAlign.center,
                        decoration:
                            InputDecoration(labelText: localization.tr('date')),
                        onTap: () {},
                      ),
                    ),
                    SizedBox(
                      width: _spaceBetween,
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue: DateFormat(_timeFormat)
                            .format(_refueling.timestamp),
                        readOnly: true,
                        textAlign: TextAlign.center,
                        decoration:
                            InputDecoration(labelText: localization.tr('time')),
                        onTap: () {},
                      ),
                    ),
                  ],
                )
              ],
            ),
          )),
    );
  }
}
