enum PieceType { pawn, knight, bishop, rook, queen, king }
enum PieceColor { white, black }

class ChessPiece {
  final PieceType type;
  final PieceColor color;

  const ChessPiece({required this.type, required this.color});

  String get symbol {
    switch (type) {
      case PieceType.king:
        return color == PieceColor.white ? '♔' : '♚';
      case PieceType.queen:
        return color == PieceColor.white ? '♕' : '♛';
      case PieceType.rook:
        return color == PieceColor.white ? '♖' : '♜';
      case PieceType.bishop:
        return color == PieceColor.white ? '♗' : '♝';
      case PieceType.knight:
        return color == PieceColor.white ? '♘' : '♞';
      case PieceType.pawn:
        return color == PieceColor.white ? '♙' : '♟';
    }
  }

  String get fenChar {
    final char = () {
      switch (type) {
        case PieceType.pawn: return 'p';
        case PieceType.knight: return 'n';
        case PieceType.bishop: return 'b';
        case PieceType.rook: return 'r';
        case PieceType.queen: return 'q';
        case PieceType.king: return 'k';
      }
    }();
    return color == PieceColor.white ? char.toUpperCase() : char.toLowerCase();
  }

  int get value {
    switch (type) {
      case PieceType.pawn: return 100;
      case PieceType.knight: return 320;
      case PieceType.bishop: return 330;
      case PieceType.rook: return 500;
      case PieceType.queen: return 900;
      case PieceType.king: return 20000;
    }
  }

  static ChessPiece? fromFenChar(String char) {
    final isWhite = char == char.toUpperCase();
    final lower = char.toLowerCase();
    final color = isWhite ? PieceColor.white : PieceColor.black;

    switch (lower) {
      case 'p': return ChessPiece(type: PieceType.pawn, color: color);
      case 'n': return ChessPiece(type: PieceType.knight, color: color);
      case 'b': return ChessPiece(type: PieceType.bishop, color: color);
      case 'r': return ChessPiece(type: PieceType.rook, color: color);
      case 'q': return ChessPiece(type: PieceType.queen, color: color);
      case 'k': return ChessPiece(type: PieceType.king, color: color);
      default: return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChessPiece &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          color == other.color;

  @override
  int get hashCode => type.hashCode ^ color.hashCode;
}

class BoardPosition {
  final int row; // 0 (rank 8) to 7 (rank 1)
  final int col; // 0 (file a) to 7 (file h)

  const BoardPosition(this.row, this.col);

  String get algebraic {
    final file = String.fromCharCode('a'.codeUnitAt(0) + col);
    final rank = (8 - row).toString();
    return '$file$rank';
  }

  static BoardPosition? fromAlgebraic(String alg) {
    if (alg.length < 2) return null;
    final fileChar = alg[0].toLowerCase();
    final rankChar = alg[1];

    final col = fileChar.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.tryParse(rankChar);
    if (rank == null || col < 0 || col > 7 || rank < 1 || rank > 8) return null;

    return BoardPosition(8 - rank, col);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardPosition &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => algebraic;
}

class ChessMove {
  final BoardPosition from;
  final BoardPosition to;
  final PieceType? promotion;
  final ChessPiece? capturedPiece;
  final bool isCastling;
  final bool isEnPassant;

  const ChessMove({
    required this.from,
    required this.to,
    this.promotion,
    this.capturedPiece,
    this.isCastling = false,
    this.isEnPassant = false,
  });

  bool get isCapture => capturedPiece != null || isEnPassant;

  String get uci {
    final promo = promotion != null ? () {
      switch (promotion!) {
        case PieceType.queen: return 'q';
        case PieceType.rook: return 'r';
        case PieceType.bishop: return 'b';
        case PieceType.knight: return 'n';
        default: return '';
      }
    }() : '';
    return '${from.algebraic}${to.algebraic}$promo';
  }

  static ChessMove? fromUci(String uci) {
    if (uci.length < 4) return null;
    final fromPos = BoardPosition.fromAlgebraic(uci.substring(0, 2));
    final toPos = BoardPosition.fromAlgebraic(uci.substring(2, 4));
    if (fromPos == null || toPos == null) return null;

    PieceType? promo;
    if (uci.length >= 5) {
      switch (uci[4].toLowerCase()) {
        case 'q': promo = PieceType.queen; break;
        case 'r': promo = PieceType.rook; break;
        case 'b': promo = PieceType.bishop; break;
        case 'n': promo = PieceType.knight; break;
      }
    }

    return ChessMove(from: fromPos, to: toPos, promotion: promo);
  }

  @override
  String toString() => uci;
}
