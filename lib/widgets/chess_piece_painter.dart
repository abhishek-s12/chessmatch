import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/chess_piece.dart';

/// Renders tournament-grade Staunton dual-tone vector chess pieces with
/// realistic bevels, specular lighting, and soft drop shadows.
class ChessPieceWidget extends StatelessWidget {
  final ChessPiece piece;
  final double size;

  const ChessPieceWidget({
    super.key,
    required this.piece,
    this.size = 45,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _StauntonPiecePainter(
          type: piece.type,
          color: piece.color,
        ),
      ),
    );
  }
}

class _StauntonPiecePainter extends CustomPainter {
  final PieceType type;
  final PieceColor color;

  _StauntonPiecePainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final isWhite = color == PieceColor.white;
    final w = size.width;
    final h = size.height;

    // Palette & Gradients
    final Color mainFill = isWhite ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final Color shadowFill = isWhite ? const Color(0xFFCBD5E1) : const Color(0xFF090D16);
    final Color strokeColor = isWhite ? const Color(0xFF475569) : const Color(0xFF0F172A);
    final Color highlightColor = isWhite ? Colors.white.withOpacity(0.9) : const Color(0xFF475569);

    final Paint bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isWhite
            ? [const Color(0xFFFFFFFF), const Color(0xFFF1F5F9), const Color(0xFFCBD5E1)]
            : [const Color(0xFF334155), const Color(0xFF1E293B), const Color(0xFF0F172A)],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final Paint strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = w * 0.04
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final Paint innerLinePaint = Paint()
      ..color = isWhite ? const Color(0xFF94A3B8) : const Color(0xFF475569)
      ..strokeWidth = w * 0.025
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Drop shadow
    final Path shadowPath = _buildPiecePath(type, w, h);
    canvas.drawShadow(shadowPath, Colors.black.withOpacity(0.4), w * 0.06, true);

    // Draw main piece body
    canvas.drawPath(shadowPath, bodyPaint);
    canvas.drawPath(shadowPath, strokePaint);

