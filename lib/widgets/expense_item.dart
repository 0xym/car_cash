import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/localization.dart';
import '../adapters/refueling_adapter.dart';
import '../model/car.dart';
import '../model/preferences.dart';
import '../screens/add_expense_screen.dart';
import '../utils/global_preferences.dart';

class ExpenseItem extends StatelessWidget {
  
  final RefuelingAdapter _refuelingAdapter;

  ExpenseItem(this._refuelingAdapter);

  @override
  Widget build(BuildContext context) {
    final loc = Localization.of(context);
    final height = RefuelingDetails.getHeight(context) + ExpenseTitle.getHeight(context);
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(AddExpenseScreen.routeName, arguments: _refuelingAdapter),
      child: Card(
        child: Row(
          children: [
            VerticalSeparator(height, _refuelingAdapter.car.color),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                ExpenseTitle(loc.tr('expenseType_Refueling'), _refuelingAdapter.car),
                RefuelingDetails(refuelingAdapter: _refuelingAdapter),
              ],),
            ),
            VerticalSeparator(height, _refuelingAdapter.car.color),
          ]
      )),
    );
  }
}

class ExpenseTitle extends StatelessWidget {
  final String title;
  final Car car;
  static const size = 16.0;
  static const dividerHeight = 5.0;
  ExpenseTitle(this.title, this.car);

  static double getHeight(BuildContext context) {
    return size * MediaQuery.of(context).textScaleFactor + dividerHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(children: <Widget>[
          Text('$title: ', style: TextStyle(fontSize: size),),
          Text(car.name, style: TextStyle(fontSize: size, fontWeight: FontWeight.bold),)
        ],),
        Divider(height: dividerHeight,),
    ],);
  }
}

class VerticalSeparator extends StatelessWidget {
  final double height;
  final Color color;
  final width = 8.0;
  static const margin = 10.0;
  VerticalSeparator(this.height, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(width: width, height: height, /*decoration: BoxDecoration(color: color),*/ color: color, margin: const EdgeInsets.symmetric(horizontal: margin),);
  }

}

class RefuelingDetails extends StatelessWidget {
  RefuelingDetails({
    @required RefuelingAdapter refuelingAdapter,
  }) : _refuelingAdapter = refuelingAdapter;
  final _prefs = Preferences();
  static const currencyDigits = 2;
  static const fuelingPrecision = 2;
  get _homeCurency => _prefs.get(CURRENCY);
  get _dateFormat => _prefs.get(DATE_FORMAT);
  get _timeFormat => _prefs.get(TIME_FORMAT);
  final RefuelingAdapter _refuelingAdapter;
  static const widgetTextLines = 3;

  static double getHeight(BuildContext context) {
    return Theme.of(context).textTheme.body1.fontSize * MediaQuery.of(context).textScaleFactor * widgetTextLines;
  }

  @override
  Widget build(BuildContext context) {
    final loc = Localization.of(context);
    return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      FittedBox(child: Column(children: <Widget>[
        Text(DateFormat('$_dateFormat').format(_refuelingAdapter.get().timestamp)),
        Text(DateFormat('$_timeFormat').format(_refuelingAdapter.get().timestamp)),
        Text(loc.ttr(_refuelingAdapter.fuelType.name)),
      ],)
      ),
      FittedBox(child: Column(children: <Widget>[
        Text('${_refuelingAdapter.displayedTotalMileage} ${_refuelingAdapter.mileageUnitString}'),
        Text('+${_refuelingAdapter.displayedTripMileage} ${_refuelingAdapter.mileageUnitString}'),
        Text('${(_refuelingAdapter.get().quantity / _refuelingAdapter.displayedTripMileage * 100).toStringAsFixed(fuelingPrecision)} ${loc.ttr(_refuelingAdapter.quantityUnitAbbrStringId)}/100 ${_refuelingAdapter.mileageUnitString}'),
      ],),),
      FittedBox(child: Column(children: <Widget>[
        Text('${(_refuelingAdapter.totalPriceInHomeCurrency).toStringAsFixed(currencyDigits)} $_homeCurency'),
        Text('${(_refuelingAdapter.pricePerUnitInHomeCurrency).toStringAsFixed(currencyDigits)} $_homeCurency/${loc.ttr(_refuelingAdapter.quantityUnitAbbrStringId)}'),
        Text('${_refuelingAdapter.get().quantity.toStringAsFixed(fuelingPrecision)} ${loc.ttr(_refuelingAdapter.quantityUnitAbbrStringId)}')
      ],),),
    ],
        );
  }
}