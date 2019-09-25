import 'package:flutter/material.dart';
import '../model/car.dart';
import '../screens/add_car_screen.dart';

class CarItem extends StatelessWidget {
  final Car _car;
  CarItem(this._car);
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text('Id: ${_car.id}'),
      title: Text(_car.name), 
      subtitle: _car.brandAndModel == null ? null : Text(_car.brandAndModel),
      onTap: () => Navigator.of(context).pushNamed(AddCarScreen.routeName, arguments: _car),
    );
  }
}