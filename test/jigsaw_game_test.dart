import 'package:flutter_test/flutter_test.dart';
import 'package:game_006_jigsaw_puzzle_world/game/jigsaw_game.dart';

void main() {
  group('JigsawGame', () {
    test('a seeded puzzle is deterministic, shuffled and has all tiles', () {
      final one = JigsawGame(size: 4, seed: 11);
      final two = JigsawGame(size: 4, seed: 11);
      expect(one.pieces, two.pieces);
      expect(one.solved, isFalse);
      expect(one.pieces.toSet(), Set.of(List.generate(16, (i) => i)));
    });
    test('swap, undo, solved status, hint never mutates', () {
      final g = JigsawGame(size: 3, seed: 4);
      final before = List<int>.of(g.pieces);
      final hint = g.hint;
      expect(hint, isNotNull);
      expect(g.pieces, before);
      expect(g.swap(0, 0), isFalse);
      expect(g.swap(-1, 1), isFalse);
      expect(g.swap(0, 1), isTrue);
      expect(g.moves, 1);
      expect(g.undo(), isTrue);
      expect(g.pieces, before);
      expect(g.moves, 0);
      expect(g.undo(), isFalse);
    });
    test('hint eventually completes every mixed permutation', () {
      for (final size in [2, 3, 4, 5, 6]) {
        final game = JigsawGame(size: size, seed: 103);
        var operations = 0;
        while (!game.solved && operations < size * size + 2) {
          expect(game.applyHint(), isTrue);
          operations++;
        }
        expect(game.solved, isTrue);
        expect(game.hintsUsed, operations);
      }
    });
    test('tap selects then swaps and pausing blocks edits and time', () {
      final g = JigsawGame(size: 3);
      expect(g.tap(0), isFalse);
      expect(g.selectedIndex, 0);
      expect(g.tap(1), isTrue);
      g.paused = true;
      expect(g.swap(1, 2), isFalse);
      expect(g.tap(2), isFalse);
      g.tick();
      expect(g.secondsElapsed, 0);
    });
    test('game state safely round trips; corrupt saves rejected', () {
      final original = JigsawGame(size: 4, seed: 32,
        mode: PuzzleMode.timed, art: ArtTheme.garden);
      original.swap(0, 2);
      original.tick();
      final restored = JigsawGame.fromJson(original.toJson());
      expect(restored.pieces, original.pieces);
      expect(restored.moves, original.moves);
      expect(restored.secondsElapsed, 1);
      expect(restored.art, ArtTheme.garden);
      expect(restored.canUndo, isFalse); // history is deliberately ephemeral
      final bad = Map<String, Object?>.from(original.toJson());
      bad['pieces'] = List.filled(16, 0);
      expect(() => JigsawGame.fromJson(bad), throwsFormatException);
    });
    test('UTC daily seed is reproducible', () {
      expect(JigsawGame.dailySeed(DateTime.utc(2026, 11, 17)), 20261117);
      expect(JigsawGame.dailySeed(DateTime.utc(2026, 11, 17, 23)), 20261117);
    });
    test('timed games stop on expiration', () {
      final g = JigsawGame(size: 2, mode: PuzzleMode.timed);
      for (var i = 0; i < g.timeLimitSeconds; i++) g.tick();
      expect(g.timedOut, isTrue);
      expect(g.swap(0, 1), isFalse);
      expect(g.remainingTime, 0);
    });
  });
}
