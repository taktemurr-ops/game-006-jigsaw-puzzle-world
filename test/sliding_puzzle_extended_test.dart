import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_006_jigsaw_puzzle_world/game/sliding_puzzle.dart';

void main() {
  test('shuffled boards retain all values with no undo history', () {
    for (var size=2;size<=6;size++) {
      final game = SlidingPuzzle(size: size)..shuffle(steps: 100, random: Random(size));
      expect(game.tiles.toSet().length, size*size);
      expect(game.moves, 0);
      expect(game.canUndo, isFalse);
      expect(game.solved, isFalse);
    }
  });
  test('invalid index, undo, and winning sequence work', () {
    final game = SlidingPuzzle();
    expect(game.move(0), isFalse);
    expect(game.move(7), isTrue);
    expect(game.canUndo, isTrue);
    expect(game.undo(), isTrue);
    expect(game.solved, isTrue);
  });
}
