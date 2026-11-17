import 'dart:math';

/// Standard sliding tile puzzle, retained as an independent game mode.
/// Every shuffle is composed of legal moves, so solvability is guaranteed.
class SlidingPuzzle {
  SlidingPuzzle({this.size = 3})
      : assert(size >= 2 && size <= 6),
        tiles = List.generate(size * size, (i) => (i + 1) % (size * size));
  final int size;
  final List<int> tiles;
  final List<List<int>> _history = [];
  int moves = 0;
  bool get canUndo => _history.isNotEmpty;

  bool get solved {
    for (var i = 0; i < tiles.length; i++) {
      if (tiles[i] != (i + 1) % tiles.length) return false;
    }
    return true;
  }

  bool canMove(int index) {
    if (index < 0 || index >= tiles.length) return false;
    final empty = tiles.indexOf(0);
    return (index ~/ size == empty ~/ size &&
            (index % size - empty % size).abs() == 1) ||
        (index % size == empty % size &&
            (index ~/ size - empty ~/ size).abs() == 1);
  }

  bool move(int index) {
    if (!canMove(index)) return false;
    _history.add(List<int>.of(tiles));
    if (_history.length > 30) _history.removeAt(0);
    final empty = tiles.indexOf(0);
    tiles[empty] = tiles[index];
    tiles[index] = 0;
    moves++;
    return true;
  }

  void shuffle({int steps = 100, Random? random}) {
    final rng = random ?? Random();
    for (var i = 0; i < tiles.length; i++) tiles[i] = (i + 1) % tiles.length;
    _history.clear();
    var previousEmpty = -1;
    for (var i = 0; i < steps; i++) {
      final empty = tiles.indexOf(0);
      final options = [for (var j = 0; j < tiles.length; j++) if (canMove(j) && j != previousEmpty) j];
      if (options.isEmpty) continue;
      final chosen = options[rng.nextInt(options.length)];
      move(chosen);
      previousEmpty = empty;
    }
    if (solved && steps > 0) move(size * size - 2);
    _history.clear();
    moves = 0;
  }

  bool undo() {
    if (_history.isEmpty) return false;
    tiles.setAll(0, _history.removeLast());
    moves = max(0, moves - 1);
    return true;
  }
}
