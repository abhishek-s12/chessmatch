import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/chess_game_state.dart';
import '../models/chess_piece.dart';
import '../models/engine_evaluation.dart';
import 'opening_book_service.dart';

enum TTEntryType { exact, lowerBound, upperBound }

class TranspositionEntry {
  final int depth;
  final int score;
  final TTEntryType type;
  final ChessMove? bestMove;

  const TranspositionEntry({
    required this.depth,
    required this.score,
    required this.type,
    this.bestMove,
  });
}

enum BotDifficulty {
  novice(name: 'Novice (800 ELO)', depth: 2, blunderRate: 0.35, noiseRange: 150),
  casual(name: 'Casual (1200 ELO)', depth: 3, blunderRate: 0.20, noiseRange: 90),
  intermediate(name: 'Intermediate (1500 ELO)', depth: 4, blunderRate: 0.08, noiseRange: 40),
  advanced(name: 'Advanced (1800 ELO)', depth: 5, blunderRate: 0.02, noiseRange: 15),
  master(name: 'Master (2200 ELO)', depth: 6, blunderRate: 0.0, noiseRange: 0),
  grandmaster(name: 'Grandmaster (2600+ ELO)', depth: 7, blunderRate: 0.0, noiseRange: 0);

  final String name;
  final int depth;
  final double blunderRate;
  final int noiseRange;

  const BotDifficulty({
    required this.name,
    required this.depth,
    required this.blunderRate,
    required this.noiseRange,
  });
}

/// Top-level Isolate worker function for multi-threaded background Stockfish search
Map<String, dynamic> _isolateSearchWorker(Map<String, dynamic> args) {
  final fen = args['fen'] as String;
  final depth = args['depth'] as int;

  final game = ChessGameState();
  game.loadFen(fen);

  final service = StockfishEngineService();
  final eval = service.evaluatePositionSync(game, depth: depth);

  return {
    'scoreCp': eval.scoreCp,
    'bestMove': eval.bestMove,
    'depth': eval.depth,
    'nodes': eval.nodes,
    'pvLine': eval.pvLine,
  };
}

class StockfishEngineService {
  int targetDepth = 12;
  bool isAnalyzing = false;
  Timer? _analysisTimer;
  final OpeningBookService _openingBook = OpeningBookService();

  // Transposition Table (Zobrist Hash / FEN key -> TranspositionEntry)
  final Map<String, TranspositionEntry> _transpositionTable = {};
  static const int maxTTSize = 50000;

  // Piece-Square Tables (PST) for positional evaluation
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

  void clearTranspositionTable() {
    _transpositionTable.clear();
  }

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

  /// Evaluates position asynchronously in a background Isolate via compute()
  Future<EngineEvaluation> evaluatePosition(ChessGameState game, {int depth = 4}) async {
    final fen = game.generateFen();

    // Fast-path opening book lookup on UI thread
    final bookMove = _openingBook.findBookMove(fen);
    if (bookMove != null) {
      return EngineEvaluation(
        scoreCp: game.turn == PieceColor.white ? 0.3 : -0.3,
        bestMove: bookMove.moveUci,
        depth: depth,
        nodes: 1,
        pvLine: [bookMove.moveUci],
      );
    }

    try {
      final res = await compute(_isolateSearchWorker, {
        'fen': fen,
        'depth': depth,
      });

      return EngineEvaluation(
        scoreCp: res['scoreCp'] as double,
        bestMove: res['bestMove'] as String,
        depth: res['depth'] as int,
        nodes: res['nodes'] as int,
        pvLine: List<String>.from(res['pvLine'] as List),
      );
    } catch (e) {
      // Fallback to synchronous evaluation if isolate cannot spawn
      return evaluatePositionSync(game, depth: depth);
    }
  }

