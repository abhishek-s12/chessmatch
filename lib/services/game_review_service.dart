import 'dart:math' as math;
import '../models/chess_game_state.dart';
import '../models/chess_piece.dart';
import 'opening_book_service.dart';
import 'stockfish_engine_service.dart';

enum MoveClassification {
  brilliant(name: 'Brilliant', symbol: '!!', colorHex: 0xFF1BACA6),
  great(name: 'Great', symbol: '!', colorHex: 0xFF5C8BB0),
  best(name: 'Best', symbol: '★', colorHex: 0xFF81B64C),
  excellent(name: 'Excellent', symbol: '✓', colorHex: 0xFF96BC4B),
  book(name: 'Book', symbol: '📖', colorHex: 0xFFC3996B),
  inaccuracy(name: 'Inaccuracy', symbol: '?!', colorHex: 0xFFF7C631),
  mistake(name: 'Mistake', symbol: '?', colorHex: 0xFFE6912C),
  missedWin(name: 'Missed Win', symbol: '❌', colorHex: 0xFFDB5353),
  blunder(name: 'Blunder', symbol: '??', colorHex: 0xFFFA412D);

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
        final isTopEngine = playedUci == bestMoveUci;
        final diff = isWhite ? (evalBefore.scoreCp - evalAfter.scoreCp) : (evalAfter.scoreCp - evalBefore.scoreCp);
        final evalBeforeWinning = isWhite ? evalBefore.scoreCp > 3.0 : evalBefore.scoreCp < -3.0;
        final evalAfterLost = isWhite ? evalAfter.scoreCp < 0.5 : evalAfter.scoreCp > -0.5;

        if (isTopEngine) {
          // Check for brilliant sacrifice: moved a valuable piece into capture or sacrificed material
          final movedPiece = tempGame.pieceAtPos(move.from);
          final capturedPiece = tempGame.pieceAtPos(move.to);
          final isSacrifice = movedPiece != null &&
              (movedPiece.type == PieceType.queen || movedPiece.type == PieceType.rook || movedPiece.type == PieceType.bishop || movedPiece.type == PieceType.knight) &&
              (capturedPiece == null || capturedPiece.value < movedPiece.value) &&
              (isWhite ? evalAfter.scoreCp > 1.5 : evalAfter.scoreCp < -1.5);

          if (isSacrifice) {
            classification = MoveClassification.brilliant;
            explanation = 'Brilliant sacrifice (!!)! You found the winning tactical sequence.';
          } else if (diff < -0.4) {
            classification = MoveClassification.great;
            explanation = 'Great find (!). The only critical path to keep the advantage.';
          } else {
            classification = MoveClassification.best;
            explanation = 'The engine\'s #1 best move (★).';
          }
        } else {
          if (evalBeforeWinning && evalAfterLost && diff > 2.0) {
            classification = MoveClassification.missedWin;
            explanation = 'Missed win (❌). You had a winning advantage; $bestMoveUci won immediately.';
          } else if (diff <= 0.25) {
            classification = MoveClassification.excellent;
            explanation = 'An excellent move (✓) preserving positional control.';
          } else if (diff <= 0.9) {
            classification = MoveClassification.inaccuracy;
            explanation = 'An inaccuracy (?!). Engine preferred $bestMoveUci.';
          } else if (diff <= 2.2) {
            classification = MoveClassification.mistake;
            explanation = 'A mistake (?). Shifts the momentum towards your opponent.';
          } else {
            classification = MoveClassification.blunder;
            explanation = 'A serious blunder (??). $bestMoveUci was essential.';
          }
        }
      }

      // Calculate CAPS move accuracy (0% - 100%)
      double moveAccuracy = 100.0;
      if (classification == MoveClassification.brilliant) moveAccuracy = 100.0;
      if (classification == MoveClassification.great) moveAccuracy = 98.0;
      if (classification == MoveClassification.best) moveAccuracy = 96.0;
      if (classification == MoveClassification.excellent) moveAccuracy = 90.0;
      if (classification == MoveClassification.book) moveAccuracy = 100.0;
      if (classification == MoveClassification.inaccuracy) moveAccuracy = 60.0;
      if (classification == MoveClassification.mistake) moveAccuracy = 30.0;
      if (classification == MoveClassification.missedWin) moveAccuracy = 15.0;
      if (classification == MoveClassification.blunder) moveAccuracy = 5.0;

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
