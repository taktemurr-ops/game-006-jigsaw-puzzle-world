import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/game_api.dart';
import '../app/play_kit.dart';
import '../app/services/audio.dart';
import '../core/game_rules.dart';
import '../core/level_plan.dart';
import '../core/rng.dart';
import 'jigsaw_engine.dart';
import 'rules.dart';

class JigsawView extends StatefulWidget {
  final PlayContext ctx;
  const JigsawView({super.key, required this.ctx});

  @override
  State<JigsawView> createState() => _JigsawViewState();
}

class _JigsawViewState extends State<JigsawView> with RoundClock {
  late JigsawGame game;
  int? _sel;
  bool _peek = false;
  int _hints = 0;
  int _undos = 0;
  int _solved = 0;
  int _placedTotal = 0;
  int _slides = 0;
  bool _ended = false;

  PlayContext get ctx => widget.ctx;
  bool get _chain => const [GameModeId.endless, GameModeId.timeAttack, GameModeId.zen].contains(ctx.spec.mode);

  @override
  void initState() {
    super.initState();
    final level = (ctx.generated as GeneratedLevel<JigsawLevel>).puzzle;
    final snap = ctx.resume['snap'];
    game = snap is String ? JigsawGame.restore(level, snap) : JigsawGame(level);
    _hints = (ctx.resume['hints'] as num?)?.toInt() ?? 0;
    _solved = (ctx.resume['solved'] as num?)?.toInt() ?? 0;
    startClock(initialSeconds: (ctx.resume['secs'] as num?)?.toInt() ?? 0, limit: level.timeLimit);
  }

  @override
  void dispose() {
    stopClock();
    super.dispose();
  }

  @override
  void onTimeUp() => _end(_chain ? _solved > 0 : game.won);

  void _persist() => ctx.saveResume({'snap': game.serialize(), 'secs': seconds, 'hints': _hints, 'solved': _solved});

  void _tap(int pos) {
    if (_ended) return;
    final before = game.correctCount;
    switch (game.level.kind) {
      case PuzzleKind.slide:
        if (!game.slide(pos)) {
          ctx.sfx(Sfx.error);
          return;
        }
        _slides++;
        break;
      case PuzzleKind.rotate:
      case PuzzleKind.swap:
        final s = _sel;
        if (s == null) {
          setState(() => _sel = pos);
          ctx.sfx(Sfx.tap);
          return;
        }
        if (s == pos) {
          if (game.level.kind == PuzzleKind.rotate) game.rotate(pos);
          _sel = null;
        } else {
          game.swap(s, pos);
          _sel = null;
        }
        break;
    }
    final gained = game.correctCount - before;
    if (gained > 0) _placedTotal += gained;
    ctx.sfx(gained > 0 ? Sfx.clear : Sfx.place);
    setState(() {});
    _persist();
    if (game.won) _onSolved();
  }

  void _onSolved() {
    ctx.sfx(Sfx.combo);
    if (_chain) {
      _solved++;
      final next = ctx.spec.copyWith(seed: mixSeed([ctx.spec.seed, _solved]));
      setState(() => game = JigsawGame(JigsawRules().build(next).puzzle));
      _persist();
      return;
    }
    _end(true);
  }

  void _end(bool won) {
    if (_ended) return;
    _ended = true;
    stopClock();
    final stars = _chain ? (_solved >= 6 ? 3 : _solved >= 3 ? 2 : 1) : JigsawRules.stars(game);
    ctx.finish(RoundResult(
      won: won,
      score: _chain ? _solved * 500 : (won ? (game.level.count * 100 - game.moves * 5).clamp(50, 99999) : 0),
      stars: won ? stars : 0,
      seconds: seconds,
      moves: game.moves,
      hintsUsed: _hints,
      undosUsed: _undos,
      gameStats: {'pieces_placed': _placedTotal, 'pictures_done': won ? 1 + _solved : _solved, 'slides': _slides},
    ));
  }

  Future<void> _hint() async {
    if (game.level.kind == PuzzleKind.slide) {
      await _peekPicture();
      return;
    }
    if (!await ctx.requestHint()) return;
    _hints++;
    setState(() => game.autoPlace());
    _persist();
    if (game.won) _onSolved();
  }

