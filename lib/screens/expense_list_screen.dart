import 'package:carsh/adapters/refueling_adapter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/localization.dart';
import '../screens/add_expense_screen.dart';
import '../screens/car_list_screen.dart';
import '../providers/refuelings.dart';
import '../providers/cars.dart';
import '../widgets/expense_item.dart';

class ExpenseListScreen extends StatelessWidget {
  static const routeName = '/expense-list';

  @override
  Widget build(BuildContext context) {
    final localization = Localization.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.tr('expensesTitle')),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.directions_car),
            onPressed: () =>
                Navigator.of(context).pushNamed(CarListScreen.routeName),
          ),
        ],
      ),
      body: FutureBuilder(
        future: Provider.of<Refuelings>(context)
            .fetchRefuelings(Provider.of<Cars>(context)),
        builder: (ctx, data) => data.connectionState == ConnectionState.waiting
            ? Center(
                child: CircularProgressIndicator(),
              )
            : Consumer<Refuelings>(
                builder: (ctx, refuelings, child) => ListView.builder(
                  itemCount: refuelings.itemCount,
                  itemBuilder: (c, idx) => ExpenseItem(
                      RefuelingAdapter(c, refuelings.itemAtIndex(idx))),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () =>
              Navigator.of(context).pushNamed(AddExpenseScreen.routeName)),
    );
  }
}