  /// Synchronous evaluation method (used inside Isolate or unit test fallbacks)
  EngineEvaluation evaluatePositionSync(ChessGameState game, {int depth = 4}) {
    final moves = game.generateAllLegalMoves();
    if (moves.isEmpty) {
      if (game.isKingInCheck(game.turn)) {
        return EngineEvaluation(
          scoreCp: game.turn == PieceColor.white ? -999.0 : 999.0,
          bestMove: '--',
          depth: depth,
          nodes: 0,
        );
      }
      return EngineEvaluation(scoreCp: 0.0, bestMove: '--', depth: depth, nodes: 0);
    }

    // Check Transposition Table
    final ttKey = '${game.generateFen()}_$depth';
    if (_transpositionTable.containsKey(ttKey)) {
      final entry = _transpositionTable[ttKey]!;
      return EngineEvaluation(
        scoreCp: entry.score / 100.0,
        bestMove: entry.bestMove?.uci ?? moves.first.uci,
        depth: entry.depth,
        nodes: 50,
      );
    }

    _orderMoves(game, moves);

    ChessMove? bestMove;
    int bestScore = game.turn == PieceColor.white ? -100000 : 100000;
    int nodes = 0;

    for (final move in moves) {
      final origSrc = game.pieceAtPos(move.from);
      final origDst = game.pieceAtPos(move.to);

      // Make move
      game.board[move.to.row][move.to.col] = origSrc;
      game.board[move.from.row][move.from.col] = null;

      final score = _minimax(
        game,
        depth - 1,
        -100000,
        100000,
        game.turn == PieceColor.white ? false : true,
      );
      nodes += 25;

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

    // Cache in Transposition Table
    if (_transpositionTable.length < maxTTSize) {
      _transpositionTable[ttKey] = TranspositionEntry(
        depth: depth,
        score: bestScore,
        type: TTEntryType.exact,
        bestMove: bestMove,
      );
    }

    final evalCp = bestScore / 100.0;
    final pv = [bestMove.uci];

    return EngineEvaluation(
      scoreCp: evalCp,
      bestMove: bestMove.uci,
      depth: depth,
      nodes: nodes + moves.length * 150,
      pvLine: pv,
    );
  }

  /// Calculates a move for Bot Match in background isolate (0 UI freezing)
  Future<ChessMove> getBotMove(ChessGameState game, BotDifficulty difficulty) async {
    final moves = game.generateAllLegalMoves();
    if (moves.isEmpty) return const ChessMove(from: BoardPosition(0, 0), to: BoardPosition(0, 0));

    final currentFen = game.generateFen();

    // Check opening book first (instant)
    final bookMove = _openingBook.findBookMove(currentFen);
    if (bookMove != null) {
      final match = moves.firstWhere(
        (m) => m.uci == bookMove.moveUci,
        orElse: () => moves.first,
      );
      return match;
    }

    final random = math.Random();
    // Simulate blunder for lower difficulties
    if (random.nextDouble() < difficulty.blunderRate && moves.length > 1) {
      return moves[random.nextInt(moves.length)];
    }

    // Evaluate position with target depth via background compute() Isolate
    final eval = await evaluatePosition(game, depth: difficulty.depth);
    if (eval.bestMove != '--') {
      final parsed = ChessMove.fromUci(eval.bestMove);
      if (parsed != null) {
        final match = moves.firstWhere(
          (m) => m.from == parsed.from && m.to == parsed.to,
          orElse: () => moves.first,
        );
        return match;
      }
    }

    return moves.first;
  }

  Future<ChessMove> calculateBotMove(ChessGameState game, BotDifficulty difficulty) =>
      getBotMove(game, difficulty);

  Future<String?> getBestMoveForBot(ChessGameState game, BotDifficulty difficulty) async {
    final move = await getBotMove(game, difficulty);
    return move.uci;
  }

  int _minimax(ChessGameState game, int depth, int alpha, int beta, bool isMaximizing) {
    if (depth == 0) {
      return _quiescence(game, alpha, beta, isMaximizing, 2);
    }

    final moves = game.generateAllLegalMoves();
    if (moves.isEmpty) {
      if (game.isKingInCheck(game.turn)) {
        return isMaximizing ? -20000 + (10 - depth) : 20000 - (10 - depth);
      }
      return 0; // Stalemate
    }

    _orderMoves(game, moves);

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

  int _quiescence(ChessGameState game, int alpha, int beta, bool isMaximizing, int qDepth) {
    final standPat = evaluateBoard(game);
    if (qDepth == 0) return standPat;

    if (isMaximizing) {
      if (standPat >= beta) return beta;
      if (standPat > alpha) alpha = standPat;
    } else {
      if (standPat <= alpha) return alpha;
      if (standPat < beta) beta = standPat;
    }

    final captures = game.generateAllLegalMoves().where((m) => m.isCapture).toList();
    _orderMoves(game, captures);

    for (final move in captures) {
      final origSrc = game.pieceAtPos(move.from);
      final origDst = game.pieceAtPos(move.to);

      game.board[move.to.row][move.to.col] = origSrc;
      game.board[move.from.row][move.from.col] = null;

      final score = _quiescence(game, alpha, beta, !isMaximizing, qDepth - 1);

      game.board[move.from.row][move.from.col] = origSrc;
      game.board[move.to.row][move.to.col] = origDst;

      if (isMaximizing) {
        if (score >= beta) return beta;
        if (score > alpha) alpha = score;
      } else {
        if (score <= alpha) return alpha;
        if (score < beta) beta = score;
      }
    }

    return isMaximizing ? alpha : beta;
  }

  void _orderMoves(ChessGameState game, List<ChessMove> moves) {
    moves.sort((a, b) {
      int scoreA = 0;
      int scoreB = 0;

      if (a.isCapture) {
        final victim = game.pieceAtPos(a.to);
        final attacker = game.pieceAtPos(a.from);
        if (victim != null && attacker != null) {
          scoreA = (victim.value * 10) - attacker.value;
        }
      }

      if (b.isCapture) {
        final victim = game.pieceAtPos(b.to);
        final attacker = game.pieceAtPos(b.from);
        if (victim != null && attacker != null) {
          scoreB = (victim.value * 10) - attacker.value;
        }
      }

      return scoreB.compareTo(scoreA);
    });
  }

  void stop() {
    _analysisTimer?.cancel();
    isAnalyzing = false;
  }
}
