import 'package:flutter_test/flutter_test.dart';
import 'package:chess_engine_app/models/chess_game_state.dart';
import 'package:chess_engine_app/models/chess_piece.dart';
import 'package:chess_engine_app/services/stockfish_engine_service.dart';

void main() {
  group('Chess Logic & Rules Tests', () {
    test('Initial board state and FEN match standard starting position', () {
      final game = ChessGameState();
      expect(game.turn, PieceColor.white);
      expect(game.generateFen(), ChessGameState.startingFen);
      expect(game.isKingInCheck(PieceColor.white), false);
      expect(game.isKingInCheck(PieceColor.black), false);
    });

    test('White pawn opening move e2 to e4', () {
      final game = ChessGameState();
      final e2 = BoardPosition.fromAlgebraic('e2')!;
      final e4 = BoardPosition.fromAlgebraic('e4')!;

      final moves = game.generateLegalMovesForPiece(e2);
      expect(moves.any((m) => m.to == e4), true);

      final success = game.makeMove(ChessMove(from: e2, to: e4));
      expect(success, true);
      expect(game.turn, PieceColor.black);
      expect(game.pieceAtPos(e4)?.type, PieceType.pawn);
      expect(game.pieceAtPos(e4)?.color, PieceColor.white);
      expect(game.pieceAtPos(e2), null);
    });

    test('Scholar\'s Mate checkmate detection', () {
      final game = ChessGameState();
      // 1. e4 e5
      game.makeMove(ChessMove(
        from: BoardPosition.fromAlgebraic('e2')!,
        to: BoardPosition.fromAlgebraic('e4')!,
      ));
      game.makeMove(ChessMove(
        from: BoardPosition.fromAlgebraic('e7')!,
        to: BoardPosition.fromAlgebraic('e5')!,
      ));

      // 2. Bc4 Nc6
      game.makeMove(ChessMove(
        from: BoardPosition.fromAlgebraic('f1')!,
        to: BoardPosition.fromAlgebraic('c4')!,
      ));
      game.makeMove(ChessMove(
        from: BoardPosition.fromAlgebraic('b8')!,
        to: BoardPosition.fromAlgebraic('c6')!,
      ));

      // 3. Qh5 Nf6
      game.makeMove(ChessMove(
        from: BoardPosition.fromAlgebraic('d1')!,
        to: BoardPosition.fromAlgebraic('h5')!,
      ));
      game.makeMove(ChessMove(
        from: BoardPosition.fromAlgebraic('g8')!,
        to: BoardPosition.fromAlgebraic('f6')!,
      ));

      // 4. Qxf7# (Checkmate)
      game.makeMove(ChessMove(
        from: BoardPosition.fromAlgebraic('h5')!,
        to: BoardPosition.fromAlgebraic('f7')!,
      ));

      expect(game.isKingInCheck(PieceColor.black), true);
      expect(game.isCheckmate, true);
    });
  });

  group('Engine Evaluation Tests', () {
    test('Stockfish engine computes best move for starting position', () async {
      final game = ChessGameState();
      final engine = StockfishEngineService();

      final eval = await engine.evaluatePosition(game, depth: 3);
      expect(eval.bestMove.isNotEmpty, true);
      expect(eval.bestMove, isNot('--'));
      expect(eval.pvLine.isNotEmpty, true);
    });
  });
}
