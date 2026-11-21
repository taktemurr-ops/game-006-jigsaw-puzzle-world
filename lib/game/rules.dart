import 'package:studio_core/core/game_rules.dart';
import 'package:studio_core/core/level_plan.dart';
import 'package:studio_core/core/missions.dart';
import 'package:studio_core/core/stats.dart';
import 'jigsaw_engine.dart';

class JigsawRules extends GameRules<JigsawLevel> {
  @override
  String get gameId => 'game-006-jigsaw-puzzle-world';

  @override
  List<String> get optionalMechanics => const ['rotate', 'slide', 'timer'];

  @override
  List<GameModeId> get modes => const [
        GameModeId.campaign,
        GameModeId.endless,
        GameModeId.timeAttack,
        GameModeId.zen,
        GameModeId.daily,
        GameModeId.weekly,
        GameModeId.challenge,
      ];

  @override
  List<GameStat> get gameStats => const [
        GameStat('pieces_placed', 'Yerine oturan parça', 'Pieces placed', scale: 50),
        GameStat('pictures_done', 'Tamamlanan resim', 'Pictures completed', scale: 5),
        GameStat('slides', 'Kaydırma', 'Slides', scale: 100),
      ];

  @override
  List<MissionTemplate> get missionTemplates => const [
        MissionTemplate('pieces', 'pieces_placed', [40, 100, 200]),
        MissionTemplate('pictures', 'pictures_done', [3, 6, 10]),
      ];

  @override
  JigsawLevel generate(LevelSpec spec) => generateJigsaw(spec);

  @override
  Validation validate(JigsawLevel l, LevelSpec spec) {
    final n = l.count;
    if (l.start.length != n || l.start.toSet().length != n) return const Validation.fail('not a permutation');
    if (l.start.any((p) => p < 0 || p >= n)) return const Validation.fail('range');
    if (JigsawGame(l).won) return const Validation.fail('already solved');
    if (l.kind == PuzzleKind.slide) {
      // Solvability via permutation parity + blank row distance.
      var inv = 0;
      final tiles = l.start.where((p) => p != n - 1).toList();
      for (var i = 0; i < tiles.length; i++) {
        for (var j = i + 1; j < tiles.length; j++) {
          if (tiles[i] > tiles[j]) inv++;
        }
      }
      final e = l.start.indexOf(n - 1);
      final blankRowFromBottom = l.rows - e ~/ l.cols;
      final solvable = l.cols.isOdd ? inv.isEven : (inv + blankRowFromBottom).isOdd;
      if (!solvable) return const Validation.fail('unsolvable slide');
    }
    return Validation.ok(n);
  }

  static int stars(JigsawGame g) {
    if (!g.won) return 0;
    final n = g.level.count;
    final par = switch (g.level.kind) {
      PuzzleKind.swap => n,
      PuzzleKind.rotate => n * 2,
      PuzzleKind.slide => g.level.scramble,
    };
    if (g.moves <= par) return 3;
    if (g.moves <= (par * 1.6).ceil()) return 2;
    return 1;
  }
}

GameRules createRules() => JigsawRules();
