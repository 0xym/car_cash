import 'package:carsh/model/car.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/localization.dart';
import '../model/preferences.dart';
import '../providers/cars.dart';
import '../widgets/car_item.dart';
import './add_car_screen.dart';

class CarListScreen extends StatelessWidget {
  static const routeName = '/car-list';
  final _prefs = Preferences();

  @override
  Widget build(BuildContext context) {
    final loc = Localization.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.tr('carsTitle')),
      ),
      body: FutureBuilder(
        future: Provider.of<Cars>(context).fetchCars(),
        builder: (ctx, data) => data.connectionState == ConnectionState.waiting
            ? Center(
                child: CircularProgressIndicator(),
              )
            : Consumer<Cars>(
                builder: (ctx, cars, child) => CarListView(_prefs, cars),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.of(context).pushNamed(AddCarScreen.routeName),
        child: Icon(Icons.add),
      ),
    );
  }
}

class CarListView extends StatefulWidget {
  CarListView(Preferences prefs, Cars cars)
      : _prefs = prefs,
        _cars = cars;

  final Preferences _prefs;
  final Cars _cars;

  @override
  _CarListViewState createState() => _CarListViewState(_prefs.get(DEFAULT_CAR));
}

class _CarListViewState extends State<CarListView> {
  _CarListViewState(int defaultCar) : defaultCar = defaultCar;
  int defaultCar;

  void setDefaultCar(int id) {
    widget._prefs.set(DEFAULT_CAR, id);
    setState(() => defaultCar = id);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: widget._cars.cars!
          .map((e) => CarItem(e, defaultCar, setDefaultCar))
          .toList(),
    );
  }
}
