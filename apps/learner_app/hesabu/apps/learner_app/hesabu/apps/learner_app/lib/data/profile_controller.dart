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

/// The learner's buddy and nickname. Stored on this device only.
/// We never ask for a real name, email or any account.
class ProfileController extends ChangeNotifier {
  ProfileController(this._prefs)
      : _nickname = sanitizeNickname(_prefs.getString(_kNick) ?? ''),
        _mascot = MascotKind.values.asNameMap()[_prefs.getString(_kMascot)] ??
            MascotKind.tembo,
        _onboarded = _prefs.getBool(_kDone) ?? false;

  static const _kNick = 'profile.nickname';
  static const _kMascot = 'profile.mascot';
  static const _kDone = 'profile.onboarded';

  final SharedPreferences _prefs;
  String _nickname;
  MascotKind _mascot;
  bool _onboarded;

  String get nickname => _nickname;
  MascotKind get mascot => _mascot;
  bool get onboarded => _onboarded;

  /// Name shown in greetings; friendly default when none was chosen.
  String get displayName => _nickname.isEmpty ? 'Champion' : _nickname;

  Future<void> save({required String nickname, required MascotKind mascot}) async {
    _nickname = sanitizeNickname(nickname);
    _mascot = mascot;
    notifyListeners();
    await _prefs.setString(_kNick, _nickname);
    await _prefs.setString(_kMascot, mascot.name);
  }

  Future<void> completeOnboarding({
    required String nickname,
    required MascotKind mascot,
  }) async {
    _onboarded = true;
    await save(nickname: nickname, mascot: mascot);
    await _prefs.setBool(_kDone, true);
  }

  Future<void> replayWelcome() async {
    _onboarded = false;
    notifyListeners();
    await _prefs.setBool(_kDone, false);
  }
}
