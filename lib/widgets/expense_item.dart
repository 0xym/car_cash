import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/localization.dart';
import '../adapters/refueling_adapter.dart';
import '../screens/add_expense_screen.dart';

class ExpenseItem extends StatelessWidget {
  final _homeCurency = 'PLN';
  final _dateFormat = 'yyyy-MM-dd';
  final _timeFormat = 'HH:mm';
  final RefuelingAdapter _refuelingAdapter;

  ExpenseItem(this._refuelingAdapter);

  @override
  Widget build(BuildContext context) {
    final loc = Localization.of(context);
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(AddExpenseScreen.routeName, arguments: _refuelingAdapter),
      child: Card(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
          FittedBox(child: Column(children: <Widget>[
            Text(DateFormat('$_dateFormat').format(_refuelingAdapter.get().timestamp)),
            Text(DateFormat('$_timeFormat').format(_refuelingAdapter.get().timestamp)),
          ],)
          ),
          FittedBox(child: Column(children: <Widget>[
            Text(_refuelingAdapter.totalMileageString),
          ],),),
          FittedBox(child: Column(children: <Widget>[
            Text('${(_refuelingAdapter.totalPriceInHomeCurrency).toStringAsFixed(2)} $_homeCurency'),
            Text('${(_refuelingAdapter.pricePerUnitInHomeCurrency).toStringAsFixed(2)} $_homeCurency/${loc.tr(_refuelingAdapter.quantityUnitStringId)}'),
          ],),)
        ],),
      ),
    );
  }
}