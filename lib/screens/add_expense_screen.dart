import 'package:car_cash/utils/data_validator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/localization.dart';
import '../model/refueling.dart';
import '../model/preferences.dart';
import '../providers/refuelings.dart';
import '../utils/common.dart';
import '../utils/global_preferences.dart';
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
  final _prefs = Preferences();
  get _homeCurency => _prefs.get(CURRENCY);
  RefuelingAdapter _refuelingAdapter;
  Refueling _oldRefueling;
  MileageType _mileageType = MileageType.Trip;
  bool _validationFailed = false;
  Refuelings _refuelings;
  DataValidator _validator;

  void _saveRefueling() {
    if (_validateForm()) {
      _formKey.currentState.save();
      _refuelings.updateRefueling(
          _oldRefueling, _refuelingAdapter, _mileageType);
      Navigator.of(context).pop();
    }
  }

  bool _validateForm() {
    _validationFailed = !_formKey.currentState.validate();
    return !_validationFailed;
  }

  void _validateOnEditingIfNeeded() {
    if (_validationFailed) {
      _validateForm();
    }
  }

  void _deleteRequested() {
    final loc = Localization.of(context);
    final Function(Function) executeActionAndClose = (Function action) {
      action();
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    };
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(loc.tr('deleteRefuelingQuestion')),
              content: Text(loc.tr('deleteRefuelingDetails')),
              actions: <Widget>[
                FlatButton(
                  child: Text(loc.tr('extendNextAction')),
                  onPressed: executeActionAndClose(() =>
                      _refuelings.deleteRefuelingAndExtendNext(_oldRefueling)),
                ),
                FlatButton(
                  child: Text(loc.tr('reduceTotalAction')),
                  onPressed: executeActionAndClose(() =>
                      _refuelings.deleteRefuelingAndReduceTotalMileage(
                          _oldRefueling, _refuelingAdapter)),
                ),
              ],
            ));
  }

  void _updateTimestamp(DateTime timestamp) {
    if (timestamp.isAtSameMomentAs(_refuelingAdapter.get().timestamp)) {
      return;
    }
    //TODO handling should be related to trip distance text input controller
    final oldPrev =
        _refuelings.previousRefuelingIndexOfCar(_refuelingAdapter.get());
    _refuelingAdapter.set(timestamp: timestamp);
    // return;
    final prev =
        _refuelings.previousRefuelingIndexOfCar(_refuelingAdapter.get());
    if (_mileageType == MileageType.Total) {
      _refuelingAdapter.set(
          tripMileage: _refuelingAdapter.get().totalMileage -
              (_refuelings.itemAtIndex(prev)?.totalMileage ??
                  _refuelingAdapter.car.initialMileage));
    } else {
      final toFuture =
          _refuelings.isMovedToFuture(prevIdx: oldPrev, nextIdx: prev);
      _refuelingAdapter.get().totalMileage =
          (_refuelings.itemAtIndex(prev)?.totalMileage ??
                  _refuelingAdapter.car.initialMileage) +
              _refuelingAdapter.get().tripMileage -
              (toFuture ? _oldRefueling?.tripMileage ?? 0 : 0);
    }
  }

  Widget _numberForm(
          {@required double initialValue,
          @required void Function(String) onSaved,
          @required String labelText}) =>
      TextFormField(
        initialValue: (initialValue ?? '').toString(),
        onSaved: onSaved,
        validator: _validator.validateNumber,
        onEditingComplete: _validateOnEditingIfNeeded,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: labelText),
      );

  @override
  Widget build(BuildContext context) {
    final localization = Localization.of(context);
    if (_refuelingAdapter == null) {
      _refuelings = Provider.of<Refuelings>(context, listen: false);
      _refuelingAdapter = ModalRoute.of(context).settings.arguments;
      _oldRefueling = _refuelingAdapter?.get();
      _refuelingAdapter ??= RefuelingAdapter(context, null);
      _validator ??= DataValidator(context);
    }
    return Scaffold(
        appBar: AppBar(
          title: Text(localization.tr('addExpenseTitle')),
          actions: <Widget>[
            if (_oldRefueling != null)
              IconButton(
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
              child: Column(children: <Widget>[
                Text(
                  localization.tr('expenseType_Refueling'),
                  style: TextStyle(fontSize: 30),
                ),
                Divider(),
                //TODO: add car selection
                TwoItemLine(
                    _numberForm(
                        initialValue: _refuelingAdapter.get().pricePerUnit,
                        onSaved: (value) =>
                            _refuelingAdapter.pricePerUnit = toDouble(value),
                        labelText: localization.tr('pricePerUnit')),
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
                    _numberForm(
                        initialValue: _refuelingAdapter.get().quantity,
                        onSaved: (value) =>
                            _refuelingAdapter.quantity = toDouble(value),
                        labelText: localization.tr('quantity')),
                    DropdownButtonFormField<int>(
                      items: _refuelingAdapter.fuelUnits
                          .map((f) => DropdownMenuItem(
                                value: f.id,
                                child: Text(localization.ttr(f.name)),
                              ))
                          .toList(),
                      onChanged: (_) {},
                      decoration:
                          InputDecoration(labelText: localization.tr('unit')),
                      value: _refuelingAdapter.fuelUnit.id,
                    )),
                TwoItemLine(
                    _numberForm(
                        initialValue: null,
                        onSaved: (_) {},
                        labelText: localization.tr('totalPrice')),
                    DropdownButtonFormField<int>(
                      items: _refuelingAdapter.fuelTypes
                          .map((f) => DropdownMenuItem(
                                value: f.id,
                                child: Text(localization.ttr(f.name)),
                              ))
                          .toList(),
                      value: _refuelingAdapter.fuelType?.id,
                      decoration: InputDecoration(
                          labelText: localization.tr('fuelType')),
                      onChanged: (value) =>
                          setState(() => _refuelingAdapter.setFuelType(value)),
                    )),
                TwoItemLine(
                    TextFormField(
                      initialValue: (_mileageType == MileageType.Trip
                                  ? _refuelingAdapter.displayedTripMileage
                                  : _refuelingAdapter.displayedTotalMileage)
                              ?.toString() ??
                          '',
                      onSaved: (value) => _refuelings.saveRefuelingDistance(
                          toDouble(value),
                          _mileageType,
                          _oldRefueling,
                          _refuelingAdapter),
                      onEditingComplete: _validateOnEditingIfNeeded,
                      validator: (value) =>
                          _validator.validateRefuelingDistance(value,
                              _mileageType, _refuelingAdapter, _refuelings),
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
                      onChanged: (value) =>
                          setState(() => _mileageType = value),
                      decoration: InputDecoration(
                          labelText: localization.tr('distanceMeasurement')),
                    )),
                TwoItemLine(RefuelingDate(_refuelingAdapter, _updateTimestamp),
                    RefuelingTime(_refuelingAdapter, _updateTimestamp)),
              ]),
            )));
  }
}
