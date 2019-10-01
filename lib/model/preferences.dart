import 'package:shared_preferences/shared_preferences.dart';
import './shared_prefs.dart';

abstract class Access<T> {
  T get(SharedPreferences prefs, String name);
  set(SharedPreferences prefs, String name, T value);
}

class StringAccess implements Access<String> {
  const StringAccess();
  String get(SharedPreferences _prefs, String name) => _prefs.getString(name);
  set(SharedPreferences _prefs, String name, String value) async => await _prefs.setString(name, value);
}

class Preference {
  static const _access = {String: StringAccess()};
  final String name;
  final Type type;
  final dynamic defaultValue;
  get access => _access[type];
  const Preference(this.name, this.type, [this.defaultValue]);
}

class Preferences {
  final SharedPreferences _prefs;
  Preferences() : _prefs = SharedPrefs.get();

  _get(Preference pref) => pref.access.get(_prefs, pref.name);
  _set(Preference pref, dynamic value) {set(pref, value); return value;}
  get(Preference pref) => _get(pref) ?? _set(pref, pref.defaultValue);
  void set(Preference pref, dynamic value) => pref.access.set(_prefs, pref.name, value);
}