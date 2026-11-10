import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mascot/mascot_kind.dart';

/// Keep nicknames short, simple and safe: letters, digits, spaces, ' and -.
String sanitizeNickname(String raw) {
  final cleaned = raw
      .replaceAll(RegExp(r"[^A-Za-z0-9 '\-]"), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return cleaned.length <= 16 ? cleaned : cleaned.substring(0, 16).trim();
}

/// The learner's buddy, nickname, and the grade they are practising.
/// Stored on this device only: no accounts, no personal data.
class ProfileController extends ChangeNotifier {
  ProfileController(this._prefs)
      : _nickname = sanitizeNickname(_prefs.getString(_kNick) ?? ''),
        _mascot = MascotKind.values.asNameMap()[_prefs.getString(_kMascot)] ?? MascotKind.tembo,
        _onboarded = _prefs.getBool(_kDone) ?? false,
        _grade = _loadGrade(_prefs.getString(_kGrade)) ?? 'grade4';

  static const _kNick = 'profile.nickname';
  static const _kMascot = 'profile.mascot';
  static const _kDone = 'profile.onboarded';
  static const _kGrade = 'profile.grade';

  static String? _loadGrade(String? raw) {
    if (raw == null) return null;
    final normalized = raw.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    if (normalized == 'grade5' || normalized == 'g5' || normalized == '5') return 'grade5';
    if (normalized == 'grade6' || normalized == 'g6' || normalized == '6') return 'grade6';
    return null;
  }

  final SharedPreferences _prefs;
  String _nickname;
  MascotKind _mascot;
  bool _onboarded;
  String _grade;

  String get grade => _grade;

  String get nickname => _nickname;
  MascotKind get mascot => _mascot;
  bool get onboarded => _onboarded;

  String get displayName => _nickname.isEmpty ? 'Champion' : _nickname;

  Future<void> save({required String nickname, required MascotKind mascot}) async {
    _nickname = sanitizeNickname(nickname);
    _mascot = mascot;
    notifyListeners();
    await _prefs.setString(_kNick, _nickname);
    await _prefs.setString(_kMascot, mascot.name);
  }

  Future<void> completeOnboarding({required String nickname, required MascotKind mascot}) async {
    _onboarded = true;
    await save(nickname: nickname, mascot: mascot);
    await _prefs.setBool(_kDone, true);
  }

  /// Switch the learner to a different grade (e.g. Grade 4 -> Grade 5).
  Future<void> setGrade(String grade) async {
    if (grade == _grade) return;
    _grade = grade;
    await _prefs.setString(_kGrade, grade);
    notifyListeners();
  }

  /// Reset the grade to its default (Grade 4).
  Future<void> resetGradeToDefault() async {
    if (_grade == 'grade4') return;
    _grade = 'grade4';
    await _prefs.remove(_kGrade);
    notifyListeners();
  }

  Future<void> replayWelcome() async {
    _onboarded = false;
    notifyListeners();
    await _prefs.setBool(_kDone, false);
  }
}
