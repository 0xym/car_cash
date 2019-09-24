import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes.dart';
import './providers/refuelings.dart';
import './providers/fuel_types.dart';
import './providers/fuel_units.dart';
import './providers/cars.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: FuelTypes() ,),
        ChangeNotifierProvider.value(value: FuelUnits() ,),
        ChangeNotifierProvider.value(value: Refuelings() ,),
        ChangeNotifierProvider.value(value: Cars() ,),
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
        routes: Routes.routes,
      ),
    );
  }
}