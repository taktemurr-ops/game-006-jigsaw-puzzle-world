import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const JigsawApp());

/// A sliding picture puzzle. Zero represents the empty tile.
class SlidingPuzzle {
  SlidingPuzzle({this.size = 3})
      : assert(size >= 2),
        tiles = List.generate(size * size, (i) => (i + 1) % (size * size));
  final int size;
  final List<int> tiles;
  int moves = 0;

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
    final empty = tiles.indexOf(0);
    tiles[empty] = tiles[index];
    tiles[index] = 0;
    moves++;
    return true;
  }

  /// Shuffle by valid moves so every generated board is solvable.
  void shuffle({int steps = 100, Random? random}) {
    final rng = random ?? Random();
    var previousEmpty = -1;
    for (var i = 0; i < steps; i++) {
      final empty = tiles.indexOf(0);
      final options = [
        for (var j = 0; j < tiles.length; j++)
          if (canMove(j) && j != previousEmpty) j,
      ];
      if (options.isEmpty) continue;
      final chosen = options[rng.nextInt(options.length)];
      move(chosen);
      previousEmpty = empty;
    }
    moves = 0;
  }
}

class JigsawApp extends StatelessWidget {
  const JigsawApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Jigsaw Puzzle World',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
        home: const PuzzleScreen(),
      );
}

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});
  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  late SlidingPuzzle puzzle = SlidingPuzzle()..shuffle();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Jigsaw Puzzle World')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Slide tiles into order to complete the puzzle.'),
                const SizedBox(height: 16),
                Text('Moves: ${puzzle.moves}', key: const ValueKey('moves')),
                if (puzzle.solved)
                  const Text('Puzzle completed!', key: ValueKey('completed')),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: puzzle.size,
                      ),
                      itemCount: puzzle.tiles.length,
                      itemBuilder: (context, index) {
                        final number = puzzle.tiles[index];
                        return Padding(
                          padding: const EdgeInsets.all(3),
                          child: number == 0
                              ? const ColoredBox(color: Color(0xFFE0F2F1))
                              : FilledButton(
                                  key: ValueKey('tile-$number'),
                                  onPressed: puzzle.canMove(index)
                                      ? () => setState(() => puzzle.move(index))
                                      : null,
                                  child: Text('$number',
                                      style: const TextStyle(fontSize: 28)),
                                ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => setState(() => puzzle.shuffle()),
                  icon: const Icon(Icons.shuffle),
                  label: const Text('New puzzle'),
                ),
              ]),
            ),
          ),
        ),
      );
}
