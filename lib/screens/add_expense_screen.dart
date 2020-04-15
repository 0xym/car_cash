import 'package:car_cash/model/car.dart';
import 'package:car_cash/providers/cars.dart';
import 'package:car_cash/utils/data_validator.dart';
import 'package:car_cash/widgets/number_form.dart';
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
  Cars _cars;
  NumberForm _pricePerUnitForm;
  NumberForm _quantityForm;
  NumberForm _totalPriceForm;

  @override
  void dispose() {
    _pricePerUnitForm.dispose();
    _quantityForm.dispose();
    _totalPriceForm.dispose();
    super.dispose();
  }

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

  NumberForm _makeNumberForm(
          {@required double initialValue,
          @required PriceSet Function(String) onSaved,
          @required String labelText}) =>
      NumberForm(
        initialValue: initialValue,
        onSaved: (value) {
          final toSet = onSaved(value);
          _priceSetToNumberForm(toSet)
              ?.changeValue(_refuelingAdapter.priceSetValue(toSet));
        },
        validate: _validator.validateNumber,
        onEditingComplete: _validateOnEditingIfNeeded,
        labelText: labelText,
      );

  NumberForm _priceSetToNumberForm(PriceSet priceSet) {
    switch (priceSet) {
      case PriceSet.PricePerUnit:
        return _pricePerUnitForm;
      case PriceSet.Quantity:
        return _quantityForm;
      case PriceSet.TotalPrice:
        return _totalPriceForm;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = Localization.of(context);
    if (_refuelingAdapter == null) {
      _refuelings = Provider.of<Refuelings>(context, listen: false);
      _refuelingAdapter = ModalRoute.of(context).settings.arguments;
      _oldRefueling = _refuelingAdapter?.get();
      _refuelingAdapter ??= RefuelingAdapter(context, null);
      _validator ??= DataValidator(context);
      _cars = Provider.of<Cars>(context);
      _pricePerUnitForm = _makeNumberForm(
          initialValue: _refuelingAdapter.get().pricePerUnit,
          onSaved: (value) =>
              _refuelingAdapter.setPricePerUnit(toDouble(value)),
          labelText: localization.tr('pricePerUnit'));
      _quantityForm = _makeNumberForm(
          initialValue: _refuelingAdapter.get().quantity,
          onSaved: (value) => _refuelingAdapter.setQuantity(toDouble(value)),
          labelText: localization.tr('quantity'));
      _totalPriceForm = _makeNumberForm(
          initialValue: _refuelingAdapter.get().totalPrice,
          onSaved: (value) => _refuelingAdapter.setTotalPrice(toDouble(value)),
          labelText: localization.tr('totalPrice'));
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
                DropdownButtonFormField<int>(
                  items: _cars.keys
                      .map(
                        (id) => DropdownMenuItem(
                          value: id,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _cars.get(id).color,
                            ),
                            title: Text(_cars.get(id).name),
                            subtitle: _cars.get(id).brandAndModel == null
                                ? null
                                : Text(_cars.get(id).brandAndModel),
                          ),
                        ),
                      )
                      .toList(),
                  value: _prefs.get(DEFAULT_CAR),
                  isExpanded: true,
                  onChanged: (id) =>
                      setState(() => _refuelingAdapter.set(carId: id)),
                  decoration: InputDecoration(
                      labelText: localization.tr('selectedCar')),
                ),
                TwoItemLine(
                    _pricePerUnitForm,
                    // _numberForm(
                    //     initialValue: _refuelingAdapter.get().pricePerUnit,
                    //     onSaved: (value) =>
                    //         _refuelingAdapter.pricePerUnit = toDouble(value),
                    //     labelText: localization.tr('pricePerUnit')),
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
                    _quantityForm,
                    // _numberForm(
                    //     initialValue: _refuelingAdapter.get().quantity,
                    //     onSaved: (value) =>
                    //         _refuelingAdapter.quantity = toDouble(value),
                    //     labelText: localization.tr('quantity')),
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
                    _totalPriceForm,
                    // _numberForm(
                    //     initialValue: _refuelingAdapter.get().totalPrice,
                    //     onSaved: (value) =>
                    //         _refuelingAdapter.totalPrice = toDouble(value),
                    //     labelText: localization.tr('totalPrice')),
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
