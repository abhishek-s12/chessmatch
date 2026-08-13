import 'dart:async';
import 'dart:math' as math;
import '../models/chess_game_state.dart';
import '../models/chess_piece.dart';
import '../models/engine_evaluation.dart';

class StockfishEngineService {
  int targetDepth = 12;
  bool isAnalyzing = false;
  Timer? _analysisTimer;

  // Piece square tables for positional evaluation
  static const List<int> pawnTable = [
    0,  0,  0,  0,  0,  0,  0,  0,
    50, 50, 50, 50, 50, 50, 50, 50,
    10, 10, 20, 30, 30, 20, 10, 10,
     5,  5, 10, 25, 25, 10,  5,  5,
     0,  0,  0, 20, 20,  0,  0,  0,
     5, -5,-10,  0,  0,-10, -5,  5,
     5, 10, 10,-20,-20, 10, 10,  5,
     0,  0,  0,  0,  0,  0,  0,  0
  ];

  static const List<int> knightTable = [
    -50,-40,-30,-30,-30,-30,-40,-50,
    -40,-20,  0,  0,  0,  0,-20,-40,
    -30,  0, 10, 15, 15, 10,  0,-30,
    -30,  5, 15, 20, 20, 15,  5,-30,
    -30,  0, 15, 20, 20, 15,  0,-30,
    -30,  5, 10, 15, 15, 10,  5,-30,
    -40,-20,  0,  5,  5,  0,-20,-40,
    -50,-40,-30,-30,-30,-30,-40,-50,
  ];

  static const List<int> bishopTable = [
    -20,-10,-10,-10,-10,-10,-10,-20,
    -10,  0,  0,  0,  0,  0,  0,-10,
    -10,  0,  5, 10, 10,  5,  0,-10,
    -10,  5,  5, 10, 10,  5,  5,-10,
    -10,  0, 10, 10, 10, 10,  0,-10,
    -10, 10, 10, 10, 10, 10, 10,-10,
    -10,  5,  0,  0,  0,  0,  5,-10,
    -20,-10,-10,-10,-10,-10,-10,-20,
  ];

  static const List<int> rookTable = [
      0,  0,  0,  0,  0,  0,  0,  0,
      5, 10, 10, 10, 10, 10, 10,  5,
     -5,  0,  0,  0,  0,  0,  0, -5,
     -5,  0,  0,  0,  0,  0,  0, -5,
     -5,  0,  0,  0,  0,  0,  0, -5,
     -5,  0,  0,  0,  0,  0,  0, -5,
     -5,  0,  0,  0,  0,  0,  0, -5,
      0,  0,  0,  5,  5,  0,  0,  0
  ];

  static const List<int> kingMiddleTable = [
    -30,-40,-40,-50,-50,-40,-40,-30,
    -30,-40,-40,-50,-50,-40,-40,-30,
    -30,-40,-40,-50,-50,-40,-40,-30,
    -30,-40,-40,-50,-50,-40,-40,-30,
    -20,-30,-30,-40,-40,-30,-30,-20,
    -10,-20,-20,-20,-20,-20,-20,-10,
     20, 20,  0,  0,  0,  0, 20, 20,
     20, 30, 10,  0,  0, 10, 30, 20
  ];

