double toDouble(String value) {
  return double.tryParse(value.replaceAll(',', '.'));
}

DateTime today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
}

String nullify(String value) {
  return value == null ? value : value.isEmpty ? null : value;
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
