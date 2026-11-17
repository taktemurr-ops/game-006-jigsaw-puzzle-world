import 'dart:math';

/// These modes never need a network connection. Daily puzzles use a UTC seed.
enum PuzzleMode { classic, timed, zen, daily }

enum ArtTheme { mountains, ocean, garden, sunset }

/// Logical image-piece reassembly board. Pieces are identified by their
/// position in the original picture and swapped by touch/keyboard controls.
/// No copyrighted photos or external resources are required.
class JigsawGame {
  JigsawGame({
    required this.size,
    this.seed = 1,
    this.mode = PuzzleMode.classic,
    this.art = ArtTheme.mountains,
    bool shuffle = true,
  }) : assert(size >= 2 && size <= 6),
       pieces = List<int>.generate(size * size, (i) => i) {
    if (size < 2 || size > 6) throw ArgumentError.value(size, 'size');
    if (shuffle) scramble();
  }

  final int size;
  final int seed;
  final PuzzleMode mode;
  final ArtTheme art;
  final List<int> pieces;
  final List<List<int>> _history = [];
  int moves = 0;
  int hintsUsed = 0;
  int secondsElapsed = 0;
  int? selectedIndex;
  bool paused = false;

  bool get solved {
    for (var i = 0; i < pieces.length; i++) {
      if (pieces[i] != i) return false;
    }
    return true;
  }

  bool get canUndo => _history.isNotEmpty;
  int get correctlyPlaced => [for (var i = 0; i < pieces.length; i++) if (pieces[i] == i) i].length;
  int get timeLimitSeconds => switch (size) {
    2 => 90,
    3 => 180,
    4 => 330,
    5 => 540,
    _ => 720,
  };
  bool get timedOut => mode == PuzzleMode.timed && secondsElapsed >= timeLimitSeconds && !solved;
  bool get finished => solved || timedOut;
  int get remainingTime => max(0, timeLimitSeconds - secondsElapsed);

  void scramble() {
    final rng = Random(seed);
    for (var i = pieces.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = pieces[i];
      pieces[i] = pieces[j];
      pieces[j] = tmp;
    }
    if (solved) {
      final tmp = pieces[0];
      pieces[0] = pieces[1];
      pieces[1] = tmp;
    }
    _history.clear();
    selectedIndex = null;
    paused = false;
    moves = 0;
    hintsUsed = 0;
    secondsElapsed = 0;
  }

  bool swap(int from, int to) {
    if (paused || finished || from < 0 || to < 0 ||
        from >= pieces.length || to >= pieces.length || from == to) {
      return false;
    }
    _history.add(List<int>.from(pieces));
    if (_history.length > 30) _history.removeAt(0);
    final temp = pieces[from];
    pieces[from] = pieces[to];
    pieces[to] = temp;
    moves++;
    selectedIndex = null;
    return true;
  }

  bool tap(int index) {
    if (paused || finished || index < 0 || index >= pieces.length) return false;
    if (selectedIndex == null) {
      selectedIndex = index;
      return false;
    }
    final from = selectedIndex!;
    selectedIndex = null;
    return swap(from, index);
  }

  bool undo() {
    if (_history.isEmpty || paused) return false;
    pieces.setAll(0, _history.removeLast());
    moves = max(0, moves - 1);
    selectedIndex = null;
    return true;
  }

  /// Returns a place needing correction and its matching destination.
  /// Pure query; no ad or payment is required to see a useful hint.
  (int from, int to)? get hint {
    for (var i = 0; i < pieces.length; i++) {
      if (pieces[i] != i) {
        return (i, pieces.indexOf(i));
      }
    }
    return null;
  }

  /// Optional one-step solve; useful for accessibility and frustration relief.
  bool applyHint() {
    if (paused || finished) return false;
    final next = hint;
    if (next == null) return false;
    final ok = swap(next.$1, next.$2);
    if (ok) hintsUsed++;
    return ok;
  }

  void tick() {
    if (!paused && !finished) secondsElapsed++;
  }

  Map<String, Object?> toJson() => {
    'version': 1,
    'size': size,
    'seed': seed,
    'mode': mode.name,
    'art': art.name,
    'pieces': List<int>.from(pieces),
    'moves': moves,
    'hints': hintsUsed,
    'elapsed': secondsElapsed,
    'paused': paused,
  };

  static JigsawGame fromJson(Map<String, dynamic> data) {
    if (data['version'] != 1) throw const FormatException('Incompatible save format');
    final size = data['size'];
    final seed = data['seed'];
    if (size is! int || size < 2 || size > 6 || seed is! int) {
      throw const FormatException('Invalid puzzle dimensions');
    }
    final original = data['pieces'];
    if (original is! List || original.length != size * size ||
        original.any((value) => value is! int) ||
        original.toSet().length != size * size ||
        original.any((value) => value < 0 || value >= size * size)) {
      throw const FormatException('Corrupted puzzle tile permutation');
    }
    final modeName = data['mode'];
    final artName = data['art'];
    final mode = PuzzleMode.values.where((m) => m.name == modeName).firstOrNull;
    final art = ArtTheme.values.where((a) => a.name == artName).firstOrNull;
    if (mode == null || art == null) throw const FormatException('Unknown game mode/art');
    final result = JigsawGame(size: size, seed: seed, mode: mode, art: art, shuffle: false);
    result.pieces.setAll(0, original.cast<int>());
    result.moves = _safeCount(data['moves']);
    result.hintsUsed = _safeCount(data['hints']);
    result.secondsElapsed = _safeCount(data['elapsed']);
    result.paused = data['paused'] == true;
    return result;
  }

  static int _safeCount(dynamic n) {
    if (n is! int || n < 0 || n > 100000000) throw const FormatException('Invalid counter');
    return n;
  }

  static int dailySeed(DateTime day) {
    final d = day.toUtc();
    return d.year * 10000 + d.month * 100 + d.day;
  }
}
