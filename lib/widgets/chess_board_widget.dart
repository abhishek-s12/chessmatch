import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chess_game_state.dart';
import '../models/chess_piece.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'chess_piece_painter.dart';

class ChessBoardWidget extends StatefulWidget {
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
  State<ChessBoardWidget> createState() => _ChessBoardWidgetState();
}

class _ChessBoardWidgetState extends State<ChessBoardWidget> with SingleTickerProviderStateMixin {
  BoardPosition? _draggingPosition;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<ChessGameState>();
    final isFlipped = game.isFlipped;
    final boardTheme = AppTheme.activeBoardTheme;

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        // Flat, square-cornered, shadowless Chess.com grid chrome
        decoration: BoxDecoration(
          color: boardTheme.darkSquare,
          border: Border.all(color: const Color(0xFF3B3935), width: 1.0),
        ),
        child: Stack(
          children: [
            // 8x8 Chess.com Grid
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
            if (widget.bestMoveUci != null && widget.bestMoveUci!.length >= 4)
              _buildBestMoveOverlay(game, isFlipped, const Color(0xFF81B64C)),
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

    final isLastMoveSource = game.moveHistory.isNotEmpty && game.moveHistory.last.from == pos;
    final isLastMoveDest = game.moveHistory.isNotEmpty && game.moveHistory.last.to == pos;

    final showRankLabel = isFlipped ? (displayCol == 7) : (displayCol == 0);
    final showFileLabel = isFlipped ? (displayRow == 0) : (displayRow == 7);
    final rankText = (isFlipped ? (pos.row + 1) : (8 - pos.row)).toString();
    final fileText = String.fromCharCode('a'.codeUnitAt(0) + pos.col);
    final coordColor = isLight ? theme.coordinateLight : theme.coordinateDark;

    Color squareColor = isLight ? theme.lightSquare : theme.darkSquare;
    if (isSelected) {
      squareColor = theme.accentColor.withOpacity(0.65);
    } else if (isLastMoveSource || isLastMoveDest) {
      squareColor = theme.accentColor.withOpacity(0.40);
    } else if (isKingInCheck) {
      squareColor = const Color(0xFFDC2626);
    }

    final isBeingDragged = _draggingPosition == pos;

    // DragTarget wrapper so this square can receive a dropped piece
    return DragTarget<BoardPosition>(
      onWillAcceptWithDetails: (details) {
        if (!widget.interactive) return false;
        final fromPos = details.data;
        if (fromPos == pos) return false;
        final legalMoves = game.generateLegalMovesForPiece(fromPos);
        return legalMoves.any((m) => m.to == pos);
      },
      onAcceptWithDetails: (details) {
        final fromPos = details.data;
        final legalMoves = game.generateLegalMovesForPiece(fromPos);
        final matching = legalMoves.where((m) => m.to == pos);
        if (matching.isNotEmpty) {
          final move = matching.first;
          game.makeMove(move);
          SoundService.playMoveSound(isCapture: move.isCapture, isCheck: game.isKingInCheck(game.turn));
          widget.onMoveMade?.call(move);
        }
        setState(() {
          _draggingPosition = null;
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        final displayColor = isHovered ? theme.accentColor.withOpacity(0.50) : squareColor;

        return GestureDetector(
          onTap: !widget.interactive
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
                      widget.onMoveMade?.call(move);
                    } else if (piece != null && piece.color == game.turn) {
                      game.selectSquare(pos);
                    } else {
                      game.clearSelection();
                    }
                  }
                },
          child: Container(
            color: displayColor,
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
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: coordColor,
                      ),
                    ),
                  ),

                // Inside-Square File Coordinates
                if (showFileLabel)
                  Positioned(
                    bottom: 1,
                    right: 3,
                    child: Text(
                      fileText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: coordColor,
                      ),
                    ),
                  ),

                // Legal Move Target Highlight Dot or Capture Ring
                if (isLegalMoveTarget && !isBeingDragged)
                  Center(
                    child: piece != null
                        ? Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black.withOpacity(0.25),
                                width: 5.0,
                              ),
                            ),
                          )
                        : Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.20),
                            ),
                          ),
                  ),

                // Piece Rendering with Drag-and-Drop & Slide Animation
                if (piece != null && !isBeingDragged)
                  Center(
                    child: widget.interactive && piece.color == game.turn
                        ? Draggable<BoardPosition>(
                            data: pos,
                            onDragStarted: () {
                              setState(() {
                                _draggingPosition = pos;
                              });
                              game.selectSquare(pos);
                            },
                            onDragEnd: (_) {
                              setState(() {
                                _draggingPosition = null;
                              });
                            },
                            feedback: Material(
                              color: Colors.transparent,
                              child: Transform.scale(
                                scale: 1.15,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.4),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ChessPieceWidget(
                                    piece: piece,
                                    size: 48,
                                  ),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.25,
                              child: ChessPieceWidget(
                                piece: piece,
                                size: 42,
                              ),
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeOutCubic,
                              child: ChessPieceWidget(
                                piece: piece,
                                size: 42,
                              ),
                            ),
                          )
                        : AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOutCubic,
                            child: ChessPieceWidget(
                              piece: piece,
                              size: 42,
                            ),
                          ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBestMoveOverlay(ChessGameState game, bool isFlipped, Color accentColor) {
    if (widget.bestMoveUci == null || widget.bestMoveUci!.length < 4) return const SizedBox.shrink();

    final fromCol = widget.bestMoveUci!.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final fromRow = 8 - int.parse(widget.bestMoveUci![1]);
    final toCol = widget.bestMoveUci!.codeUnitAt(2) - 'a'.codeUnitAt(0);
    final toRow = 8 - int.parse(widget.bestMoveUci![3]);

    if (fromCol < 0 || fromCol > 7 ||
        fromRow < 0 || fromRow > 7 ||
        toCol < 0 || toCol > 7 ||
        toRow < 0 || toRow > 7) {
      return const SizedBox.shrink();
    }

    final startX = (isFlipped ? 7 - fromCol : fromCol) + 0.5;
    final startY = (isFlipped ? 7 - fromRow : fromRow) + 0.5;
    final endX = (isFlipped ? 7 - toCol : toCol) + 0.5;
    final endY = (isFlipped ? 7 - toRow : toRow) + 0.5;

    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _MoveArrowPainter(
          start: Offset(startX / 8.0, startY / 8.0),
          end: Offset(endX / 8.0, endY / 8.0),
          color: const Color(0xFF81B64C),
        ),
      ),
    );
  }
}

