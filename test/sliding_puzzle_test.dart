import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_006_jigsaw_puzzle_world/main.dart';

void main() {
  test('starts solved and only adjacent tiles move', () {
    final puzzle = SlidingPuzzle();
    expect(puzzle.solved, isTrue);
    expect(puzzle.canMove(7), isTrue);
    expect(puzzle.canMove(5), isTrue);
    expect(puzzle.canMove(0), isFalse);
    expect(puzzle.move(0), isFalse);
    expect(puzzle.move(7), isTrue);
    expect(puzzle.moves, 1);
    expect(puzzle.solved, isFalse);
    expect(puzzle.move(8), isTrue);
    expect(puzzle.solved, isTrue);
  });

  test('shuffling preserves tile set and reset move count', () {
    final puzzle = SlidingPuzzle();
    puzzle.shuffle(steps: 150, random: Random(42));
    expect(puzzle.tiles.toSet(), equals(Set<int>.from(List.generate(9, (i) => i))));
    expect(puzzle.moves, 0);
    expect(puzzle.solved, isFalse);
  });
}
