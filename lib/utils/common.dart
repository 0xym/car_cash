double? toDouble(String? value) {
  return value == null ? null : double.tryParse(value.replaceAll(',', '.'));
}

String valueToText(double? value, int precision) {
  if (value == null) return '';
  return value.toStringAsFixed(precision);
}

String withoutTrailingZeros(String text) {
  while (text.endsWith('0')) text = text.substring(0, text.length - 1);
  if (text.endsWith('.')) text = text.substring(0, text.length - 1);
  return text;
}

DateTime today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
}

String? nullify(String? value) {
  return value == null
      ? value
      : value.isEmpty
          ? null
          : value;
}

class EnumParser<T> {
  final List<T> values;
  EnumParser(this.values);

  T? fromString(String value) {
    for (T element in values) {
      if (element.toString() == value) {
        return element;
      }
    }
    return null;
  }
}

extension NullAware<T> on Iterable<T> {
  T? firstWhereOrNull(bool test(T element)) {
    for (T element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