class _MoveArrowPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;

  _MoveArrowPainter({
    required this.start,
    required this.end,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Offset(start.dx * size.width, start.dy * size.height);
    final p2 = Offset(end.dx * size.width, end.dy * size.height);

    final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
    final arrowLength = 16.0;
    final arrowWidth = 12.0;

    final shaftEnd = Offset(
      p2.dx - arrowLength * math.cos(angle) * 0.8,
      p2.dy - arrowLength * math.sin(angle) * 0.8,
    );

    final linePaint = Paint()
      ..color = color.withOpacity(0.85)
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(p1, shaftEnd, linePaint);

    final headPath = Path();
    final pLeft = Offset(
      p2.dx - arrowLength * math.cos(angle) + arrowWidth * math.sin(angle),
      p2.dy - arrowLength * math.sin(angle) - arrowWidth * math.cos(angle),
    );
    final pRight = Offset(
      p2.dx - arrowLength * math.cos(angle) - arrowWidth * math.sin(angle),
      p2.dy - arrowLength * math.sin(angle) + arrowWidth * math.cos(angle),
    );

    headPath.moveTo(p2.dx, p2.dy);
    headPath.lineTo(pLeft.dx, pLeft.dy);
    headPath.lineTo(pRight.dx, pRight.dy);
    headPath.close();

    final headPaint = Paint()
      ..color = color.withOpacity(0.95)
      ..style = PaintingStyle.fill;

    canvas.drawPath(headPath, headPaint);
  }

  @override
  bool shouldRepaint(covariant _MoveArrowPainter oldDelegate) =>
      oldDelegate.start != start || oldDelegate.end != end || oldDelegate.color != color;
}
