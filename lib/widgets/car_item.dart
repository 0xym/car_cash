import 'package:flutter/material.dart';
import '../model/car.dart';

class CarItem extends StatelessWidget {
  final Car _car;
  CarItem(this._car);
  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(_car.name), subtitle: _car.brandAndModel == null ? null : Text(_car.brandAndModel),
    );
  }
}