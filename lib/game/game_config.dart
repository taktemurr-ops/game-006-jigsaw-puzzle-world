import 'package:flutter/material.dart';

import '../app/game_api.dart';
import 'jigsaw_view.dart';
import 'rules.dart';

final gameConfig = GameConfig(
  gameId: 'game-006-jigsaw-puzzle-world',
  title: const ['Yapboz Dünyası', 'Jigsaw Puzzle World', 'Puzzle-Welt', 'Mundo de Puzles', 'Monde du Puzzle'],
  tagline: const [
    'Sonsuz özgün resim, parça parça birleştir!',
    'Endless original pictures to piece together!',
    'Unendlich viele Bilder zum Puzzeln!',
    '¡Imágenes infinitas para armar!',
    'Des images infinies à reconstituer !',
  ],
  seedColor: const Color(0xFF2E7D32),
  icon: Icons.extension,
  rules: JigsawRules(),
  buildPlay: (ctx) => JigsawView(ctx: ctx),
  tutorial: const [
    TutorialStep(Icons.swap_horiz, [
      'Klasik bölümlerde iki parçaya sırayla dokunarak yerlerini değiştir.',
      'Classic levels: tap two pieces to swap them.',
      'Klassisch: zwei Teile antippen, um sie zu tauschen.',
      'Clásico: toca dos piezas para cambiarlas.',
      'Classique : touchez deux pièces pour les échanger.',
    ]),
    TutorialStep(Icons.rotate_right, [
      'Döndürmeli bölümlerde seçili parçaya tekrar dokununca 90° döner.',
      'Rotate levels: tap a selected piece again to turn it 90°.',
      'Dreh-Level: ausgewähltes Teil erneut antippen.',
      'Rotación: toca de nuevo la pieza para girarla.',
      'Rotation : touchez à nouveau pour tourner.',
    ]),
    TutorialStep(Icons.grid_view, [
      'Kaydırmalı bölümlerde boşluğun yanındaki parçaya dokun.',
      'Slide levels: tap a piece next to the gap.',
      'Schiebe-Level: Teil neben der Lücke antippen.',
      'Deslizar: toca una pieza junto al hueco.',
      'Glissement : touchez une pièce près du vide.',
    ]),
    TutorialStep(Icons.visibility, [
      'Göz atma ile resmin tamamını 3 saniye gör. Doğru yerdeki parçalar yeşil kenarlıdır.',
      'Peek shows the full picture for 3 seconds. Correct pieces glow green.',
      'Vorschau zeigt das Bild 3 Sekunden. Richtige Teile leuchten grün.',
      'Vista previa 3 s. Las piezas correctas brillan en verde.',
      'Aperçu 3 s. Les bonnes pièces brillent en vert.',
    ]),
  ],
);
