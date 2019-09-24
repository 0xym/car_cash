double toDouble(String value) {
  return double.tryParse(value.replaceAll(',', '.'));
}

class EnumParser<T> {
  final List<T> values;
  EnumParser(this.values);

  T fromString(String value) {
    for (T element in values) {
      if (element.toString() == value) {
        return element;
      }
    }
    return null;
  }
}
