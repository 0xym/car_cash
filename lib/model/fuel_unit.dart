enum UnitType { Energy, Mass, Volume 
}

UnitType unitTypeFromString(String unitType) {
  for (UnitType element in UnitType.values) {
    if (element.toString() == unitType) {
      return element;
    }
  }
  return null;
}

class FuelUnit {
  int id;
  UnitType unitType;
  double conversionFactor;//to SI unit
  String name;

  FuelUnit(this.id, this.name, this.unitType, this.conversionFactor);
}