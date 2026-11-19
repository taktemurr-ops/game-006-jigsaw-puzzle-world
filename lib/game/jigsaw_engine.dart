import '../core/level_plan.dart';
import '../core/rng.dart';

enum PuzzleKind { swap, rotate, slide }

class JigsawLevel {
  final int rows;
  final int cols;
  final PuzzleKind kind;

  /// position -> piece id (piece id = correct position). For slide, the
  /// piece id rows*cols-1 is the empty slot.
  final List<int> start;
  final List<int> rotations; // quarter turns per piece (rotate kind)
  final int artSeed;
  final int timeLimit;
  final int difficulty;
  final int scramble;

  const JigsawLevel({
    required this.rows,
    required this.cols,
    required this.kind,
    required this.start,
    required this.rotations,
    required this.artSeed,
    required this.timeLimit,
    required this.difficulty,
    required this.scramble,
  });

  int get count => rows * cols;
}

class JigsawGame {
  final JigsawLevel level;
  late List<int> perm;
  late List<int> rot;
  int moves = 0;
  final List<String> _undo = [];

  JigsawGame(this.level) {
    perm = List.of(level.start);
    rot = List.of(level.rotations);
  }

  int get emptyPiece => level.count - 1;

  bool get won {
    for (var i = 0; i < perm.length; i++) {
      if (perm[i] != i) return false;
      if (level.kind == PuzzleKind.rotate && rot[i] % 4 != 0) return false;
    }
    return true;
  }

  bool placedRight(int pos) =>
      perm[pos] == pos && (level.kind != PuzzleKind.rotate || rot[pos] % 4 == 0);

  int get correctCount => List.generate(perm.length, placedRight).where((e) => e).length;

  void _push() {
    _undo.add(_snap());
    if (_undo.length > 60) _undo.removeAt(0);
  }

  bool swap(int a, int b) {
    if (a == b || level.kind == PuzzleKind.slide) return false;
    _push();
    final t = perm[a];
    perm[a] = perm[b];
    perm[b] = t;
    final r = rot[a];
    rot[a] = rot[b];
    rot[b] = r;
    moves++;
    return true;
  }

  void rotate(int pos) {
    if (level.kind != PuzzleKind.rotate) return;
    _push();
    rot[pos] = (rot[pos] + 1) % 4;
    moves++;
  }

  int get emptyPos => perm.indexOf(emptyPiece);

  bool canSlide(int pos) {
    if (level.kind != PuzzleKind.slide) return false;
    final e = emptyPos;
    final ex = e % level.cols, ey = e ~/ level.cols;
    final x = pos % level.cols, y = pos ~/ level.cols;
    return (ex - x).abs() + (ey - y).abs() == 1;
  }

  bool slide(int pos) {
    if (!canSlide(pos)) return false;
    _push();
    final e = emptyPos;
    perm[e] = perm[pos];
    perm[pos] = emptyPiece;
    moves++;
    return true;
  }

  /// Hint (swap / rotate): fixes one wrong position. Returns the position.
  int? autoPlace() {
    if (level.kind == PuzzleKind.slide) return null;
    for (var pos = 0; pos < perm.length; pos++) {
      if (placedRight(pos)) continue;
      _push();
      final from = perm.indexOf(pos);
      if (from != pos) {
        final t = perm[pos];
        perm[pos] = pos;
        perm[from] = t;
        final r = rot[pos];
        rot[pos] = rot[from];
        rot[from] = r;
      }
      rot[pos] = 0;
      moves++;
      return pos;
    }
    return null;
  }

  bool get canUndo => _undo.isNotEmpty;

  void undo() {
    if (_undo.isNotEmpty) _restore(_undo.removeLast());
  }

  String _snap() => '${perm.join(',')}#${rot.join(',')}#$moves';

  void _restore(String s) {
    final p = s.split('#');
    perm = p[0].split(',').map(int.parse).toList();
    rot = p[1].split(',').map(int.parse).toList();
    moves = int.parse(p[2]);
  }

  String serialize() => _snap();

  static JigsawGame restore(JigsawLevel l, String s) => JigsawGame(l).._restore(s);
}

JigsawLevel generateJigsaw(LevelSpec spec) {
  final r = SeededRandom(spec.seed);
  final d = spec.difficulty;
  final kind = spec.has('slide')
      ? PuzzleKind.slide
      : spec.has('rotate')
          ? PuzzleKind.rotate
          : PuzzleKind.swap;
  int rows;
  if (kind == PuzzleKind.slide) {
    rows = (3 + (d - 1) ~/ 4).clamp(3, 5);
  } else {
    rows = (3 + (d - 1) ~/ 2).clamp(3, 8);
  }
  if (spec.levelId > 0 && spec.levelId <= 3 && spec.mode == GameModeId.campaign) rows = 2 + spec.levelId ~/ 2 + 1;
  final cols = rows;
  final n = rows * cols;
  var perm = List.generate(n, (i) => i);
  var scramble = 0;
  if (kind == PuzzleKind.slide) {
    // Random legal moves from the solved state: always solvable.
    var e = n - 1;
    var prev = -1;
    final steps = 20 + d * 25 + rows * 10;
    for (var k = 0; k < steps; k++) {
      final ex = e % cols, ey = e ~/ cols;
      final opts = <int>[];
      if (ex > 0) opts.add(e - 1);
      if (ex < cols - 1) opts.add(e + 1);
      if (ey > 0) opts.add(e - cols);
      if (ey < rows - 1) opts.add(e + cols);
      opts.remove(prev);
      final p = r.pick(opts);
      perm[e] = perm[p];
      perm[p] = n - 1;
      prev = e;
      e = p;
    }
    scramble = steps;
  } else {
    r.shuffle(perm);
    scramble = n;
  }
  final rots = List<int>.filled(n, 0);
  if (kind == PuzzleKind.rotate) {
    for (var i = 0; i < n; i++) {
      rots[i] = r.nextInt(4);
    }
  }
  return JigsawLevel(
    rows: rows,
    cols: cols,
    kind: kind,
    start: perm,
    rotations: rots,
    artSeed: spec.seed,
    timeLimit: spec.mode == GameModeId.timeAttack ? 60 + n * 4 : (spec.has('timer') ? 60 + n * 8 : 0),
    difficulty: d,
    scramble: scramble,
  );
}