  Future<void> _peekPicture() async {
    if (!await ctx.requestBooster()) return;
    setState(() => _peek = true);
    await Future<void>.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _peek = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = ctx.t;
    final l = game.level;
    return Column(children: [
      PlayHud(items: [
        (Icons.extension, '${game.correctCount}/${l.count}'),
        (Icons.swap_horiz, '${t('moves')}: ${game.moves}'),
        (Icons.timer, timeText),
        if (_chain) (Icons.emoji_events, '$_solved'),
      ]),
      Expanded(
        child: LayoutBuilder(builder: (context, c) {
          final side = (c.maxWidth < c.maxHeight ? c.maxWidth : c.maxHeight) - 16;
          final cell = side / l.cols;
          return Center(
            child: SizedBox(
              width: side,
              height: side,
              child: Stack(children: [
                for (var pos = 0; pos < l.count; pos++) _piece(pos, cell, side),
                if (_peek)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: ArtPainter(l.artSeed)),
                    ),
                  ),
              ]),
            ),
          );
        }),
      ),
      BoosterBar(buttons: [
        BoosterButton(Icons.lightbulb, t('hint'), _hint),
        BoosterButton(Icons.visibility, 'Peek', _peekPicture),
        BoosterButton(Icons.undo, t('undo'), game.canUndo
            ? () {
                setState(() {
                  game.undo();
                  _undos++;
                });
                _persist();
              }
            : null),
      ]),
    ]);
  }

  Widget _piece(int pos, double cell, double side) {
    final l = game.level;
    final id = game.perm[pos];
    final x = pos % l.cols, y = pos ~/ l.cols;
    final isEmpty = l.kind == PuzzleKind.slide && id == l.count - 1 && !game.won;
    final px = id % l.cols, py = id ~/ l.cols;
    final art = ClipRect(
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: side,
        maxWidth: side,
        minHeight: side,
        maxHeight: side,
        child: Transform.translate(
          offset: Offset(-px * cell, -py * cell),
          child: CustomPaint(size: Size(side, side), painter: ArtPainter(l.artSeed)),
        ),
      ),
    );
    final right = game.placedRight(pos);
    return AnimatedPositioned(
      duration: Duration(milliseconds: ctx.reducedMotion ? 0 : 160),
      left: x * cell,
      top: y * cell,
      width: cell,
      height: cell,
      child: Semantics(
        button: true,
        label: 'piece ${id + 1}${right ? ' ok' : ''}',
        child: GestureDetector(
          onTap: () => _tap(pos),
          child: Container(
            margin: EdgeInsets.all(game.won ? 0 : 1),
            decoration: BoxDecoration(
              border: Border.all(
                color: _sel == pos
                    ? Colors.yellowAccent
                    : (right && !game.won ? Colors.greenAccent.withValues(alpha: 0.6) : Colors.white24),
                width: _sel == pos ? 3 : 1,
              ),
            ),
            child: isEmpty
                ? Container(color: Colors.black26)
                : RotatedBox(quarterTurns: game.rot[pos] % 4, child: art),
          ),
        ),
      ),
    );
  }
}

/// Procedural, original artwork (no external images). Same seed = same
/// picture on every device.
class ArtPainter extends CustomPainter {
  final int seed;
  ArtPainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final r = SeededRandom(seed);
    final w = size.width, h = size.height;
    final hue = r.nextInt(360).toDouble();
    Color hsl(double dh, double s, double l) =>
        HSLColor.fromAHSL(1, (hue + dh) % 360, s, l).toColor();
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [hsl(0, 0.6, 0.75), hsl(40, 0.55, 0.45)],
        ).createShader(Offset.zero & size),
    );
    final theme = r.nextInt(3);
    // Sun / moon
    canvas.drawCircle(Offset(w * (0.2 + r.nextDouble() * 0.6), h * 0.22), w * 0.09, Paint()..color = hsl(180, 0.8, 0.85));
    if (theme == 0) {
      // Mountains
      for (var layer = 0; layer < 4; layer++) {
        final path = Path()..moveTo(0, h);
        final base = h * (0.45 + layer * 0.12);
        for (var x = 0.0; x <= w; x += w / 8) {
          path.lineTo(x, base - r.nextDouble() * h * 0.18);
        }
        path
          ..lineTo(w, h)
          ..close();
        canvas.drawPath(path, Paint()..color = hsl(200 + layer * 15, 0.35, 0.55 - layer * 0.1));
      }
    } else if (theme == 1) {
      // Waves
      for (var layer = 0; layer < 6; layer++) {
        final path = Path()..moveTo(0, h);
        final base = h * (0.4 + layer * 0.1);
        final amp = h * (0.02 + r.nextDouble() * 0.04);
        final freq = 2 + r.nextInt(4);
        for (var x = 0.0; x <= w; x += 4) {
          path.lineTo(x, base + math.sin(x / w * math.pi * freq + layer) * amp);
        }
        path
          ..lineTo(w, h)
          ..close();
        canvas.drawPath(path, Paint()..color = hsl(160 + layer * 12, 0.6, 0.6 - layer * 0.07));
      }
    } else {
      // Geometric city / mosaic
      for (var i = 0; i < 26; i++) {
        final bw = w * (0.05 + r.nextDouble() * 0.12);
        final bh = h * (0.15 + r.nextDouble() * 0.45);
        final bx = r.nextDouble() * w;
        canvas.drawRect(Rect.fromLTWH(bx, h - bh, bw, bh), Paint()..color = hsl(220 + r.nextInt(80).toDouble(), 0.4, 0.25 + r.nextDouble() * 0.3));
        for (var k = 0; k < 6; k++) {
          canvas.drawRect(
            Rect.fromLTWH(bx + bw * 0.2, h - bh + k * bh / 7 + 6, bw * 0.2, bh / 20),
            Paint()..color = hsl(60, 0.9, 0.75),
          );
        }
      }
    }
    // Scattered detail shapes so every piece is distinguishable.
    for (var i = 0; i < 40; i++) {
      final p = Offset(r.nextDouble() * w, r.nextDouble() * h);
      final s = w * (0.01 + r.nextDouble() * 0.03);
      final paint = Paint()..color = hsl(r.nextInt(360).toDouble(), 0.7, 0.6).withValues(alpha: 0.85);
      if (i.isEven) {
        canvas.drawCircle(p, s, paint);
      } else {
        canvas.drawRect(Rect.fromCenter(center: p, width: s * 2, height: s * 2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(ArtPainter old) => old.seed != seed;
}
