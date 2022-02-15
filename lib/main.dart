import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes.dart';
import './providers/refuelings.dart';
import './providers/fuel_types.dart';
import './providers/fuel_units.dart';
import './providers/cars.dart';
import './screens/add_car_screen.dart';
import './screens/expense_list_screen.dart';
import './model/shared_prefs.dart';

void main() => runApp(MyApp());

Future<void> fetchMandatoryData(Cars cars) async {
  await SharedPrefs.aget();
  await cars.fetchCars();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: SharedPrefs.aget(),
        builder: (ctx, data) => data.connectionState == ConnectionState.waiting
            ? Center(child: CircularProgressIndicator())
            : MultiProvider(
                providers: [
                  ChangeNotifierProvider.value(
                    value: FuelTypes(),
                  ),
                  ChangeNotifierProvider.value(
                    value: FuelUnits(),
                  ),
                  ChangeNotifierProvider.value(
                    value: Cars(),
                  ),
                  ChangeNotifierProvider.value(
                    value: Refuelings(),
                  ),
                ],
                child: MaterialApp(
                  supportedLocales: [
                    const Locale('en'),
                    // const Locale('pl'),
                  ],
                  title: 'Car cash',
                  theme: ThemeData(
                    primarySwatch: Colors.blue,
                  ),
                  home: Consumer<Cars>(
                    builder: (ctx, cars, child) => FutureBuilder(
                      future: cars.fetchCars(),
                      builder: (c, data) =>
                          data.connectionState == ConnectionState.waiting
                              ? Center(child: CircularProgressIndicator())
                              : cars.keys?.length == 0
                                  ? AddCarScreen.mainScreen()
                                  : ExpenseListScreen(),
                    ),
                  ),
                  routes: Routes.routes,
                ),
              ));
  }
}
