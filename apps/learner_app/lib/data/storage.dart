import 'dart:convert';

import 'package:content_pack/content_pack.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mastery_core/mastery_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Progress lives on the device only: no accounts, no personal data.
class ProgressStore {
  ProgressStore(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'progress.v1';

  Map<String, SkillProgress> load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) =>
        MapEntry(k, SkillProgress.fromJson(v as Map<String, dynamic>)));
  }

  Future<void> save(Map<String, SkillProgress> progress) => _prefs.setString(
        _key,
        jsonEncode(progress.map((k, v) => MapEntry(k, v.toJson()))),
      );
}

Future<ContentBundle> loadContent(String grade) async {
  Future<Map<String, dynamic>> read(String file) async => jsonDecode(
        await rootBundle.loadString('$contentRoot/$grade/$file'),
      ) as Map<String, dynamic>;

  final manifest = await read('manifest.json');
  final skills = await read(manifest['skills'] as String);
  final files = <Map<String, dynamic>>[
    for (final f in manifest['questions'] as List<dynamic>) await read(f as String),
  ];
  return ContentBundle.fromJson(skillsJson: skills, questionFiles: files);
}
