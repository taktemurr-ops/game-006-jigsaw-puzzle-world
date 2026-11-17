import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'game/jigsaw_game.dart';
import 'game/sliding_puzzle.dart';
import 'services/game_text.dart';
import 'services/puzzle_storage.dart';
import 'widgets/artwork.dart';

// Maintain compatibility with the repository's original puzzle-engine tests.
export 'game/sliding_puzzle.dart' show SlidingPuzzle;

void main() => runApp(const JigsawApp());

class JigsawApp extends StatelessWidget {
  const JigsawApp({super.key, this.storage});
  final PuzzleStorage? storage;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Jigsaw Puzzle World',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF59D6C8),
        brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF0D2035)),
    home: PuzzleScreen(storage: storage ?? LocalPuzzleStorage()),
  );
}

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key, required this.storage});
  final PuzzleStorage storage;
  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  JigsawGame game = JigsawGame(size: 3, seed: 804);
  SlidingPuzzle slider = SlidingPuzzle()..shuffle(random: Random(5));
  PuzzlePreferences preferences = PuzzlePreferences();
  bool slidingMode = false;
  bool preview = false;
  bool started = false;
  bool _winRecorded = false;
  Timer? _timer;
  String? _status;

  GameText get text => GameText(preferences.language);

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || slidingMode || game.finished || game.paused) return;
      setState(() {
        game.tick();
        if (game.timedOut) _status = text.t('timeout');
      });
    });
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<Object?>([
        widget.storage.readPreferences(), widget.storage.readGame(),
      ]);
      if (!mounted) return;
      setState(() {
        preferences = results[0] as PuzzlePreferences;
        final previous = results[1] as JigsawGame?;
        if (previous != null) game = previous;
        started = true;
        _winRecorded = game.solved;
      });
    } catch (_) {
      if (mounted) setState(() => started = true);
    }
  }

  Future<void> _save() async {
    try { await widget.storage.save(game, preferences); } catch (_) {
      // Offline play must continue even when local storage is unavailable.
    }
  }

  void _changed() {
    if (game.solved && !_winRecorded) {
      preferences.registerWin(game);
      _winRecorded = true;
      _status = text.t('done');
    }
    _save();
  }

  void _newGame({PuzzleMode? mode, int? size, ArtTheme? art, bool? slide}) {
    final nextSlide = slide ?? slidingMode;
    if (nextSlide) {
      final nextSize = size ?? slider.size;
      setState(() {
        slidingMode = true;
        slider = SlidingPuzzle(size: nextSize)..shuffle(steps: 150,
          random: Random(DateTime.now().microsecondsSinceEpoch));
        _status = null;
      });
    } else {
      final nextMode = mode ?? game.mode;
      final seed = nextMode == PuzzleMode.daily
          ? JigsawGame.dailySeed(DateTime.now().toUtc())
          : DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
      setState(() {
        slidingMode = false;
        game = JigsawGame(size: size ?? game.size, seed: seed,
            mode: nextMode, art: art ?? game.art);
        _status = null;
        _winRecorded = false;
      });
      _save();
    }
  }

  void _tileTapped(int index) {
    setState(() {
      final before = game.moves;
      game.tap(index);
      if (game.moves != before) _changed();
    });
  }

  void _tileDropped(int from, int to) {
    setState(() {
      if (game.swap(from, to)) _changed();
    });
  }

  void _undo() {
    setState(() {
      if (slidingMode) {
        slider.undo();
      } else {
        game.undo();
        _winRecorded = game.solved;
        _save();
      }
    });
  }

  void _showSettings() {
    showModalBottomSheet<void>(context: context, isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, updateSheet) {
          final t = text;
          void apply(void Function() fn) {
            setState(fn);
            updateSheet(() {});
            _save();
          }
          return SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(t.t('settings'), style: Theme.of(context).textTheme.headlineSmall),
              DropdownButtonFormField<String>(value: preferences.language,
                decoration: InputDecoration(labelText: t.t('language')),
                items: const [DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'ar', child: Text('العربية'))],
                onChanged: (value) { if (value != null) apply(() => preferences.language = value); }),
              SwitchListTile(title: Text(t.t('numbers')), value: preferences.showNumbers,
                onChanged: (v) => apply(() => preferences.showNumbers = v)),
              SwitchListTile(title: Text(t.t('motion')), value: preferences.reducedMotion,
                onChanged: (v) => apply(() => preferences.reducedMotion = v)),
              SwitchListTile(title: Text(t.t('sound')), subtitle: const Text('Audio engine disabled until assets and permission reviews.'),
                value: preferences.sound, onChanged: (v) => apply(() => preferences.sound = v)),
              ListTile(title: Text(t.t('privacy')), subtitle: Text(t.t('noAds'))),
              OutlinedButton.icon(onPressed: () async {
                final confirm = await showDialog<bool>(context: sheetContext,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(t.t('clearTitle')),
                    actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false),
                      child: Text(t.t('cancel'))),
                    FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
                      child: Text(t.t('confirm')))],
                  ));
                if (confirm != true) return;
                await widget.storage.clear();
                if (!mounted) return;
                setState(() { preferences = PuzzlePreferences();
                  game = JigsawGame(size: 3, seed: 804); _winRecorded = false; });
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              }, icon: const Icon(Icons.delete_outline), label: Text(t.t('erase'))),
            ]),
          ));
        },
      ),
    );
  }

  Widget _modeSelector() {
    final t = text;
    return SingleChildScrollView(scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final mode in PuzzleMode.values)
          Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(
            label: Text(t.t(mode.name)),
            selected: !slidingMode && game.mode == mode,
            onSelected: (_) => _newGame(mode: mode, slide: false))),
        ChoiceChip(label: Text(t.t('slide')), selected: slidingMode,
          onSelected: (_) => _newGame(slide: true)),
      ]),
    );
  }

  Widget _toolbar() {
    final t = text;
    return Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 4, children: [
      OutlinedButton.icon(onPressed: (slidingMode ? slider.canUndo : game.canUndo)
          ? _undo : null, icon: const Icon(Icons.undo), label: Text(t.t('undo'))),
      if (!slidingMode) ...[
        OutlinedButton.icon(onPressed: game.finished || game.paused ? null : () {
          final h = game.hint;
          if (h == null) return;
          setState(() => _status = '${t.t('hint')}: ${h.$1 + 1} → ${h.$2 + 1}');
        }, icon: const Icon(Icons.lightbulb_outline), label: Text(t.t('hint'))),
        OutlinedButton.icon(onPressed: () => setState(() => preview = !preview),
          icon: const Icon(Icons.image_outlined), label: Text(t.t('preview'))),
        OutlinedButton.icon(onPressed: game.finished ? null : () {
          setState(() => game.paused = !game.paused);
          _save();
        }, icon: Icon(game.paused ? Icons.play_arrow : Icons.pause),
          label: Text(t.t(game.paused ? 'resume' : 'pause'))),
      ],
    ]);
  }

  Widget _pictureBoard() {
    final t = text;
    final size = game.size;
    return LayoutBuilder(builder: (context, constraints) {
      final side = min(constraints.maxWidth, 460.0);
      final tileSide = (side - (size - 1) * 3) / size;
      return SizedBox(width: side, height: side,
        child: Stack(children: [
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: size, crossAxisSpacing: 3, mainAxisSpacing: 3),
            itemCount: game.pieces.length,
            itemBuilder: (context, index) {
              final id = game.pieces[index];
              final selected = game.selectedIndex == index;
              Widget picture() => DecoratedBox(
                decoration: BoxDecoration(border: Border.all(color: selected
                    ? Colors.amberAccent : Colors.white30, width: selected ? 4 : 1),
                  borderRadius: BorderRadius.circular(5)),
                child: ClipRRect(borderRadius: BorderRadius.circular(4),
                  child: ArtPiece(art: game.art, size: size, pieceId: id,
                    showNumber: preferences.showNumbers)));
              return DragTarget<int>(
                onWillAcceptWithDetails: (d) => !game.paused && !game.finished && d.data != index,
                onAcceptWithDetails: (d) => _tileDropped(d.data, index),
                builder: (context, candidates, rejects) => Semantics(
                  button: true,
                  label: 'Piece ${id + 1}; position ${index + 1}; '
                      '${id == index ? 'correct' : 'incorrect'}',
                  child: LongPressDraggable<int>(
                    data: index,
                    maxSimultaneousDrags: game.paused || game.finished ? 0 : 1,
                    feedback: Material(color: Colors.transparent,
                      child: SizedBox(width: tileSide, height: tileSide,
                        child: Opacity(opacity: .85, child: picture()))),
                    childWhenDragging: const DecoratedBox(decoration: BoxDecoration(color: Colors.white12)),
                    child: InkWell(key: ValueKey('picture-piece-$index'),
                      onTap: game.paused || game.finished ? null : () => _tileTapped(index),
                      child: picture()),
                  ),
                ),
              );
            }),
          if (game.paused || preview)
            Positioned.fill(child: DecoratedBox(
              decoration: const BoxDecoration(color: Color(0xF00D2035)),
              child: Center(child: game.paused
                ? Text(t.t('pause'), style: const TextStyle(fontSize: 32))
                : Padding(padding: const EdgeInsets.all(10),
                  child: ArtPreview(art: game.art))))),
        ]),
      );
    });
  }

  Widget _slidingBoard() {
    return ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460),
      child: AspectRatio(aspectRatio: 1, child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: slider.size, crossAxisSpacing: 4, mainAxisSpacing: 4),
        itemCount: slider.tiles.length,
        itemBuilder: (context, index) {
          final number = slider.tiles[index];
          return number == 0 ? const ColoredBox(color: Color(0xFF244E68))
              : FilledButton(
                key: ValueKey('tile-$number'),
                onPressed: slider.canMove(index) ? () => setState(() => slider.move(index)) : null,
                style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                child: FittedBox(child: Text('$number',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 29))));
        }),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final t = text;
    final complete = slidingMode ? slider.solved : game.solved;
    return Directionality(textDirection: t.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: const Text('Jigsaw Puzzle World'), actions: [
          IconButton(tooltip: t.t('settings'), onPressed: _showSettings,
            icon: const Icon(Icons.settings_outlined))]),
        body: SafeArea(child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(padding: const EdgeInsets.fromLTRB(14, 8, 14, 32), children: [
            Text(t.t('subtitle'), textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            _modeSelector(),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: DropdownButtonFormField<int>(
                value: slidingMode ? slider.size : game.size,
                decoration: InputDecoration(labelText: t.t('level'),
                  border: const OutlineInputBorder()),
                items: [for (var n = 2; n <= 6; n++)
                  DropdownMenuItem(value: n, child: Text('$n × $n'))],
                onChanged: (value) { if (value != null) _newGame(size: value); })),
              if (!slidingMode) ...[
                const SizedBox(width: 10),
                Expanded(child: DropdownButtonFormField<ArtTheme>(
                  value: game.art,
                  decoration: InputDecoration(labelText: t.t('theme'),
                    border: const OutlineInputBorder()),
                  items: [for (final art in ArtTheme.values)
                    DropdownMenuItem(value: art, child: Text(t.t('art${art.index+1}')))],
                  onChanged: (value) { if (value != null) _newGame(art: value); })),
              ],
            ]),
            const SizedBox(height: 12),
            Wrap(alignment: WrapAlignment.spaceAround, spacing: 12, children: [
              Chip(label: Text('${t.t('moves')}: ${slidingMode ? slider.moves : game.moves}')),
              if (!slidingMode) Chip(label: Text('${t.t('time')}: ${game.mode == PuzzleMode.timed ? game.remainingTime : game.secondsElapsed}s')),
              if (!slidingMode) Chip(label: Text('${game.correctlyPlaced}/${game.pieces.length}')),
            ]),
            const SizedBox(height: 12),
            Center(child: slidingMode ? _slidingBoard() : _pictureBoard()),
            const SizedBox(height: 10),
            if (complete || (!slidingMode && game.timedOut))
              Card(color: const Color(0xFF176B63), child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(complete ? t.t('done') : t.t('timeout'),
                  key: const ValueKey('completed'), textAlign: TextAlign.center))),
            if (_status != null) Text(_status!, textAlign: TextAlign.center,
              key: const ValueKey('status')),
            const SizedBox(height: 10),
            _toolbar(),
            const SizedBox(height: 6),
            FilledButton.icon(onPressed: () => _newGame(),
              icon: const Icon(Icons.shuffle), label: Text(t.t('new'))),
            const SizedBox(height: 8),
            if (!slidingMode) Text(t.t('select'), textAlign: TextAlign.center),
            if (!started) const Center(child: CircularProgressIndicator()),
          ]),
        ))),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
