import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chess_game_state.dart';
import '../models/chess_piece.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'chess_piece_painter.dart';

class ChessBoardWidget extends StatelessWidget {
  final String? bestMoveUci;
  final Function(ChessMove)? onMoveMade;
  final bool interactive;

  const ChessBoardWidget({
    super.key,
    this.bestMoveUci,
    this.onMoveMade,
    this.interactive = true,
  });

  @override
  Widget build(BuildContext context) {
    final game = context.watch<ChessGameState>();
    final isFlipped = game.isFlipped;
    final boardTheme = AppTheme.activeBoardTheme;

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: boardTheme.borderColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // 8x8 Board Grid
            Column(
              children: List.generate(8, (displayRow) {
                final actualRow = isFlipped ? 7 - displayRow : displayRow;
                return Expanded(
                  child: Row(
                    children: List.generate(8, (displayCol) {
                      final actualCol = isFlipped ? 7 - displayCol : displayCol;
                      final pos = BoardPosition(actualRow, actualCol);
                      return Expanded(
                        child: _buildSquare(
                          context,
                          game,
                          pos,
                          displayRow,
                          displayCol,
                          isFlipped,
                          boardTheme,
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),

            // Best Move Vector Arrow Overlay
            if (bestMoveUci != null && bestMoveUci!.length >= 4)
              _buildBestMoveOverlay(game, isFlipped, boardTheme.accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSquare(
    BuildContext context,
    ChessGameState game,
    BoardPosition pos,
    int displayRow,
    int displayCol,
    bool isFlipped,
    BoardThemeType theme,
  ) {
    final isLight = (pos.row + pos.col) % 2 == 0;
    final isSelected = game.selectedSquare == pos;
    final isLegalMoveTarget = game.legalMovesForSelected.any((m) => m.to == pos);
    final piece = game.pieceAtPos(pos);
    final isKingInCheck = piece != null &&
        piece.type == PieceType.king &&
        piece.color == game.turn &&
        game.isKingInCheck(game.turn);

    // Is this square the source or destination of the last move played?
    final isLastMoveSource = game.moveHistory.isNotEmpty && game.moveHistory.last.from == pos;
    final isLastMoveDest = game.moveHistory.isNotEmpty && game.moveHistory.last.to == pos;

    // Coordinate displays (Top-Left of 'a' file squares, Bottom-Right of rank 1 squares)
    final showRankLabel = isFlipped ? (displayCol == 7) : (displayCol == 0);
    final showFileLabel = isFlipped ? (displayRow == 0) : (displayRow == 7);
    final rankText = (isFlipped ? (pos.row + 1) : (8 - pos.row)).toString();
    final fileText = String.fromCharCode('a'.codeUnitAt(0) + pos.col);
    final coordColor = isLight ? theme.coordinateLight : theme.coordinateDark;

    Color squareColor = isLight ? theme.lightSquare : theme.darkSquare;
    if (isSelected) {
      squareColor = theme.accentColor.withOpacity(0.60);
    } else if (isLastMoveSource || isLastMoveDest) {
      squareColor = theme.accentColor.withOpacity(0.35);
    } else if (isKingInCheck) {
      squareColor = const Color(0xFFDC2626);
    }

    return GestureDetector(
      onTap: !interactive
          ? null
          : () {
              if (game.selectedSquare == null) {
                if (piece != null && piece.color == game.turn) {
                  game.selectSquare(pos);
                }
              } else {
                if (isLegalMoveTarget) {
                  final move = game.legalMovesForSelected.firstWhere((m) => m.to == pos);
                  game.makeMove(move);
                  SoundService.playMoveSound(isCapture: move.isCapture, isCheck: game.isKingInCheck(game.turn));
                  onMoveMade?.call(move);
                } else if (piece != null && piece.color == game.turn) {
                  game.selectSquare(pos);
                } else {
                  game.clearSelection();
                }
              }
            },
      child: Container(
        color: squareColor,
        child: Stack(
          children: [
            // Inside-Square Rank Coordinates
            if (showRankLabel)
              Positioned(
                top: 2,
                left: 3,
                child: Text(
                  rankText,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: coordColor.withOpacity(0.85),
                  ),
                ),
              ),

            // Inside-Square File Coordinates
            if (showFileLabel)
              Positioned(
                bottom: 2,
                right: 3,
                child: Text(
                  fileText,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: coordColor.withOpacity(0.85),
                  ),
                ),
              ),

            // Legal Move Target Indicators (Dot for empty, Ring for capture)
            if (isLegalMoveTarget)
              Center(
                child: piece == null
                    ? Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: theme.accentColor.withOpacity(0.55),
                          shape: BoxShape.circle,
                        ),
                      )
                    : Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.accentColor.withOpacity(0.80),
                            width: 3.5,
                          ),
                        ),
                      ),
              ),

            // Staunton HD Vector Piece
            if (piece != null)
              Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final pieceSize = constraints.maxWidth * 0.85;
                    return ChessPieceWidget(
                      piece: piece,
                      size: pieceSize,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestMoveOverlay(ChessGameState game, bool isFlipped, Color accentColor) {
    final fromPos = BoardPosition.fromAlgebraic(bestMoveUci!.substring(0, 2));
    final toPos = BoardPosition.fromAlgebraic(bestMoveUci!.substring(2, 4));
    if (fromPos == null || toPos == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final squareSize = constraints.maxWidth / 8.0;

        final fromDisplayCol = isFlipped ? 7 - fromPos.col : fromPos.col;
        final fromDisplayRow = isFlipped ? 7 - fromPos.row : fromPos.row;

        final toDisplayCol = isFlipped ? 7 - toPos.col : toPos.col;
        final toDisplayRow = isFlipped ? 7 - toPos.row : toPos.row;

        final fromCenter = Offset(
          fromDisplayCol * squareSize + squareSize / 2,
          fromDisplayRow * squareSize + squareSize / 2,
        );
        final toCenter = Offset(
          toDisplayCol * squareSize + squareSize / 2,
          toDisplayRow * squareSize + squareSize / 2,
        );

        return IgnorePointer(
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _BestMoveArrowPainter(
              from: fromCenter,
              to: toCenter,
              color: accentColor,
            ),
          ),
        );
      },
    );
  }
}

class _BestMoveArrowPainter extends CustomPainter {
  final Offset from;
  final Offset to;
  final Color color;

  _BestMoveArrowPainter({
    required this.from,
    required this.to,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance < 4) return;

    final angle = math.atan2(dy, dx);
    const arrowHeadLength = 16.0;

    // Shorten end point slightly so arrow head sits right on target
    final shortenedTo = Offset(
      to.dx - math.cos(angle) * (arrowHeadLength * 0.4),
      to.dy - math.sin(angle) * (arrowHeadLength * 0.4),
    );

    // Glowing shaft line
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(from, shortenedTo, glowPaint);

    final linePaint = Paint()
      ..color = color.withOpacity(0.9)
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(from, shortenedTo, linePaint);

    // Source ring
    final circlePaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(from, 7, circlePaint);

    // Arrow head
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const arrowWidth = 11.0;

    final p1 = to;
    final p2 = Offset(
      to.dx - arrowHeadLength * math.cos(angle) + arrowWidth * math.cos(angle + math.pi / 2),
      to.dy - arrowHeadLength * math.sin(angle) + arrowWidth * math.sin(angle + math.pi / 2),
    );
    final p3 = Offset(
      to.dx - arrowHeadLength * math.cos(angle) - arrowWidth * math.cos(angle + math.pi / 2),
      to.dy - arrowHeadLength * math.sin(angle) - arrowWidth * math.sin(angle + math.pi / 2),
    );

    path.moveTo(p1.dx, p1.dy);
    path.lineTo(p2.dx, p2.dy);
    path.lineTo(p3.dx, p3.dy);
    path.close();

    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _BestMoveArrowPainter oldDelegate) =>
      oldDelegate.from != from || oldDelegate.to != to || oldDelegate.color != color;
}
