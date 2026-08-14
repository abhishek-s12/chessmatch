import 'package:flutter_test/flutter_test.dart';
import 'package:chess_engine_app/models/chess_game_state.dart';
import 'package:chess_engine_app/services/game_review_service.dart';

void main() {
  group('GameReviewService Tests', () {
    test('Analyzes played game and computes move classifications and accuracy', () async {
      final game = ChessGameState();
      final reviewer = GameReviewService();

      // Play 2 quick moves
      final moves = game.generateAllLegalMoves();
      game.makeMove(moves.first);
      final reply = game.generateAllLegalMoves().first;
      game.makeMove(reply);

      final report = await reviewer.analyzeGame(game);
      expect(report.moves.length, 2);
      expect(report.whiteAccuracy >= 0 && report.whiteAccuracy <= 100, true);
      expect(report.blackAccuracy >= 0 && report.blackAccuracy <= 100, true);
      expect(report.evalTimeline.length, 2);
    });
  });
}
