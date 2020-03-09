import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/localization.dart';
import '../providers/fuel_types.dart';
import '../providers/fuel_units.dart';

class FuelTypeSelectionWidget extends StatelessWidget {
  final int fuelIndex;
  final int selectedType;
  final int selectedUnit;
  final Function onChange;
  final Function onDeleted;

  FuelTypeSelectionWidget(
      {this.fuelIndex,
      this.onChange,
      this.onDeleted,
      this.selectedType,
      this.selectedUnit});

  @override
  Widget build(BuildContext context) {
    final fuelTypes = Provider.of<FuelTypes>(context, listen: false);
    final fuelUnits = Provider.of<FuelUnits>(context, listen: false);
    final getValidUnit = (int value) {
      final oldUnitType =
          selectedType != null ? fuelTypes.get(selectedType).unitType : null;
      final newUnitType = fuelTypes.get(value).unitType;
      return oldUnitType == newUnitType
          ? selectedUnit
          : fuelUnits.firstWhere(newUnitType);
    };
    final loc = Localization.of(context);
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
                child: DropdownButtonFormField<int>(
              decoration: InputDecoration(
                  labelText: "${loc.tr('fuelType')} (${fuelIndex + 1})"),
              onChanged: (value) =>
                  onChange(fuelIndex, value, getValidUnit(value)),
              value: selectedType,
              items: fuelTypes.keys
                  .map((fuel) => DropdownMenuItem(
                        value: fuel,
                        child: Text(loc.ttr(fuelTypes.get(fuel).name)),
                      ))
                  .toList(),
            )),
            if (onDeleted != null)
              IconButton(
                icon: Icon(Icons.remove_circle),
                onPressed: () => onDeleted(fuelIndex),
                color: Theme.of(context).accentColor,
              ),
          ],
        ),
        DropdownButtonFormField<int>(
          decoration: InputDecoration(
              labelText: "${loc.tr('unit')} (${fuelIndex + 1})"),
          value: selectedUnit,
          onChanged: (value) => onChange(fuelIndex, selectedType, value),
          validator: (value) => selectedType != null && selectedUnit == null
              ? 'error'
              : null, //this sould not happen
          items: selectedType == null
              ? null
              : fuelUnits
                  .keysWhere(fuelTypes.get(selectedType).unitType)
                  .map((fuel) => DropdownMenuItem(
                        value: fuel,
                        child: Text(loc.ttr(fuelUnits.get(fuel).name)),
                      ))
                  .toList(),
        )
      ],
    );
  }
}
