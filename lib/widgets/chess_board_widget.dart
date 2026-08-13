import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chess_game_state.dart';
import '../models/chess_piece.dart';
import '../theme/app_theme.dart';

class ChessBoardWidget extends StatelessWidget {
  final String? bestMoveUci;
  final Function(ChessMove)? onMoveMade;

  const ChessBoardWidget({
    super.key,
    this.bestMoveUci,
    this.onMoveMade,
  });

  @override
  Widget build(BuildContext context) {
    final game = context.watch<ChessGameState>();
    final isFlipped = game.isFlipped;

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // 8x8 Squares Grid
            Column(
              children: List.generate(8, (displayRow) {
                final actualRow = isFlipped ? 7 - displayRow : displayRow;
                return Expanded(
                  child: Row(
                    children: List.generate(8, (displayCol) {
                      final actualCol = isFlipped ? 7 - displayCol : displayCol;
                      final pos = BoardPosition(actualRow, actualCol);
                      return Expanded(
                        child: _buildSquare(context, game, pos, displayRow, displayCol),
                      );
                    }),
                  ),
                );
              }),
            ),

            // Rank and File Coordinate Indicators
            _buildCoordinates(isFlipped),

            // Best Move Arrow / Overlay Indicator
            if (bestMoveUci != null && bestMoveUci!.length >= 4)
              _buildBestMoveOverlay(game, isFlipped),
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
  ) {
    final isLight = (pos.row + pos.col) % 2 == 0;
    final isSelected = game.selectedSquare == pos;
    final isLegalMoveTarget = game.legalMovesForSelected.any((m) => m.to == pos);
    final piece = game.pieceAtPos(pos);
    final isKingInCheck = piece != null &&
        piece.type == PieceType.king &&
        piece.color == game.turn &&
        game.isKingInCheck(game.turn);

    // Background color
    Color squareColor = isLight ? AppTheme.lightSquareCyber : AppTheme.darkSquareCyber;
    if (isSelected) {
      squareColor = const Color(0xFF007799);
    } else if (isKingInCheck) {
      squareColor = const Color(0xFF7F1D1D);
    }

    return GestureDetector(
      onTap: () {
        final selected = game.selectedSquare;
        if (selected != null) {
          final move = game.legalMovesForSelected.firstWhere(
            (m) => m.to == pos,
            orElse: () => const ChessMove(
              from: BoardPosition(-1, -1),
              to: BoardPosition(-1, -1),
            ),
          );
          if (move.from.row != -1) {
            game.selectSquare(pos);
            onMoveMade?.call(move);
            return;
          }
        }
        game.selectSquare(pos);
      },
      child: Container(
        color: squareColor,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Legal move destination dot or capture ring
            if (isLegalMoveTarget)
              Container(
                width: piece != null ? 36 : 14,
                height: piece != null ? 36 : 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: piece != null ? Colors.transparent : AppTheme.primaryNeon.withOpacity(0.6),
                  border: piece != null
                      ? Border.all(color: AppTheme.primaryNeon, width: 3)
                      : null,
                ),
              ),

            // Piece symbol
            if (piece != null)
              Text(
                piece.symbol,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: piece.color == PieceColor.white ? Colors.white : const Color(0xFF1E293B),
                  shadows: [
                    Shadow(
                      color: piece.color == PieceColor.white
                          ? Colors.cyan.withOpacity(0.8)
                          : Colors.black.withOpacity(0.9),
                      blurRadius: piece.color == PieceColor.white ? 8 : 4,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoordinates(bool isFlipped) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // File letters along bottom
            Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                children: List.generate(8, (i) {
                  final fileChar = String.fromCharCode('a'.codeUnitAt(0) + (isFlipped ? 7 - i : i));
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 3, bottom: 2),
                      child: Text(
                        fileChar,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMuted.withOpacity(0.7),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // Rank numbers along left
            Align(
              alignment: Alignment.topLeft,
              child: Column(
                children: List.generate(8, (i) {
                  final rankNum = (isFlipped ? i + 1 : 8 - i).toString();
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 3, top: 2),
                      child: Text(
                        rankNum,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMuted.withOpacity(0.7),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestMoveOverlay(ChessGameState game, bool isFlipped) {
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
              color: AppTheme.secondaryNeon,
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
    final paint = Paint()
      ..color = color.withOpacity(0.85)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw main shaft line
    canvas.drawLine(from, to, paint);

    // Draw source ring
    final circlePaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(from, 8, circlePaint);

    // Draw arrowhead at target
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final angle = (Offset(dx, dy).direction);

    final path = Path();
    const arrowLength = 16.0;
    const arrowWidth = 10.0;

    final p1 = to;
    final p2 = Offset(
      to.dx - arrowLength * (Offset.fromDirection(angle).dx) + arrowWidth * (Offset.fromDirection(angle + 1.57).dx),
      to.dy - arrowLength * (Offset.fromDirection(angle).dy) + arrowWidth * (Offset.fromDirection(angle + 1.57).dy),
    );
    final p3 = Offset(
      to.dx - arrowLength * (Offset.fromDirection(angle).dx) - arrowWidth * (Offset.fromDirection(angle + 1.57).dx),
      to.dy - arrowLength * (Offset.fromDirection(angle).dy) - arrowWidth * (Offset.fromDirection(angle + 1.57).dy),
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
