import 'package:carsh/model/car.dart';
import 'package:carsh/providers/cars.dart';
import 'package:carsh/utils/data_validator.dart';
import 'package:carsh/utils/focus_handler.dart';
import 'package:carsh/widgets/number_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/localization.dart';
import '../model/expenditure.dart';
import '../model/preferences.dart';
import '../providers/expenditures.dart';
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

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prefs = Preferences();
  get _homeCurency => _prefs.get(CURRENCY);
  RefuelingAdapter? _refuelingAdapter;
  Expenditure? _oldRefueling;
  MileageType _mileageType = MileageType.Trip;
  bool _validationFailed = false;
  Expenditures? _refuelings;
  DataValidator? _validator;
  Cars? _cars;
  NumberForm? _pricePerUnitForm;
  NumberForm? _quantityForm;
  NumberForm? _totalPriceForm;
  FocusNode? _distanceFocusNode;
  FocusHandler? _focusHandler;
  var _savingScheduled = false;

  @override
  void dispose() {
    _pricePerUnitForm?.dispose();
    _quantityForm?.dispose();
    _totalPriceForm?.dispose();
    super.dispose();
  }

  void _scheduleSave() {
    _focusHandler?.defocusAll();
    setState(() => _savingScheduled = true);
  }

  void _saveRefueling() {
    if (_validateForm()) {
      _formKey.currentState?.save();
      _refuelings?.updateRefueling(
          _oldRefueling, _refuelingAdapter!, _mileageType);
      Navigator.of(context).pop();
    }
  }

  bool _validateForm() {
    _validationFailed = !_formKey.currentState!.validate();
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
                TextButton(
                  child: Text(loc.tr('extendNextAction')),
                  onPressed: executeActionAndClose(() =>
                      _refuelings?.deleteRefuelingAndExtendNext(_oldRefueling)),
                ),
                TextButton(
                  child: Text(loc.tr('reduceTotalAction')),
                  onPressed: executeActionAndClose(() =>
                      _refuelings?.deleteRefuelingAndReduceTotalMileage(
                          _oldRefueling!, _refuelingAdapter!)),
                ),
              ],
            ));
  }

  NumberForm _makeNumberForm(
          {required double? initialValue,
          required PriceSet Function(String) onSaved,
          required String labelText,
          bool keepTrailingZeros = true,
          int precision = 2}) =>
      NumberForm(
        initialValue: initialValue,
        onSaved: (value) {
          final toSet = onSaved(value);
          _priceSetToNumberForm(toSet)
              ?.changeValue(_refuelingAdapter!.priceSetValue(toSet)!);
        },
        focusHandler: _focusHandler!,
        validate: _validator!.validateNumber,
        onEditingComplete: _validateOnEditingIfNeeded,
        labelText: labelText,
        valueToText: (value) {
          final text = valueToText(value, precision);
          if (keepTrailingZeros) return text;
          return withoutTrailingZeros(text);
        },
      );

  NumberForm? _priceSetToNumberForm(PriceSet priceSet) {
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

  double? _distanceInRefueling() => _mileageType == MileageType.Trip
      ? _refuelingAdapter?.displayedTripMileage
      : _refuelingAdapter?.displayedTotalMileage;

  @override
  Widget build(BuildContext context) {
    if (_savingScheduled) {
      _savingScheduled = false;
      Future.delayed(Duration(), () => _saveRefueling());
    }
    final localization = Localization.of(context);
    if (_refuelingAdapter == null) {
      _focusHandler = FocusHandler(_saveRefueling);
      _refuelings = Provider.of<Expenditures>(context, listen: false);
      _refuelingAdapter =
          ModalRoute.of(context)!.settings.arguments as RefuelingAdapter?;
      _oldRefueling = _refuelingAdapter?.get();
      _refuelingAdapter ??= RefuelingAdapter(context, null);
      _validator ??= DataValidator(context);
      _cars = Provider.of<Cars>(context);
      _pricePerUnitForm = _makeNumberForm(
          initialValue: _refuelingAdapter!.get().pricePerUnit,
          onSaved: (value) =>
              _refuelingAdapter!.setPricePerUnit(toDouble(value)),
          labelText: localization.tr('pricePerUnit'));
      _focusHandler!.make(_pricePerUnitForm!.focusNode,
          () => _refuelingAdapter!.get().pricePerUnit != null);
      _quantityForm = _makeNumberForm(
          initialValue: _refuelingAdapter!.get().quantity,
          onSaved: (value) => _refuelingAdapter!.setQuantity(toDouble(value)),
          labelText: localization.tr('quantity'));
      _focusHandler!.make(_quantityForm!.focusNode,
          () => _refuelingAdapter!.get().quantity != null);
      _totalPriceForm = _makeNumberForm(
          initialValue: _refuelingAdapter!.get().totalPrice,
          onSaved: (value) => _refuelingAdapter!.setTotalPrice(toDouble(value)),
          labelText: localization.tr('totalPrice'));
      _focusHandler!.make(_totalPriceForm!.focusNode,
          () => _refuelingAdapter!.get().totalPrice != null);
      _distanceFocusNode = FocusNode();
      _focusHandler!
          .make(_distanceFocusNode!, () => _distanceInRefueling() != null);
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
              onPressed: _scheduleSave,
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
                  items: _cars!.keys!
                      .map(
                        (id) => DropdownMenuItem(
                            value: id,
                            child: Row(
                              children: [
                                CircleAvatar(
                                    backgroundColor: _cars!.get(id)!.color),
                                SizedBox(width: 5),
                                Text(_cars!.get(id)!.name!),
                                SizedBox(width: 10),
                                if (_cars!.get(id)!.brandAndModel != null)
                                  Text(
                                    _cars!.get(id)!.brandAndModel!,
                                    style: TextStyle(color: Colors.grey),
                                  )
                              ],
                            )),
                      )
                      .toList(),
                  value: _prefs.get(DEFAULT_CAR),
                  isExpanded: true,
                  onChanged: (id) =>
                      setState(() => _refuelingAdapter!.set(carId: id)),
                  decoration: InputDecoration(
                      labelText: localization.tr('selectedCar')),
                ),
                TwoItemLine(
                    _pricePerUnitForm!,
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
                    _quantityForm!,
                    DropdownButtonFormField<int>(
                      items: _refuelingAdapter!.fuelUnits
                          .map((f) => DropdownMenuItem(
                                value: f.id,
                                child: Text(localization.ttr(f.name)),
                              ))
                          .toList(),
                      onChanged: (_) {},
                      decoration:
                          InputDecoration(labelText: localization.tr('unit')),
                      value: _refuelingAdapter!.fuelUnit!.id,
                    )),
                TwoItemLine(
                    _totalPriceForm!,
                    DropdownButtonFormField<int>(
                      items: _refuelingAdapter!.fuelTypes!
                          .map((f) => DropdownMenuItem(
                                value: f!.id,
                                child: Text(localization.ttr(f.name)),
                              ))
                          .toList(),
                      value: _refuelingAdapter!.fuelType?.id,
                      decoration: InputDecoration(
                          labelText: localization.tr('fuelType')),
                      onChanged: (value) =>
                          setState(() => _refuelingAdapter!.setFuelType(value)),
                    )),
                TwoItemLine(
                    TextFormField(
                      initialValue: _distanceInRefueling()?.toString() ?? '',
                      onSaved: (value) => _refuelings!.saveRefuelingDistance(
                          toDouble(value),
                          _mileageType,
                          _oldRefueling,
                          _refuelingAdapter!),
                      onEditingComplete: _validateOnEditingIfNeeded,
                      validator: (value) => _validator!
                          .validateRefuelingDistance(value, _mileageType,
                              _refuelingAdapter!, _refuelings!),
                      focusNode: _distanceFocusNode,
                      textInputAction:
                          _focusHandler!.nodeAction(_distanceFocusNode!),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText:
                              '${localization.tr(_mileageType == MileageType.Trip ? 'tripDistance' : 'totalDistance')} (${_refuelingAdapter!.mileageUnitString})'),
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
                          setState(() => _mileageType = value!),
                      decoration: InputDecoration(
                          labelText: localization.tr('distanceMeasurement')),
                    )),
                TwoItemLine(
                    RefuelingDate(
                        _refuelingAdapter!,
                        (timestamp) => _refuelingAdapter!.updateTimestamp(
                            timestamp,
                            _refuelings!,
                            _mileageType,
                            _oldRefueling?.tripMileage)),
                    RefuelingTime(
                        _refuelingAdapter!,
                        (timestamp) => _refuelingAdapter!.updateTimestamp(
                            timestamp,
                            _refuelings!,
                            _mileageType,
                            _oldRefueling?.tripMileage))),
              ]),
            )));
  }
}
