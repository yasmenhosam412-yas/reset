import 'package:flutter/material.dart';

class TeamPitchLinesPainter extends CustomPainter {
  TeamPitchLinesPainter({required this.line, required this.subtle});

  final Color line;
  final Color subtle;

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = line
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final grid = Paint()
      ..color = subtle
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Offset.zero & size, border);

    final midY = size.height / 2;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), border);

    final cx = size.width / 2;
    final r = size.width * 0.11;
    canvas.drawCircle(Offset(cx, midY), r, border);

    final boxW = size.width * 0.42;
    final boxH = size.height * 0.2;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, midY), width: boxW, height: boxH),
      border,
    );

    canvas.drawRect(
      Rect.fromLTWH((size.width - boxW) / 2, 8, boxW, boxH * 0.55),
      border,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - boxW) / 2,
        size.height - 8 - boxH * 0.55,
        boxW,
        boxH * 0.55,
      ),
      border,
    );

    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  @override
  bool shouldRepaint(covariant TeamPitchLinesPainter oldDelegate) =>
      oldDelegate.line != line || oldDelegate.subtle != subtle;
}
