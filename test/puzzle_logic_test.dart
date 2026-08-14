import 'package:flutter_test/flutter_test.dart';
import 'package:chess_engine_app/models/chess_game_state.dart';
import 'package:chess_engine_app/models/chess_piece.dart';
import 'package:chess_engine_app/services/puzzle_service.dart';

void main() {
  group('PuzzleService Tests', () {
    final puzzleService = PuzzleService();

    test('Retrieves puzzles with valid solution moves and FEN', () {
      final puzzle = puzzleService.getPuzzleByIndex(0);
      expect(puzzle.solutionMoves.isNotEmpty, true);

      final game = ChessGameState();
      game.loadFen(puzzle.fen);
      expect(game.turn, PieceColor.white);

      final firstSolutionMove = ChessMove.fromUci(puzzle.solutionMoves.first);
      expect(firstSolutionMove, isNotNull);

      final legalMoves = game.generateAllLegalMoves();
      expect(legalMoves.any((m) => m.from == firstSolutionMove!.from && m.to == firstSolutionMove.to), true);
    });

    test('Streak and rating updates on success and failure', () {
      final puzzle = puzzleService.getPuzzleByIndex(0);
      final initialRating = puzzleService.userRating;

      puzzleService.onPuzzleSuccess(puzzle);
      expect(puzzleService.currentStreak, 1);
      expect(puzzleService.userRating, initialRating + 15);

      puzzleService.onPuzzleFailure(puzzle);
      expect(puzzleService.currentStreak, 0);
    });
  });
}
