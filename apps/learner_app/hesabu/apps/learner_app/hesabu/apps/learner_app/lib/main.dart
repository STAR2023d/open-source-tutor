import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/profile_controller.dart';
import 'data/storage.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(HesabuApp(
    theme: ThemeController(prefs),
    profile: ProfileController(prefs),
    store: ProgressStore(prefs),
  ));
}
