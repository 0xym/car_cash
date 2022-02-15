import 'package:flutter/material.dart';
import '../model/car.dart';
import '../screens/add_car_screen.dart';

class CarItem extends StatelessWidget {
  final Car _car;
  final int _defaultCar;
  final Function _setDefault;
  CarItem(this._car, this._defaultCar, this._setDefault);
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconButton(
        icon: Icon(_car.id == _defaultCar
            ? Icons.radio_button_checked
            : Icons.radio_button_unchecked),
        onPressed: () => _setDefault(_car.id),
      ),
      title: Text(_car.name!),
      subtitle: _car.brandAndModel == null ? null : Text(_car.brandAndModel!),
      trailing: CircleAvatar(
        backgroundColor: _car.color,
      ),
      onTap: () => Navigator.of(context)
          .pushNamed(AddCarScreen.routeName, arguments: _car),
    );
  }
}