    // Draw detail accents based on piece type
    _drawPieceDetails(canvas, w, h, isWhite, innerLinePaint, highlightColor);
  }

  Path _buildPiecePath(PieceType type, double w, double h) {
    final p = Path();

    switch (type) {
      case PieceType.pawn:
        // Pedestal base
        p.moveTo(w * 0.22, h * 0.88);
        p.lineTo(w * 0.78, h * 0.88);
        p.quadraticBezierTo(w * 0.80, h * 0.80, w * 0.68, h * 0.76);
        // Collar & Stem
        p.quadraticBezierTo(w * 0.58, h * 0.62, w * 0.56, h * 0.48);
        p.lineTo(w * 0.62, h * 0.48);
        // Head sphere
        p.arcToPoint(
          Offset(w * 0.38, h * 0.48),
          radius: Radius.circular(w * 0.20),
          clockwise: false,
        );
        p.lineTo(w * 0.44, h * 0.48);
        // Left Stem & Base
        p.quadraticBezierTo(w * 0.42, h * 0.62, w * 0.32, h * 0.76);
        p.quadraticBezierTo(w * 0.20, h * 0.80, w * 0.22, h * 0.88);
        p.close();
        break;

      case PieceType.knight:
        p.moveTo(w * 0.20, h * 0.88);
        p.lineTo(w * 0.80, h * 0.88);
        p.quadraticBezierTo(w * 0.78, h * 0.80, w * 0.72, h * 0.72);
        // Mane back arch
        p.cubicTo(w * 0.82, h * 0.55, w * 0.75, h * 0.30, w * 0.58, h * 0.16);
        // Ears
        p.lineTo(w * 0.52, h * 0.14);
        p.lineTo(w * 0.48, h * 0.22);
        // Snout & Forehead
        p.cubicTo(w * 0.34, h * 0.26, w * 0.22, h * 0.38, w * 0.20, h * 0.48);
        // Muzzle & Mouth
        p.lineTo(w * 0.28, h * 0.54);
        p.lineTo(w * 0.38, h * 0.48);
        // Chest & Neck
        p.cubicTo(w * 0.34, h * 0.60, w * 0.26, h * 0.74, w * 0.20, h * 0.88);
        p.close();
        break;

      case PieceType.bishop:
        p.moveTo(w * 0.22, h * 0.88);
        p.lineTo(w * 0.78, h * 0.88);
        p.quadraticBezierTo(w * 0.76, h * 0.80, w * 0.68, h * 0.74);
        p.quadraticBezierTo(w * 0.60, h * 0.58, w * 0.64, h * 0.44);
        // Mitre dome
        p.cubicTo(w * 0.70, h * 0.30, w * 0.58, h * 0.16, w * 0.50, h * 0.14);
        p.cubicTo(w * 0.42, h * 0.16, w * 0.30, h * 0.30, w * 0.36, h * 0.44);
        p.quadraticBezierTo(w * 0.40, h * 0.58, w * 0.32, h * 0.74);
        p.quadraticBezierTo(w * 0.24, h * 0.80, w * 0.22, h * 0.88);
        p.close();
        break;

      case PieceType.rook:
        p.moveTo(w * 0.20, h * 0.88);
        p.lineTo(w * 0.80, h * 0.88);
        p.quadraticBezierTo(w * 0.78, h * 0.80, w * 0.70, h * 0.76);
        // Tower body
        p.lineTo(w * 0.68, h * 0.42);
        p.lineTo(w * 0.76, h * 0.38);
        // Crenellations (castles)
        p.lineTo(w * 0.76, h * 0.20);
        p.lineTo(w * 0.64, h * 0.20);
        p.lineTo(w * 0.64, h * 0.28);
        p.lineTo(w * 0.56, h * 0.28);
        p.lineTo(w * 0.56, h * 0.20);
        p.lineTo(w * 0.44, h * 0.20);
        p.lineTo(w * 0.44, h * 0.28);
        p.lineTo(w * 0.36, h * 0.28);
        p.lineTo(w * 0.36, h * 0.20);
        p.lineTo(w * 0.24, h * 0.20);
        p.lineTo(w * 0.24, h * 0.38);
        p.lineTo(w * 0.32, h * 0.42);
        p.lineTo(w * 0.30, h * 0.76);
        p.quadraticBezierTo(w * 0.22, h * 0.80, w * 0.20, h * 0.88);
        p.close();
        break;

      case PieceType.queen:
        p.moveTo(w * 0.18, h * 0.88);
        p.lineTo(w * 0.82, h * 0.88);
        p.quadraticBezierTo(w * 0.78, h * 0.80, w * 0.68, h * 0.74);
        p.quadraticBezierTo(w * 0.62, h * 0.56, w * 0.76, h * 0.32);
        // 5 Crown Points
        p.lineTo(w * 0.62, h * 0.38);
        p.lineTo(w * 0.50, h * 0.22);
        p.lineTo(w * 0.38, h * 0.38);
        p.lineTo(w * 0.24, h * 0.32);
        p.quadraticBezierTo(w * 0.38, h * 0.56, w * 0.32, h * 0.74);
        p.quadraticBezierTo(w * 0.22, h * 0.80, w * 0.18, h * 0.88);
        p.close();
        break;

      case PieceType.king:
        p.moveTo(w * 0.18, h * 0.88);
        p.lineTo(w * 0.82, h * 0.88);
        p.quadraticBezierTo(w * 0.78, h * 0.80, w * 0.68, h * 0.74);
        p.quadraticBezierTo(w * 0.60, h * 0.56, w * 0.68, h * 0.38);
        p.cubicTo(w * 0.72, h * 0.24, w * 0.58, h * 0.22, w * 0.50, h * 0.24);
        p.cubicTo(w * 0.42, h * 0.22, w * 0.28, h * 0.24, w * 0.32, h * 0.38);
        p.quadraticBezierTo(w * 0.40, h * 0.56, w * 0.32, h * 0.74);
        p.quadraticBezierTo(w * 0.22, h * 0.80, w * 0.18, h * 0.88);
        p.close();
        break;
    }

    return p;
  }

  void _drawPieceDetails(
    Canvas canvas,
    double w,
    double h,
    bool isWhite,
    Paint linePaint,
    Color highlight,
  ) {
    final goldAccentPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;

    switch (type) {
      case PieceType.pawn:
        // Base ring
        canvas.drawLine(Offset(w * 0.30, h * 0.78), Offset(w * 0.70, h * 0.78), linePaint);
        // Collar
        canvas.drawLine(Offset(w * 0.40, h * 0.50), Offset(w * 0.60, h * 0.50), linePaint);
        break;

      case PieceType.knight:
        // Mane cuts
        canvas.drawLine(Offset(w * 0.64, h * 0.34), Offset(w * 0.74, h * 0.42), linePaint);
        canvas.drawLine(Offset(w * 0.60, h * 0.48), Offset(w * 0.70, h * 0.56), linePaint);
        // Eye
        final eyePaint = Paint()
          ..color = isWhite ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(w * 0.38, h * 0.34), w * 0.035, eyePaint);
        // Muzzle nostril line
        canvas.drawLine(Offset(w * 0.24, h * 0.46), Offset(w * 0.30, h * 0.44), linePaint);
        break;

      case PieceType.bishop:
        // Mitre Cross / Finial
        canvas.drawCircle(Offset(w * 0.50, h * 0.13), w * 0.045, goldAccentPaint);
        // Mitre Cut slash
        final cutPaint = Paint()
          ..color = isWhite ? const Color(0xFF64748B) : const Color(0xFF090D16)
          ..strokeWidth = w * 0.035
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(w * 0.44, h * 0.30), Offset(w * 0.58, h * 0.42), cutPaint);
        // Base ring
        canvas.drawLine(Offset(w * 0.30, h * 0.76), Offset(w * 0.70, h * 0.76), linePaint);
        break;

      case PieceType.rook:
        // Castle parapet accent line
        canvas.drawLine(Offset(w * 0.28, h * 0.40), Offset(w * 0.72, h * 0.40), linePaint);
        // Base ring
        canvas.drawLine(Offset(w * 0.28, h * 0.78), Offset(w * 0.72, h * 0.78), linePaint);
        break;

      case PieceType.queen:
        // 5 Jewels on Crown
        final jewelOffsets = [
          Offset(w * 0.24, h * 0.30),
          Offset(w * 0.38, h * 0.36),
          Offset(w * 0.50, h * 0.20),
          Offset(w * 0.62, h * 0.36),
          Offset(w * 0.76, h * 0.30),
        ];
        for (final offset in jewelOffsets) {
          canvas.drawCircle(offset, w * 0.04, goldAccentPaint);
        }
        // Waistband
        canvas.drawLine(Offset(w * 0.34, h * 0.60), Offset(w * 0.66, h * 0.60), linePaint);
        // Base ring
        canvas.drawLine(Offset(w * 0.26, h * 0.76), Offset(w * 0.74, h * 0.76), linePaint);
        break;

      case PieceType.king:
        // Royal Cross Finial on top
        final crossPaint = Paint()
          ..color = const Color(0xFFF59E0B)
          ..strokeWidth = w * 0.05
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.square;

        // Vertical cross bar
        canvas.drawLine(Offset(w * 0.50, h * 0.10), Offset(w * 0.50, h * 0.24), crossPaint);
        // Horizontal cross bar
        canvas.drawLine(Offset(w * 0.40, h * 0.16), Offset(w * 0.60, h * 0.16), crossPaint);

        // Headband
        canvas.drawLine(Offset(w * 0.34, h * 0.42), Offset(w * 0.66, h * 0.42), linePaint);
        // Base ring
        canvas.drawLine(Offset(w * 0.26, h * 0.76), Offset(w * 0.74, h * 0.76), linePaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _StauntonPiecePainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.color != color;
  }
}
