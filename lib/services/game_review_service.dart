import 'dart:math' as math;
import '../models/chess_game_state.dart';
import '../models/chess_piece.dart';
import 'opening_book_service.dart';
import 'stockfish_engine_service.dart';

enum MoveClassification {
  brilliant(name: 'Brilliant', symbol: '!!', colorHex: 0xFF22D3EE),
  best(name: 'Best', symbol: '!', colorHex: 0xFF10B981),
  excellent(name: 'Excellent', symbol: '✓', colorHex: 0xFF3B82F6),
  good(name: 'Good', symbol: '✓', colorHex: 0xFF60A5FA),
  book(name: 'Book', symbol: '📖', colorHex: 0xFFA855F7),
  inaccuracy(name: 'Inaccuracy', symbol: '?!', colorHex: 0xFFFBBF24),
  mistake(name: 'Mistake', symbol: '?', colorHex: 0xFFF97316),
  blunder(name: 'Blunder', symbol: '??', colorHex: 0xFFEF4444);

  final String name;
  final String symbol;
  final int colorHex;

  const MoveClassification({
    required this.name,
    required this.symbol,
    required this.colorHex,
  });
}

class ReviewedMove {
  final int moveIndex;
  final String san;
  final String uci;
  final String fenBefore;
  final String fenAfter;
  final double evalCp;
  final String bestMoveUci;
  final MoveClassification classification;
  final String explanation;
  final bool isWhite;

  const ReviewedMove({
    required this.moveIndex,
    required this.san,
    required this.uci,
    required this.fenBefore,
    required this.fenAfter,
    required this.evalCp,
    required this.bestMoveUci,
    required this.classification,
    required this.explanation,
    required this.isWhite,
  });
}

class GameReviewReport {
  final List<ReviewedMove> moves;
  final double whiteAccuracy;
  final double blackAccuracy;
  final Map<MoveClassification, int> whiteStats;
  final Map<MoveClassification, int> blackStats;
  final List<double> evalTimeline;

  const GameReviewReport({
    required this.moves,
    required this.whiteAccuracy,
    required this.blackAccuracy,
    required this.whiteStats,
    required this.blackStats,
    required this.evalTimeline,
  });
}

class GameReviewService {
  final StockfishEngineService _engine = StockfishEngineService();
  final OpeningBookService _openingBook = OpeningBookService();

  Future<GameReviewReport> analyzeGame(ChessGameState game) async {
    final fens = game.fenHistory;
    final moves = game.moveHistory;
    final sans = game.sanHistory;

    final reviewedMoves = <ReviewedMove>[];
    final evalTimeline = <double>[];

    final whiteStats = <MoveClassification, int>{
      for (final c in MoveClassification.values) c: 0,
    };
    final blackStats = <MoveClassification, int>{
      for (final c in MoveClassification.values) c: 0,
    };

    double whiteAccuracySum = 0;
    int whiteMovesCount = 0;
    double blackAccuracySum = 0;
    int blackMovesCount = 0;

    final tempGame = ChessGameState();

    for (int i = 0; i < moves.length; i++) {
      final fenBefore = fens[i];
      final fenAfter = fens[i + 1];
      final move = moves[i];
      final san = sans[i];
      final isWhite = i % 2 == 0;

      tempGame.loadFen(fenBefore);

      // 1. Calculate best move before player made move
      final evalBefore = await _engine.evaluatePosition(tempGame, depth: 3);
      final bestMoveUci = evalBefore.bestMove;

      tempGame.loadFen(fenAfter);
      final evalAfter = await _engine.evaluatePosition(tempGame, depth: 3);

      final evalCp = evalAfter.scoreCp;
      evalTimeline.add(evalCp);

      // Check if opening book move
      MoveClassification classification;
      String explanation;

      if (_openingBook.isInBook(fenBefore)) {
        classification = MoveClassification.book;
        explanation = 'Theoretical opening book line.';
      } else {
        final playedUci = move.uci;
        if (playedUci == bestMoveUci) {
          classification = MoveClassification.best;
          explanation = 'The top computer engine move.';
        } else {
          final diff = isWhite ? (evalBefore.scoreCp - evalAfter.scoreCp) : (evalAfter.scoreCp - evalBefore.scoreCp);

          if (diff <= 0.2) {
            classification = MoveClassification.excellent;
            explanation = 'A very solid move maintaining positional strength.';
          } else if (diff <= 0.5) {
            classification = MoveClassification.good;
            explanation = 'A playable move, though $bestMoveUci was slightly more active.';
          } else if (diff <= 1.2) {
            classification = MoveClassification.inaccuracy;
            explanation = 'An inaccuracy ($san). The engine favored $bestMoveUci.';
          } else if (diff <= 2.5) {
            classification = MoveClassification.mistake;
            explanation = 'A notable mistake that concedes advantage to opponent.';
          } else {
            classification = MoveClassification.blunder;
            explanation = 'A critical blunder ($san). $bestMoveUci was required.';
          }
        }
      }

      // Calculate CAPS move accuracy (0% - 100%)
      double moveAccuracy = 100.0;
      if (classification == MoveClassification.excellent) moveAccuracy = 95.0;
      if (classification == MoveClassification.good) moveAccuracy = 85.0;
      if (classification == MoveClassification.inaccuracy) moveAccuracy = 60.0;
      if (classification == MoveClassification.mistake) moveAccuracy = 35.0;
      if (classification == MoveClassification.blunder) moveAccuracy = 10.0;

      if (isWhite) {
        whiteStats[classification] = (whiteStats[classification] ?? 0) + 1;
        whiteAccuracySum += moveAccuracy;
        whiteMovesCount++;
      } else {
        blackStats[classification] = (blackStats[classification] ?? 0) + 1;
        blackAccuracySum += moveAccuracy;
        blackMovesCount++;
      }

      reviewedMoves.add(
        ReviewedMove(
          moveIndex: i,
          san: san,
          uci: move.uci,
          fenBefore: fenBefore,
          fenAfter: fenAfter,
          evalCp: evalCp,
          bestMoveUci: bestMoveUci,
          classification: classification,
          explanation: explanation,
          isWhite: isWhite,
        ),
      );
    }

    final whiteAcc = whiteMovesCount > 0 ? (whiteAccuracySum / whiteMovesCount) : 100.0;
    final blackAcc = blackMovesCount > 0 ? (blackAccuracySum / blackMovesCount) : 100.0;

    return GameReviewReport(
      moves: reviewedMoves,
      whiteAccuracy: double.parse(whiteAcc.toStringAsFixed(1)),
      blackAccuracy: double.parse(blackAcc.toStringAsFixed(1)),
      whiteStats: whiteStats,
      blackStats: blackStats,
      evalTimeline: evalTimeline,
    );
  }
}
