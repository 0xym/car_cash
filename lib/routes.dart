import 'package:flutter/widgets.dart';
import './screens/expense_list_screen.dart';
import './screens/add_expense_screen.dart';

class Routes {
  static Map<String, WidgetBuilder> get routes {
    return {
      '/': (_) => ExpenseListScreen(),
      ExpenseListScreen.routeName: (_) => ExpenseListScreen(),
      AddExpenseScreen.routeName: (_) => AddExpenseScreen(),
    };
  }

}