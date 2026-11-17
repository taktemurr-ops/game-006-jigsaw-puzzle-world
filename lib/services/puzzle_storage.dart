import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/jigsaw_game.dart';

/// All progress is local by default. No account, network or analytics SDK.
class PuzzlePreferences {
  PuzzlePreferences({this.language = 'tr', this.showNumbers = false,
      this.sound = false, this.reducedMotion = false, this.bestMoves = const {}});
  String language;
  bool showNumbers;
  bool sound;
  bool reducedMotion;
  final Map<String, int> bestMoves;

  Map<String, Object?> toJson() => {
    'language': language, 'showNumbers': showNumbers,
    'sound': sound, 'reducedMotion': reducedMotion,
    'bestMoves': bestMoves,
  };

  static PuzzlePreferences fromJson(Map<String, dynamic> raw) {
    final scores = <String, int>{};
    if (raw['bestMoves'] is Map) {
      for (final entry in (raw['bestMoves'] as Map).entries) {
        if (entry.key is String && entry.value is int && entry.value >= 0) {
          scores[entry.key as String] = entry.value as int;
        }
      }
    }
    final lang = raw['language'];
    return PuzzlePreferences(
      language: ['tr', 'en', 'ar'].contains(lang) ? lang as String : 'tr',
      showNumbers: raw['showNumbers'] == true,
      sound: raw['sound'] == true,
      reducedMotion: raw['reducedMotion'] == true,
      bestMoves: scores,
    );
  }

  void registerWin(JigsawGame game) {
    if (!game.solved) return;
    final key = '${game.mode.name}_${game.art.name}_${game.size}';
    final previous = bestMoves[key];
    if (previous == null || game.moves < previous) bestMoves[key] = game.moves;
  }
}

abstract class PuzzleStorage {
  Future<JigsawGame?> readGame();
  Future<PuzzlePreferences> readPreferences();
  Future<void> save(JigsawGame game, PuzzlePreferences preferences);
  Future<void> clear();
}

class LocalPuzzleStorage implements PuzzleStorage {
  static const _gameKey = 'jigsaw_game_v1';
  static const _prefsKey = 'jigsaw_preferences_v1';

  @override
  Future<JigsawGame?> readGame() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_gameKey);
      if (raw == null) return null;
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) return null;
      return JigsawGame.fromJson(data);
    } catch (_) {
      // Corrupted saves must never crash the game.
      return null;
    }
  }

  @override
  Future<PuzzlePreferences> readPreferences() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_prefsKey);
      if (raw == null) return PuzzlePreferences();
      final data = jsonDecode(raw);
      return data is Map<String, dynamic>
          ? PuzzlePreferences.fromJson(data) : PuzzlePreferences();
    } catch (_) { return PuzzlePreferences(); }
  }

  @override
  Future<void> save(JigsawGame game, PuzzlePreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gameKey, jsonEncode(game.toJson()));
    await prefs.setString(_prefsKey, jsonEncode(preferences.toJson()));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_gameKey);
    await prefs.remove(_prefsKey);
  }
}
