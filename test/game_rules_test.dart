import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/core/level_plan.dart';
import 'package:game_006_jigsaw_puzzle_world/game/jigsaw_engine.dart';
import 'package:game_006_jigsaw_puzzle_world/game/rules.dart';

void main() {
  final rules = JigsawRules();
  final planner = LevelPlanner(gameId: rules.gameId, optionalMechanics: rules.optionalMechanics);

  test('swap puzzles are solved by auto-placing every piece', () {
    final l = rules.build(planner.spec(10).copyWith(mechanics: const [])).puzzle;
    expect(l.kind, PuzzleKind.swap);
    final g = JigsawGame(l);
    var guard = 0;
    while (!g.won && guard++ < 200) {
      g.autoPlace();
    }
    expect(g.won, isTrue);
  });

  test('rotate puzzles need correct rotation too', () {
    final l = rules.build(planner.spec(30).copyWith(mechanics: const ['rotate'])).puzzle;
    final g = JigsawGame(l);
    while (g.autoPlace() != null) {}
    expect(g.won, isTrue);
    g.rotate(0);
    expect(g.won, isFalse);
    g.undo();
    expect(g.won, isTrue);
  });

  test('slide puzzles: only neighbours of the gap move, always solvable', () {
    for (var n = 1; n <= 60; n++) {
      final g = rules.build(planner.spec(n * 13).copyWith(mechanics: const ['slide']));
      expect(g.validation.ok, isTrue);
      expect(g.puzzle.kind, PuzzleKind.slide);
    }
    final game = JigsawGame(rules.build(planner.spec(77).copyWith(mechanics: const ['slide'])).puzzle);
    final e = game.emptyPos;
    final far = (e + game.level.count ~/ 2 + 1) % game.level.count;
    if (!game.canSlide(far)) expect(game.slide(far), isFalse);
  });

  test('resume restores state', () {
    final l = rules.build(planner.spec(44)).puzzle;
    final g = JigsawGame(l)..autoPlace();
    expect(JigsawGame.restore(l, g.serialize()).serialize(), g.serialize());
  });

  test('levels 1..300 valid', () {
    for (var n = 1; n <= 300; n++) {
      expect(rules.build(planner.spec(n)).validation.ok, isTrue, reason: 'level $n');
    }
  });
}
