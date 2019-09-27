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
  final int id;
  final UnitType unitType;
  final double conversionFactor;//to SI unit
  final String name;

  FuelUnit(this.id, this.name, this.unitType, this.conversionFactor);
}