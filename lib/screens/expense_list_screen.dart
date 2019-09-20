import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/localization.dart';
import '../screens/add_expense_screen.dart';
import '../providers/refuelings.dart';
import '../widgets/expense_item.dart';

class ExpenseListScreen extends StatelessWidget {
  static const routeName ='/expense-list';

  @override
  Widget build(BuildContext context) {
    final localization = Localization.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(localization.expensesTitle), actions: <Widget>[
        IconButton(icon: Icon(Icons.delete_forever), onPressed: () => Provider.of<Refuelings>(context, listen: false).clear(),)
      ],),
      body: FutureBuilder(future: Provider.of<Refuelings>(context).fetchRefuelings(),
        builder: (ctx, data) => data.connectionState == ConnectionState.waiting ? Center(child: CircularProgressIndicator(),) : 
          Consumer<Refuelings>(builder: (ctx, refuelings, child) => ListView.builder(itemCount: refuelings.itemCount, itemBuilder: (c, idx) => 
          ExpenseItem(refuelings.itemAtIndex(idx)),),),),
      floatingActionButton: FloatingActionButton(child: Icon(Icons.add), onPressed: () => Navigator.of(context).pushNamed(AddExpenseScreen.routeName)),
    );
  }
}