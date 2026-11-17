import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game_006_jigsaw_puzzle_world/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('picture game renders and exposes modes, toolbar and tiles', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const JigsawApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Jigsaw Puzzle World'), findsOneWidget);
    expect(find.byKey(const ValueKey('picture-piece-0')), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
  testWidgets('switching to sliding game keeps classic board available', (tester) async {
    await tester.pumpWidget(const JigsawApp());
    await tester.pump();
    await tester.ensureVisible(find.text('Kaydırmalı'));
    await tester.pump();
    await tester.tap(find.text('Kaydırmalı'));
    await tester.pump();
    expect(find.byKey(const ValueKey('tile-1')), findsOneWidget);
  });
}
