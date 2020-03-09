import 'package:car_cash/adapters/refueling_adapter.dart';
import 'package:car_cash/l10n/localization.dart';
import 'package:car_cash/providers/refuelings.dart';
import 'package:car_cash/screens/add_expense_screen.dart';
import 'package:flutter/cupertino.dart';

import 'common.dart';

class DataValidator {
  final BuildContext context;

  DataValidator(this.context);

  String validateNumber(String value) {
    final loc = Localization.of(context);
    double parsed = toDouble(value);
    return value.isEmpty
        ? loc.tr('errorValueEmpty')
        : parsed == null
            ? loc.tr('errorInvalidNumber')
            : parsed <= 0.0 ? loc.tr('errorMustBePositive') : null;
  }

  String validateRefuelingDistance(String value, MileageType mileageType,
      RefuelingAdapter refuelingAdapter, Refuelings refuelings) {
    final preValidation = validateNumber(value);
    if (mileageType == MileageType.Trip || preValidation != null) {
      return preValidation;
    }
    final minMax = refuelings.sorouningRefuelingData(
        refuelingAdapter.get(), refuelingAdapter.car.initialMileage);
    final minValue = minMax.prevMileage;
    final maxValue = minMax.nextMileage;
    return (toDouble(value) < minValue) ||
            (maxValue != null && toDouble(value) > maxValue)
        ? 'Must be greater than ${refuelingAdapter.displayedDistance(minValue)}${maxValue == null ? "" : " and smaller than " + refuelingAdapter.displayedDistance(maxValue).toString()}'
        : null;
  }
}
