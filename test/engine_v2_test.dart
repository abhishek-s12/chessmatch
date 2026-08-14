import 'package:flutter_test/flutter_test.dart';
import 'package:chess_engine_app/models/chess_game_state.dart';
import 'package:chess_engine_app/services/stockfish_engine_service.dart';

void main() {
  group('Engine 2.0 Feature Tests', () {
    test('Calculates bot move across different difficulties', () async {
      final game = ChessGameState();
      final engine = StockfishEngineService();

      for (final diff in BotDifficulty.values) {
        final move = await engine.getBotMove(game, diff);
        expect(move.uci.length, 4);
      }
    });

    test('Undo two moves reverts both player and engine move', () {
      final game = ChessGameState();
      final startFen = game.generateFen();

      // Make 2 moves
      final m1 = game.generateAllLegalMoves().first;
      game.makeMove(m1);
      final m2 = game.generateAllLegalMoves().first;
      game.makeMove(m2);

      expect(game.moveHistory.length, 2);
      final reverted = game.undoTwoMoves();
      expect(reverted, true);
      expect(game.moveHistory.length, 0);
      expect(game.generateFen(), startFen);
    });

    test('PGN generation formats valid move string', () {
      final game = ChessGameState();
      final m1 = game.generateAllLegalMoves().first;
      game.makeMove(m1);

      final pgn = game.generatePgn(white: 'Alice', black: 'Bob');
      expect(pgn.contains('[White "Alice"]'), true);
      expect(pgn.contains('[Black "Bob"]'), true);
      expect(pgn.contains('1. '), true);
    });
  });
}
