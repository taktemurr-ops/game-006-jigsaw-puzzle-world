import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game_006_jigsaw_puzzle_world/game/jigsaw_game.dart';
import 'package:game_006_jigsaw_puzzle_world/services/puzzle_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('save and restore puzzle, settings, achievements and deletion', () async {
    final store = LocalPuzzleStorage();
    final game = JigsawGame(size: 4, seed: 777, art: ArtTheme.ocean);
    game.swap(0, 1);
    final prefs = PuzzlePreferences(language: 'ar', showNumbers: true);
    await store.save(game, prefs);
    final restored = await store.readGame();
    expect(restored, isNotNull);
    expect(restored!.pieces, game.pieces);
    expect((await store.readPreferences()).language, 'ar');
    await store.clear();
    expect(await store.readGame(), isNull);
    expect((await store.readPreferences()).language, 'tr');
  });
  test('malformed save fails closed without crashing', () async {
    SharedPreferences.setMockInitialValues({
      'jigsaw_game_v1': '{invalid',
      'jigsaw_preferences_v1': 'false',
    });
    final store = LocalPuzzleStorage();
    expect(await store.readGame(), isNull);
    expect((await store.readPreferences()).language, 'tr');
  });
  test('only valid completion improves local best score', () {
    final prefs = PuzzlePreferences();
    final game = JigsawGame(size: 2, seed: 13);
    prefs.registerWin(game);
    expect(prefs.bestMoves, isEmpty);
    while (!game.solved) { game.applyHint(); }
    prefs.registerWin(game);
    expect(prefs.bestMoves.values, contains(game.moves));
  });
}
