import 'package:flutter/material.dart';
import '../l10n/localization.dart';
import '../screens/add_expense_screen.dart';

class ExpenseListScreen extends StatelessWidget {
  static const routeName ='/expense-list';

  @override
  Widget build(BuildContext context) {
    final localization = Localization.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(localization.expensesTitle),),
      floatingActionButton: FloatingActionButton(child: Icon(Icons.add), onPressed: () => Navigator.of(context).pushNamed(AddExpenseScreen.routeName)),
    );
  }
}