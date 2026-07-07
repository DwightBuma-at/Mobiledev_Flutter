import 'package:shared_preferences/shared_preferences.dart';

class StorageBackend {
  StorageBackend._(this._prefs);

  final SharedPreferences _prefs;

  static Future<StorageBackend> create() async {
    return StorageBackend._(await SharedPreferences.getInstance());
  }

  bool containsKey(String key) => _prefs.containsKey(key);

  String? getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
}
