import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-facing look settings, stored on the device.
class ThemeController extends ChangeNotifier {
  ThemeController(this._prefs)
      : _mode = ThemeMode.values.asNameMap()[_prefs.getString(_kMode)] ??
            ThemeMode.system,
        _largeText = _prefs.getBool(_kLarge) ?? false;

  static const _kMode = 'theme.mode';
  static const _kLarge = 'theme.largeText';

  final SharedPreferences _prefs;
  ThemeMode _mode;
  bool _largeText;

  ThemeMode get mode => _mode;
  bool get largeText => _largeText;

  /// Extra text scale applied on top of the system setting.
  double get extraTextScale => _largeText ? 1.2 : 1.0;

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    await _prefs.setString(_kMode, mode.name);
  }

  Future<void> setLargeText(bool value) async {
    _largeText = value;
    notifyListeners();
    await _prefs.setBool(_kLarge, value);
  }
}
