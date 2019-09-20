import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes.dart';
import './providers/refuelings.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: Refuelings(),
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