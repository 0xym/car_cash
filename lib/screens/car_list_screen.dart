import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/localization.dart';
import '../providers/cars.dart';
import '../widgets/car_item.dart';
import './add_car_screen.dart';

class CarListScreen extends StatelessWidget {
  static const routeName = '/car-list';

  @override
  Widget build(BuildContext context) {
    final loc = Localization.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.tr('carsTitle')),),
      body: FutureBuilder(future: Provider.of<Cars>(context).fetchCars(),
        builder: (ctx, data) => data.connectionState == ConnectionState.waiting ? Center(child: CircularProgressIndicator(),) : 
          Consumer<Cars>(builder: (ctx, cars, child) => ListView.builder(itemCount: cars.keys.length, itemBuilder: (c, idx) => 
          CarItem(cars.get(cars.keys.toList()[idx])),),),),

      floatingActionButton: FloatingActionButton(onPressed: () => Navigator.of(context).pushNamed(AddCarScreen.routeName), child: Icon(Icons.add),),
    );
  }
}