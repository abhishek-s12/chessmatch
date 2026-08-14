import 'package:flutter_test/flutter_test.dart';
import 'package:chess_engine_app/services/opening_book_service.dart';

void main() {
  group('OpeningBookService Tests', () {
    final book = OpeningBookService();

    test('Identifies standard starting position in book', () {
      const startingFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
      expect(book.isInBook(startingFen), true);

      final move = book.findBookMove(startingFen);
      expect(move, isNotNull);
      expect(['e2e4', 'd2d4', 'c2c4', 'g1f3'].contains(move!.moveUci), true);
    });

    test('Identifies 1. e4 response in book', () {
      const e4Fen = 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1';
      expect(book.isInBook(e4Fen), true);

      final move = book.findBookMove(e4Fen);
      expect(move, isNotNull);
      expect(['c7c5', 'e7e5', 'e7e6', 'c7c6', 'd7d5', 'g8f6', 'd7d6'].contains(move!.moveUci), true);
    });

    test('Returns null for arbitrary non-book endgame FEN', () {
      const endgameFen = '8/8/8/4k3/8/8/4K3/8 w - - 0 1';
      expect(book.isInBook(endgameFen), false);
      expect(book.findBookMove(endgameFen), isNull);
    });
  });
}
