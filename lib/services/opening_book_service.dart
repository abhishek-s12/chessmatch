import 'dart:math' as math;

class OpeningMove {
  final String moveUci;
  final String openingName;
  final String eco;

  const OpeningMove({
    required this.moveUci,
    required this.openingName,
    required this.eco,
  });
}

class OpeningBookService {
  static final OpeningBookService _instance = OpeningBookService._internal();
  factory OpeningBookService() => _instance;
  OpeningBookService._internal();

  /// Map of FEN position prefix (pieces + turn + castling) to available book moves
  static final Map<String, List<OpeningMove>> _openingTree = {
    // Start position
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq': [
      const OpeningMove(moveUci: 'e2e4', openingName: "King's Pawn Opening", eco: 'B00'),
      const OpeningMove(moveUci: 'd2d4', openingName: "Queen's Pawn Opening", eco: 'A40'),
      const OpeningMove(moveUci: 'c2c4', openingName: 'English Opening', eco: 'A10'),
      const OpeningMove(moveUci: 'g1f3', openingName: 'Réti Opening', eco: 'A04'),
    ],

    // 1. e4
    'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq': [
      const OpeningMove(moveUci: 'c7c5', openingName: 'Sicilian Defense', eco: 'B20'),
      const OpeningMove(moveUci: 'e7e5', openingName: "Open Game (King's Pawn)", eco: 'C20'),
      const OpeningMove(moveUci: 'e7e6', openingName: 'French Defense', eco: 'C00'),
      const OpeningMove(moveUci: 'c7c6', openingName: 'Caro-Kann Defense', eco: 'B10'),
      const OpeningMove(moveUci: 'd7d5', openingName: 'Scandinavian Defense', eco: 'B01'),
      const OpeningMove(moveUci: 'g8f6', openingName: "Alekhine's Defense", eco: 'B02'),
      const OpeningMove(moveUci: 'd7d6', openingName: 'Pirc Defense', eco: 'B07'),
    ],

    // 1. d4
    'rnbqkbnr/pppppppp/8/8/3P4/8/PPP1PPPP/RNBQKBNR b KQkq': [
      const OpeningMove(moveUci: 'g8f6', openingName: 'Indian Defense', eco: 'A45'),
      const OpeningMove(moveUci: 'd7d5', openingName: "Closed Game (Queen's Pawn)", eco: 'D00'),
      const OpeningMove(moveUci: 'e7e6', openingName: 'Horwitz Defense', eco: 'A40'),
      const OpeningMove(moveUci: 'f7f5', openingName: 'Dutch Defense', eco: 'A80'),
    ],

    // 1. e4 e5
    'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq': [
      const OpeningMove(moveUci: 'g1f3', openingName: "King's Knight Opening", eco: 'C40'),
      const OpeningMove(moveUci: 'f2f4', openingName: "King's Gambit", eco: 'C30'),
      const OpeningMove(moveUci: 'b1c3', openingName: 'Vienna Game', eco: 'C25'),
      const OpeningMove(moveUci: 'f1c4', openingName: "Bishop's Opening", eco: 'C23'),
    ],

    // 1. e4 e5 2. Nf3
    'rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq': [
      const OpeningMove(moveUci: 'b8c6', openingName: "King's Knight: Normal Variation", eco: 'C44'),
      const OpeningMove(moveUci: 'g8f6', openingName: 'Petrov Defense', eco: 'C42'),
      const OpeningMove(moveUci: 'd7d6', openingName: 'Philidor Defense', eco: 'C41'),
    ],

    // 1. e4 e5 2. Nf3 Nc6
    'r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq': [
      const OpeningMove(moveUci: 'f1b5', openingName: 'Ruy Lopez (Spanish Opening)', eco: 'C60'),
      const OpeningMove(moveUci: 'f1c4', openingName: 'Italian Game', eco: 'C50'),
      const OpeningMove(moveUci: 'd2d4', openingName: 'Scotch Game', eco: 'C45'),
      const OpeningMove(moveUci: 'b1c3', openingName: 'Four Knights Game', eco: 'C46'),
    ],

