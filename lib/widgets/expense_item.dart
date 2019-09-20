import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/refueling.dart';
import '../screens/add_expense_screen.dart';

class ExpenseItem extends StatelessWidget {
  final _homeCurency = 'PLN';
  final _dateFormat = 'yyyy-MM-dd';
  final _timeFormat = 'HH:mm';
  final Refueling _refueling;

  ExpenseItem(this._refueling);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(AddExpenseScreen.routeName, arguments: _refueling),
      child: Card(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
          FittedBox(child: Column(children: <Widget>[
            Text(DateFormat('$_dateFormat').format(_refueling.timestamp)),
            Text(DateFormat('$_timeFormat').format(_refueling.timestamp)),
          ],)
          ),
          FittedBox(child: Column(children: <Widget>[
            Text(_refueling.totalMileageString),
          ],),),
          FittedBox(child: Column(children: <Widget>[
            Text('${(_refueling.pricePerUnit * _refueling.quantity).toStringAsFixed(2)} $_homeCurency')
          ],),)
        ],),
      ),
    );
  }
}