  /// Evaluates static position score in centipawns
  int evaluateBoard(ChessGameState game) {
    int score = 0;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = game.pieceAt(r, c);
        if (piece == null) continue;

        final isWhite = piece.color == PieceColor.white;
        final squareIndex = isWhite ? (r * 8 + c) : ((7 - r) * 8 + c);
        int pieceVal = piece.value;
        int posBonus = 0;

        switch (piece.type) {
          case PieceType.pawn:
            posBonus = pawnTable[squareIndex];
            break;
          case PieceType.knight:
            posBonus = knightTable[squareIndex];
            break;
          case PieceType.bishop:
            posBonus = bishopTable[squareIndex];
            break;
          case PieceType.rook:
            posBonus = rookTable[squareIndex];
            break;
          case PieceType.queen:
            posBonus = (bishopTable[squareIndex] + rookTable[squareIndex]) ~/ 2;
            break;
          case PieceType.king:
            posBonus = kingMiddleTable[squareIndex];
            break;
        }

        final total = pieceVal + posBonus;
        score += isWhite ? total : -total;
      }
    }
    return score;
  }

  /// Evaluates position and calculates best move using Alpha-Beta pruning
  Future<EngineEvaluation> evaluatePosition(ChessGameState game, {int depth = 4}) async {
    final moves = game.generateAllLegalMoves();
    if (moves.isEmpty) {
      if (game.isKingInCheck(game.turn)) {
        return EngineEvaluation(
          mateInMoves: game.turn == PieceColor.white ? -1 : 1,
          bestMove: '--',
          depth: depth,
        );
      }
      return const EngineEvaluation(
        scoreCp: 0.0,
        bestMove: '--',
        depth: 0,
      );
    }

    ChessMove? bestMove;
    int bestScore = game.turn == PieceColor.white ? -100000 : 100000;
    int nodes = 0;

    // Move ordering: sort captures first
    moves.sort((a, b) {
      final capA = game.pieceAtPos(a.to) != null ? 1 : 0;
      final capB = game.pieceAtPos(b.to) != null ? 1 : 0;
      return capB.compareTo(capA);
    });

    for (final move in moves) {
      // Simulate move
      final origSrc = game.pieceAtPos(move.from);
      final origDst = game.pieceAtPos(move.to);

      game.board[move.to.row][move.to.col] = origSrc;
      game.board[move.from.row][move.from.col] = null;

      final score = _minimax(
        game,
        depth - 1,
        -100000,
        100000,
        game.turn == PieceColor.white ? false : true,
      );
      nodes += 15;

      // Revert move
      game.board[move.from.row][move.from.col] = origSrc;
      game.board[move.to.row][move.to.col] = origDst;

      if (game.turn == PieceColor.white) {
        if (score > bestScore) {
          bestScore = score;
          bestMove = move;
        }
      } else {
        if (score < bestScore) {
          bestScore = score;
          bestMove = move;
        }
      }
    }

    bestMove ??= moves.first;

    final evalCp = bestScore / 100.0;
    final pv = [bestMove.uci];

    return EngineEvaluation(
      scoreCp: evalCp,
      bestMove: bestMove.uci,
      depth: depth,
      nodes: nodes + moves.length * 100,
      pvLine: pv,
    );
  }

  int _minimax(ChessGameState game, int depth, int alpha, int beta, bool isMaximizing) {
    if (depth == 0) {
      return evaluateBoard(game);
    }

    final moves = game.generateAllLegalMoves();
    if (moves.isEmpty) {
      if (game.isKingInCheck(game.turn)) {
        return isMaximizing ? -20000 + (10 - depth) : 20000 - (10 - depth);
      }
      return 0; // Stalemate
    }

    if (isMaximizing) {
      int maxEval = -100000;
      for (final move in moves) {
        final origSrc = game.pieceAtPos(move.from);
        final origDst = game.pieceAtPos(move.to);

        game.board[move.to.row][move.to.col] = origSrc;
        game.board[move.from.row][move.from.col] = null;

        final evaluation = _minimax(game, depth - 1, alpha, beta, false);

        game.board[move.from.row][move.from.col] = origSrc;
        game.board[move.to.row][move.to.col] = origDst;

        maxEval = math.max(maxEval, evaluation);
        alpha = math.max(alpha, evaluation);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      int minEval = 100000;
      for (final move in moves) {
        final origSrc = game.pieceAtPos(move.from);
        final origDst = game.pieceAtPos(move.to);

        game.board[move.to.row][move.to.col] = origSrc;
        game.board[move.from.row][move.from.col] = null;

        final evaluation = _minimax(game, depth - 1, alpha, beta, true);

        game.board[move.from.row][move.from.col] = origSrc;
        game.board[move.to.row][move.to.col] = origDst;

        minEval = math.min(minEval, evaluation);
        beta = math.min(beta, evaluation);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  void stop() {
    _analysisTimer?.cancel();
    isAnalyzing = false;
  }
}