    // 1. e4 c5 (Sicilian)
    'rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq': [
      const OpeningMove(moveUci: 'g1f3', openingName: 'Sicilian Defense: Open Variation', eco: 'B27'),
      const OpeningMove(moveUci: 'b1c3', openingName: 'Sicilian Defense: Closed', eco: 'B23'),
      const OpeningMove(moveUci: 'c2c3', openingName: 'Sicilian Defense: Alapin Variation', eco: 'B22'),
    ],

    // 1. e4 c5 2. Nf3
    'rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq': [
      const OpeningMove(moveUci: 'd7d6', openingName: 'Sicilian Defense: Modern Line', eco: 'B50'),
      const OpeningMove(moveUci: 'b8c6', openingName: 'Sicilian Defense: Old Sicilian', eco: 'B30'),
      const OpeningMove(moveUci: 'e7e6', openingName: 'Sicilian Defense: French Variation', eco: 'B40'),
    ],

    // 1. d4 d5
    'rnbqkbnr/ppp1pppp/8/3p4/3P4/8/PPP1PPPP/RNBQKBNR w KQkq': [
      const OpeningMove(moveUci: 'c2c4', openingName: "Queen's Gambit", eco: 'D06'),
      const OpeningMove(moveUci: 'g1f3', openingName: "Queen's Pawn: London / Torre System", eco: 'D02'),
      const OpeningMove(moveUci: 'c1f4', openingName: 'London System', eco: 'D00'),
    ],

    // 1. d4 d5 2. c4
    'rnbqkbnr/ppp1pppp/8/3p4/2PP4/8/PP2PPPP/RNBQKBNR b KQkq': [
      const OpeningMove(moveUci: 'e7e6', openingName: "Queen's Gambit Declined (QGD)", eco: 'D30'),
      const OpeningMove(moveUci: 'c7c6', openingName: 'Slav Defense', eco: 'D10'),
      const OpeningMove(moveUci: 'd5c4', openingName: "Queen's Gambit Accepted (QGA)", eco: 'D20'),
    ],

    // 1. d4 Nf6
    'rnbqkb1r/pppppppp/5n2/8/3P4/8/PPP1PPPP/RNBQKBNR w KQkq': [
      const OpeningMove(moveUci: 'c2c4', openingName: 'Indian Defense: Main Line', eco: 'A50'),
      const OpeningMove(moveUci: 'g1f3', openingName: 'Indian Defense: Knights Variation', eco: 'A46'),
      const OpeningMove(moveUci: 'c1g5', openingName: 'Trompowsky Attack', eco: 'A45'),
    ],

    // 1. d4 Nf6 2. c4 g6
    'rnbqkb1r/pppppp1p/5np1/8/2PP4/8/PP2PPPP/RNBQKBNR w KQkq': [
      const OpeningMove(moveUci: 'b1c3', openingName: "King's Indian / Grünfeld Defense", eco: 'E60'),
      const OpeningMove(moveUci: 'g1f3', openingName: "King's Indian Defense", eco: 'E60'),
    ],
  };

  /// Query opening book for a given FEN string
  OpeningMove? findBookMove(String fen) {
    final parts = fen.trim().split(RegExp(r'\s+'));
    if (parts.length < 3) return null;

    final key = '${parts[0]} ${parts[1]} ${parts[2]}';
    final moves = _openingTree[key];
    if (moves == null || moves.isEmpty) return null;

    final rand = math.Random();
    return moves[rand.nextInt(moves.length)];
  }

  /// Check if position is within opening book
  bool isInBook(String fen) {
    final parts = fen.trim().split(RegExp(r'\s+'));
    if (parts.length < 3) return false;
    final key = '${parts[0]} ${parts[1]} ${parts[2]}';
    return _openingTree.containsKey(key);
  }

  /// Get Opening name from FEN if known
  String? getOpeningName(String fen) {
    final parts = fen.trim().split(RegExp(r'\s+'));
    if (parts.length < 3) return null;
    final key = '${parts[0]} ${parts[1]} ${parts[2]}';
    final moves = _openingTree[key];
    if (moves != null && moves.isNotEmpty) {
      return moves.first.openingName;
    }
    return null;
  }
}
