import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_006_jigsaw_puzzle_world/main.dart';

void main() {
  test('solved board only accepts adjacent moves', () {
    final board = SlidingPuzzle();
    expect(board.solved, isTrue);
    expect(board.canMove(7), isTrue);
    expect(board.canMove(5), isTrue);
    expect(board.canMove(0), isFalse);
    expect(board.move(0), isFalse);
    expect(board.moves, 0);
    expect(board.move(7), isTrue);
    expect(board.solved, isFalse);
    expect(board.moves, 1);
    expect(board.move(8), isTrue);
    expect(board.solved, isTrue);
  });

  test('shuffle produces valid tile permutation with reset counter', () {
    final board = SlidingPuzzle(size: 4);
    board.shuffle(steps: 75, random: Random(7));
    expect(board.tiles.toSet().length, 16);
    expect(board.tiles.toSet(), Set<int>.from(List.generate(16, (i) => i)));
    expect(board.moves, 0);
    expect(board.canMove(-1), isFalse);
    expect(board.canMove(16), isFalse);
  });
}
