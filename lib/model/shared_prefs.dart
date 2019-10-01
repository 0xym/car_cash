import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static SharedPreferences _prefs;
  static SharedPreferences get()  {
    if (_prefs == null) {
      throw Exception();//todo add custom exception
    }
    return _prefs;
  }

  static aget() async {
    _prefs = await SharedPreferences.getInstance();
  }
}