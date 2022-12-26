import 'package:carsh/adapters/refueling_adapter.dart';
import 'package:carsh/l10n/localization.dart';
import 'package:carsh/providers/expenditures.dart';
import 'package:flutter/cupertino.dart';

import '../l10n/localization.dart';
import 'common.dart';

class DataValidator {
  final BuildContext context;

  DataValidator(this.context);

  String? _validatePositiveValue(double parsed, Localization loc) =>
      parsed <= 0.0 ? loc.tr('errorMustBePositive') : null;

  String? _validateNonNegativeValue(double parsed, Localization loc) =>
      parsed < 0.0 ? loc.tr('errorMustBePositive') : null;

  String? validateNumber(String? value) =>
      _validateNumber(value, _validatePositiveValue);
  String? validateNonNegativeNumber(String? value) =>
      _validateNumber(value, _validateNonNegativeValue);

  String? _validateNumber(
      String? value, String? valueValidator(double v, Localization l)) {
    final loc = Localization.of(context);
    double? parsed = value == null ? null : toDouble(value);
    return value?.isEmpty ?? true
        ? loc.tr('errorValueEmpty')
        : parsed == null
            ? loc.tr('errorInvalidNumber')
            : valueValidator(parsed, loc);
  }

  String? validateRefuelingDistance(String? value, MileageType mileageType,
      RefuelingAdapter refuelingAdapter, Expenditures refuelings) {
    final thisIsFirstRefueling =
        refuelings.previousRefuelingIndexOfCar(refuelingAdapter.get()) == -1;
    final preValidation = thisIsFirstRefueling
        ? validateNonNegativeNumber(value)
        : validateNumber(value);
    if (mileageType == MileageType.Trip || preValidation != null) {
      return preValidation;
    }
    final minMax = refuelings.sorouningRefuelingData(
        refuelingAdapter.get(), refuelingAdapter.car!.initialMileage!);
    final minValue = minMax.prevMileage;
    final maxValue = minMax.nextMileage;
    return (toDouble(value)! < minValue) ||
            (maxValue != null && toDouble(value)! > maxValue)
        ? 'Must be greater than ${refuelingAdapter.displayedDistance(minValue)}${maxValue == null ? "" : " and smaller than " + refuelingAdapter.displayedDistance(maxValue).toString()}'
        : null;
  }
}
