import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game/jigsaw_game.dart';

/// Procedural, original vector art, avoiding copyrighted image assets.
class ArtPiece extends StatelessWidget {
  const ArtPiece({required this.art, required this.size, required this.pieceId,
      required this.showNumber, super.key});
  final ArtTheme art;
  final int size;
  final int pieceId;
  final bool showNumber;

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
    CustomPaint(painter: _ArtPiecePainter(art, size, pieceId)),
    if (showNumber) Align(alignment: Alignment.bottomRight, child: Padding(
      padding: const EdgeInsets.all(3), child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.black54,
            borderRadius: BorderRadius.circular(5)),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: Text('${pieceId + 1}', style: const TextStyle(color: Colors.white,
                fontSize: 11, fontWeight: FontWeight.bold))),
      ),
    )),
  ]);
}

class ArtPreview extends StatelessWidget {
  const ArtPreview({required this.art, super.key});
  final ArtTheme art;
  @override
  Widget build(BuildContext context) => AspectRatio(aspectRatio: 1,
      child: CustomPaint(painter: _ArtPreviewPainter(art)));
}

class _ArtPreviewPainter extends CustomPainter {
  _ArtPreviewPainter(this.art);
  final ArtTheme art;
  @override
  void paint(Canvas canvas, Size size) => _paintArt(canvas, size, art);
  @override
  bool shouldRepaint(covariant _ArtPreviewPainter old) => old.art != art;
}

class _ArtPiecePainter extends CustomPainter {
  _ArtPiecePainter(this.art, this.count, this.pieceId);
  final ArtTheme art;
  final int count;
  final int pieceId;
  @override
  void paint(Canvas canvas, Size size) {
    final row = pieceId ~/ count;
    final col = pieceId % count;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(-col * size.width, -row * size.height);
    _paintArt(canvas, Size(size.width * count, size.height * count), art);
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant _ArtPiecePainter old) =>
      old.art != art || old.count != count || old.pieceId != pieceId;
}

void _paintArt(Canvas canvas, Size s, ArtTheme theme) {
  final w = s.width, h = s.height;
  final sky = switch (theme) {
    ArtTheme.mountains => const Color(0xFF89C5ED),
    ArtTheme.ocean => const Color(0xFF257FCE),
    ArtTheme.garden => const Color(0xFFA8E6A1),
    ArtTheme.sunset => const Color(0xFFFFB878),
  };
  final ground = switch (theme) {
    ArtTheme.mountains => const Color(0xFF2C687A),
    ArtTheme.ocean => const Color(0xFF013C71),
    ArtTheme.garden => const Color(0xFF338C52),
    ArtTheme.sunset => const Color(0xFF8B4163),
  };
  canvas.drawRect(Offset.zero & s, Paint()..shader = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [sky, ground], stops: const [0.0, 1.0],
  ).createShader(Offset.zero & s));
  void circle(double x, double y, double radius, Color color) => canvas.drawCircle(
    Offset(x * w, y * h), radius * w, Paint()..color = color);
  void polygon(List<Offset> points, Color color) {
    final path = Path()..moveTo(points.first.dx * w, points.first.dy * h);
    for (final p in points.skip(1)) { path.lineTo(p.dx * w, p.dy * h); }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }
  if (theme == ArtTheme.mountains) {
    circle(.77, .22, .09, const Color(0xFFFFF3C3));
    polygon([const Offset(-.12,.77),const Offset(.28,.2),const Offset(.7,.82)], const Color(0xFF4C7C90));
    polygon([const Offset(.25,.85),const Offset(.68,.3),const Offset(1.1,.86)], const Color(0xFF28596E));
    polygon([const Offset(.19,.33),const Offset(.28,.2),const Offset(.37,.34)], Colors.white70);
    polygon([const Offset(.6,.41),const Offset(.68,.3),const Offset(.76,.41)], Colors.white70);
    polygon([const Offset(0,.92),const Offset(.25,.73),const Offset(.55,.91),const Offset(.76,.78),const Offset(1,.88),const Offset(1,1),const Offset(0,1)], const Color(0xFF174A4A));
  } else if (theme == ArtTheme.ocean) {
    for (var i=0;i<7;i++) {
      circle((.12+i*.14)%1, .16+(i%3)*.16, .035, Colors.white24);
    }
    polygon([const Offset(.1,.5), const Offset(.3,.39),const Offset(.48,.5),const Offset(.3,.59)], const Color(0xFFFFB25B));
    polygon([const Offset(.47,.5),const Offset(.57,.42),const Offset(.57,.59)], const Color(0xFFFFB25B));
    circle(.27,.48,.015, const Color(0xFF102B48));
    polygon([const Offset(.56,.72),const Offset(.73,.62),const Offset(.91,.72),const Offset(.73,.82)], const Color(0xFF6CE1C4));
    polygon([const Offset(.91,.72),const Offset(1,.65),const Offset(1,.78)], const Color(0xFF6CE1C4));
    for (var i=0;i<5;i++) {
      final x=.1+i*.21;
      polygon([Offset(x,1),Offset(x-.02,.83),Offset(x+.025,.7),Offset(x+.04,1)], const Color(0xFF19A783));
    }
  } else if (theme == ArtTheme.garden) {
    circle(.75,.18,.085, const Color(0xFFFFFFB5));
    for (var i=0;i<7;i++) {
      final x=.08+i*.14;
      canvas.drawLine(Offset(x*w,.88*h),Offset(x*w,.58*h),Paint()..color=const Color(0xFF266A43)..strokeWidth=w*.014);
      for(var petal=0;petal<6;petal++){
        final a=petal*math.pi/3;
        circle(x+math.cos(a)*.045,.57+math.sin(a)*.045,.037,
          i.isEven?const Color(0xFFFFC9E1):const Color(0xFFFFE27A));
      }
      circle(x,.57,.027,const Color(0xFFF3A74F));
    }
    polygon([const Offset(0,.85),const Offset(.25,.8),const Offset(.6,.88),const Offset(1,.81),const Offset(1,1),const Offset(0,1)],const Color(0xFF276C3D));
  } else {
    circle(.53,.42,.17,const Color(0xFFFFE09B));
    for(var i=0;i<5;i++){
      final y=.63+i*.075;
      canvas.drawLine(Offset(0,y*h),Offset(w,y*h),Paint()
        ..color=Color.lerp(const Color(0xFFFFC1A0),const Color(0xFF3D2B62),i/5)!
        ..strokeWidth=w*.04);
    }
    polygon([const Offset(0,.68),const Offset(.12,.6),const Offset(.35,.75),const Offset(.68,.67),const Offset(1,.78),const Offset(1,1),const Offset(0,1)],const Color(0xFF502E60));
  }
}
