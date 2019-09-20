double toDouble(String value) {
  return double.tryParse(value.replaceAll(',', '.'));
}