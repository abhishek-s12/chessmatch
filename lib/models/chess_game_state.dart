import 'package:flutter/foundation.dart';
import 'chess_piece.dart';

class ChessGameState extends ChangeNotifier {
  static const String startingFen =
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  late List<List<ChessPiece?>> _board;
  PieceColor _turn = PieceColor.white;
  bool _whiteCanCastleKingside = true;
  bool _whiteCanCastleQueenside = true;
  bool _blackCanCastleKingside = true;
  bool _blackCanCastleQueenside = true;
  BoardPosition? _enPassantTarget;
  int _halfmoveClock = 0;
  int _fullmoveNumber = 1;

  final List<String> _fenHistory = [];
  final List<ChessMove> _moveHistory = [];
  final List<String> _sanHistory = [];

  BoardPosition? _selectedSquare;
  List<ChessMove> _legalMovesForSelected = [];
  ChessMove? _lastMove;
  bool _isFlipped = false;

  ChessGameState() {
    loadFen(startingFen);
  }

  // Getters
  List<List<ChessPiece?>> get board => _board;
  PieceColor get turn => _turn;
  BoardPosition? get selectedSquare => _selectedSquare;
  List<ChessMove> get legalMovesForSelected => _legalMovesForSelected;
  ChessMove? get lastMove => _lastMove;
  bool get isFlipped => _isFlipped;
  List<ChessMove> get moveHistory => List.unmodifiable(_moveHistory);
  List<String> get sanHistory => List.unmodifiable(_sanHistory);
  List<String> get fenHistory => List.unmodifiable(_fenHistory);

  void toggleBoardFlip() {
    _isFlipped = !_isFlipped;
    notifyListeners();
  }

  ChessPiece? pieceAt(int row, int col) {
    if (row < 0 || row > 7 || col < 0 || col > 7) return null;
    return _board[row][col];
  }

  ChessPiece? pieceAtPos(BoardPosition pos) {
    return pieceAt(pos.row, pos.col);
  }

  void resetGame() {
    loadFen(startingFen);
  }

  void loadFen(String fen) {
    _board = List.generate(8, (_) => List<ChessPiece?>.filled(8, null));
    final parts = fen.trim().split(RegExp(r'\s+'));

    // 1. Piece placement
    final ranks = parts[0].split('/');
    for (int r = 0; r < 8 && r < ranks.length; r++) {
      int col = 0;
      for (int i = 0; i < ranks[r].length && col < 8; i++) {
        final char = ranks[r][i];
        if (RegExp(r'[1-8]').hasMatch(char)) {
          col += int.parse(char);
        } else {
          _board[r][col] = ChessPiece.fromFenChar(char);
          col++;
        }
      }
    }

    // 2. Active turn
    if (parts.length > 1) {
      _turn = parts[1] == 'b' ? PieceColor.black : PieceColor.white;
    } else {
      _turn = PieceColor.white;
    }

    // 3. Castling rights
    if (parts.length > 2) {
      final castling = parts[2];
      _whiteCanCastleKingside = castling.contains('K');
      _whiteCanCastleQueenside = castling.contains('Q');
      _blackCanCastleKingside = castling.contains('k');
      _blackCanCastleQueenside = castling.contains('q');
    } else {
      _whiteCanCastleKingside = true;
      _whiteCanCastleQueenside = true;
      _blackCanCastleKingside = true;
      _blackCanCastleQueenside = true;
    }

    // 4. En passant target
    if (parts.length > 3 && parts[3] != '-') {
      _enPassantTarget = BoardPosition.fromAlgebraic(parts[3]);
    } else {
      _enPassantTarget = null;
    }

    // 5. Halfmove clock & fullmove
    _halfmoveClock = parts.length > 4 ? int.tryParse(parts[4]) ?? 0 : 0;
    _fullmoveNumber = parts.length > 5 ? int.tryParse(parts[5]) ?? 1 : 1;

    _selectedSquare = null;
    _legalMovesForSelected = [];
    _lastMove = null;
    _moveHistory.clear();
    _sanHistory.clear();
    _fenHistory.clear();
    _fenHistory.add(generateFen());

    notifyListeners();
  }

  String generateFen() {
    final buffer = StringBuffer();
    // 1. Piece positions
    for (int r = 0; r < 8; r++) {
      int emptyCount = 0;
      for (int c = 0; c < 8; c++) {
        final piece = _board[r][c];
        if (piece == null) {
          emptyCount++;
        } else {
          if (emptyCount > 0) {
            buffer.write(emptyCount);
            emptyCount = 0;
          }
          buffer.write(piece.fenChar);
        }
      }
      if (emptyCount > 0) {
        buffer.write(emptyCount);
      }
      if (r < 7) buffer.write('/');
    }

    // 2. Turn
    buffer.write(' ${_turn == PieceColor.white ? 'w' : 'b'} ');

    // 3. Castling
    final castling = StringBuffer();
    if (_whiteCanCastleKingside) castling.write('K');
    if (_whiteCanCastleQueenside) castling.write('Q');
    if (_blackCanCastleKingside) castling.write('k');
    if (_blackCanCastleQueenside) castling.write('q');
    buffer.write(castling.isEmpty ? '-' : castling.toString());

    // 4. En passant
    buffer.write(' ${_enPassantTarget != null ? _enPassantTarget!.algebraic : '-'} ');

    // 5. Clocks
    buffer.write('$_halfmoveClock $_fullmoveNumber');
    return buffer.toString();
  }

  void selectSquare(BoardPosition pos) {
    final piece = pieceAtPos(pos);
    if (_selectedSquare != null) {
      // Check if clicking a destination square for the selected piece
      final matchingMove = _legalMovesForSelected.firstWhere(
        (m) => m.to == pos,
        orElse: () => const ChessMove(
          from: BoardPosition(-1, -1),
          to: BoardPosition(-1, -1),
        ),
      );

      if (matchingMove.from.row != -1) {
        makeMove(matchingMove);
        _selectedSquare = null;
        _legalMovesForSelected = [];
        notifyListeners();
        return;
      }
    }

    // Select piece if it's the current player's piece
    if (piece != null && piece.color == _turn) {
      _selectedSquare = pos;
      _legalMovesForSelected = generateLegalMovesForPiece(pos);
    } else {
      _selectedSquare = null;
      _legalMovesForSelected = [];
    }
    notifyListeners();
  }

  bool makeMove(ChessMove move) {
    final piece = pieceAtPos(move.from);
    if (piece == null || piece.color != _turn) return false;

    final san = _formatSan(move, piece);

    // Apply move to board
    _board[move.to.row][move.to.col] = move.promotion != null
        ? ChessPiece(type: move.promotion!, color: piece.color)
        : piece;
    _board[move.from.row][move.from.col] = null;

    // Handle En Passant capture
    if (piece.type == PieceType.pawn && move.to == _enPassantTarget) {
      final capRow = piece.color == PieceColor.white ? move.to.row + 1 : move.to.row - 1;
      _board[capRow][move.to.col] = null;
    }

    // Handle Castling rook movement
    if (piece.type == PieceType.king && (move.to.col - move.from.col).abs() == 2) {
      if (move.to.col == 6) {
        // Kingside
        final rook = _board[move.from.row][7];
        _board[move.from.row][5] = rook;
        _board[move.from.row][7] = null;
      } else if (move.to.col == 2) {
        // Queenside
        final rook = _board[move.from.row][0];
        _board[move.from.row][3] = rook;
        _board[move.from.row][0] = null;
      }
    }

    // Update Castling Rights
    if (piece.type == PieceType.king) {
      if (piece.color == PieceColor.white) {
        _whiteCanCastleKingside = false;
        _whiteCanCastleQueenside = false;
      } else {
        _blackCanCastleKingside = false;
        _blackCanCastleQueenside = false;
      }
    } else if (piece.type == PieceType.rook) {
      if (move.from.row == 7 && move.from.col == 7) _whiteCanCastleKingside = false;
      if (move.from.row == 7 && move.from.col == 0) _whiteCanCastleQueenside = false;
      if (move.from.row == 0 && move.from.col == 7) _blackCanCastleKingside = false;
      if (move.from.row == 0 && move.from.col == 0) _blackCanCastleQueenside = false;
    }

    // Set new En Passant target
    if (piece.type == PieceType.pawn && (move.to.row - move.from.row).abs() == 2) {
      final epRow = piece.color == PieceColor.white ? move.from.row - 1 : move.from.row + 1;
      _enPassantTarget = BoardPosition(epRow, move.from.col);
    } else {
      _enPassantTarget = null;
    }

    if (_turn == PieceColor.black) {
      _fullmoveNumber++;
    }
    _turn = _turn == PieceColor.white ? PieceColor.black : PieceColor.white;

    _lastMove = move;
    _moveHistory.add(move);
    _sanHistory.add(san);
    _fenHistory.add(generateFen());

    notifyListeners();
    return true;
  }

  bool isKingInCheck(PieceColor color) {
    BoardPosition? kingPos;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final p = _board[r][c];
        if (p != null && p.type == PieceType.king && p.color == color) {
          kingPos = BoardPosition(r, c);
          break;
        }
      }
    }
    if (kingPos == null) return false;
    return isSquareAttacked(kingPos, color == PieceColor.white ? PieceColor.black : PieceColor.white);
  }

  bool isSquareAttacked(BoardPosition pos, PieceColor byColor) {
    // Check knight attacks
    const knightOffsets = [
      [-2, -1], [-2, 1], [-1, -2], [-1, 2],
      [1, -2], [1, 2], [2, -1], [2, 1]
    ];
    for (final off in knightOffsets) {
      final nr = pos.row + off[0];
      final nc = pos.col + off[1];
      final p = pieceAt(nr, nc);
      if (p != null && p.color == byColor && p.type == PieceType.knight) return true;
    }

    // Check pawn attacks
    final pawnDir = byColor == PieceColor.white ? 1 : -1;
    for (final dc in [-1, 1]) {
      final pr = pos.row + pawnDir;
      final pc = pos.col + dc;
      final p = pieceAt(pr, pc);
      if (p != null && p.color == byColor && p.type == PieceType.pawn) return true;
    }

    // Check straight attacks (Rook, Queen)
    const straightDirs = [[-1, 0], [1, 0], [0, -1], [0, 1]];
    for (final dir in straightDirs) {
      int r = pos.row + dir[0];
      int c = pos.col + dir[1];
      while (r >= 0 && r < 8 && c >= 0 && c < 8) {
        final p = _board[r][c];
        if (p != null) {
          if (p.color == byColor && (p.type == PieceType.rook || p.type == PieceType.queen)) {
            return true;
          }
          break;
        }
        r += dir[0];
        c += dir[1];
      }
    }

    // Check diagonal attacks (Bishop, Queen)
    const diagDirs = [[-1, -1], [-1, 1], [1, -1], [1, 1]];
    for (final dir in diagDirs) {
      int r = pos.row + dir[0];
      int c = pos.col + dir[1];
      while (r >= 0 && r < 8 && c >= 0 && c < 8) {
        final p = _board[r][c];
        if (p != null) {
          if (p.color == byColor && (p.type == PieceType.bishop || p.type == PieceType.queen)) {
            return true;
          }
          break;
        }
        r += dir[0];
        c += dir[1];
      }
    }

    // Check king attacks
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final kr = pos.row + dr;
        final kc = pos.col + dc;
        final p = pieceAt(kr, kc);
        if (p != null && p.color == byColor && p.type == PieceType.king) return true;
      }
    }

    return false;
  }

  List<ChessMove> generateLegalMovesForPiece(BoardPosition from) {
    final piece = pieceAtPos(from);
    if (piece == null || piece.color != _turn) return [];

    final pseudoMoves = <ChessMove>[];
    final color = piece.color;
    final enemyColor = color == PieceColor.white ? PieceColor.black : PieceColor.white;

    switch (piece.type) {
      case PieceType.pawn:
        final forward = color == PieceColor.white ? -1 : 1;
        final startRank = color == PieceColor.white ? 6 : 1;
        final promoRank = color == PieceColor.white ? 0 : 7;

        // 1 step forward
        final oneStepRow = from.row + forward;
        if (oneStepRow >= 0 && oneStepRow < 8 && pieceAt(oneStepRow, from.col) == null) {
          if (oneStepRow == promoRank) {
            for (final pr in [PieceType.queen, PieceType.rook, PieceType.bishop, PieceType.knight]) {
              pseudoMoves.add(ChessMove(from: from, to: BoardPosition(oneStepRow, from.col), promotion: pr));
            }
          } else {
            pseudoMoves.add(ChessMove(from: from, to: BoardPosition(oneStepRow, from.col)));
          }

          // 2 steps forward
          final twoStepsRow = from.row + 2 * forward;
          if (from.row == startRank && pieceAt(twoStepsRow, from.col) == null) {
            pseudoMoves.add(ChessMove(from: from, to: BoardPosition(twoStepsRow, from.col)));
          }
        }

        // Captures
        for (final dc in [-1, 1]) {
          final targetCol = from.col + dc;
          final targetRow = from.row + forward;
          if (targetRow >= 0 && targetRow < 8 && targetCol >= 0 && targetCol < 8) {
            final destPiece = pieceAt(targetRow, targetCol);
            final isEnPassant = _enPassantTarget != null &&
                _enPassantTarget!.row == targetRow &&
                _enPassantTarget!.col == targetCol;

            if ((destPiece != null && destPiece.color == enemyColor) || isEnPassant) {
              if (targetRow == promoRank) {
                for (final pr in [PieceType.queen, PieceType.rook, PieceType.bishop, PieceType.knight]) {
                  pseudoMoves.add(ChessMove(
                    from: from,
                    to: BoardPosition(targetRow, targetCol),
                    promotion: pr,
                    isEnPassant: isEnPassant,
                  ));
                }
              } else {
                pseudoMoves.add(ChessMove(
                  from: from,
                  to: BoardPosition(targetRow, targetCol),
                  isEnPassant: isEnPassant,
                ));
              }
            }
          }
        }
        break;

      case PieceType.knight:
        const offsets = [
          [-2, -1], [-2, 1], [-1, -2], [-1, 2],
          [1, -2], [1, 2], [2, -1], [2, 1]
        ];
        for (final off in offsets) {
          final r = from.row + off[0];
          final c = from.col + off[1];
          if (r >= 0 && r < 8 && c >= 0 && c < 8) {
            final p = pieceAt(r, c);
            if (p == null || p.color == enemyColor) {
              pseudoMoves.add(ChessMove(from: from, to: BoardPosition(r, c)));
            }
          }
        }
        break;

      case PieceType.bishop:
      case PieceType.rook:
      case PieceType.queen:
        final dirs = <List<int>>[];
        if (piece.type == PieceType.bishop || piece.type == PieceType.queen) {
          dirs.addAll([[-1, -1], [-1, 1], [1, -1], [1, 1]]);
        }
        if (piece.type == PieceType.rook || piece.type == PieceType.queen) {
          dirs.addAll([[-1, 0], [1, 0], [0, -1], [0, 1]]);
        }
        for (final dir in dirs) {
          int r = from.row + dir[0];
          int c = from.col + dir[1];
          while (r >= 0 && r < 8 && c >= 0 && c < 8) {
            final p = pieceAt(r, c);
            if (p == null) {
              pseudoMoves.add(ChessMove(from: from, to: BoardPosition(r, c)));
            } else {
              if (p.color == enemyColor) {
                pseudoMoves.add(ChessMove(from: from, to: BoardPosition(r, c)));
              }
              break;
            }
            r += dir[0];
            c += dir[1];
          }
        }
        break;

      case PieceType.king:
        for (int dr = -1; dr <= 1; dr++) {
          for (int dc = -1; dc <= 1; dc++) {
            if (dr == 0 && dc == 0) continue;
            final r = from.row + dr;
            final c = from.col + dc;
            if (r >= 0 && r < 8 && c >= 0 && c < 8) {
              final p = pieceAt(r, c);
              if (p == null || p.color == enemyColor) {
                pseudoMoves.add(ChessMove(from: from, to: BoardPosition(r, c)));
              }
            }
          }
        }

        // Castling
        if (!isKingInCheck(color)) {
          final row = color == PieceColor.white ? 7 : 0;
          final canK = color == PieceColor.white ? _whiteCanCastleKingside : _blackCanCastleKingside;
          final canQ = color == PieceColor.white ? _whiteCanCastleQueenside : _blackCanCastleQueenside;

          // Kingside (e1->g1 or e8->g8)
          if (canK && pieceAt(row, 5) == null && pieceAt(row, 6) == null) {
            if (!isSquareAttacked(BoardPosition(row, 5), enemyColor) &&
                !isSquareAttacked(BoardPosition(row, 6), enemyColor)) {
              pseudoMoves.add(ChessMove(from: from, to: BoardPosition(row, 6), isCastling: true));
            }
          }
          // Queenside (e1->c1 or e8->c8)
          if (canQ && pieceAt(row, 1) == null && pieceAt(row, 2) == null && pieceAt(row, 3) == null) {
            if (!isSquareAttacked(BoardPosition(row, 2), enemyColor) &&
                !isSquareAttacked(BoardPosition(row, 3), enemyColor)) {
              pseudoMoves.add(ChessMove(from: from, to: BoardPosition(row, 2), isCastling: true));
            }
          }
        }
        break;
    }

    // Filter moves that leave the King in check
    final legalMoves = <ChessMove>[];
    for (final move in pseudoMoves) {
      if (_isMoveLegal(move, color)) {
        legalMoves.add(move);
      }
    }
    return legalMoves;
  }

  bool _isMoveLegal(ChessMove move, PieceColor color) {
    final origSrc = _board[move.from.row][move.from.col];
    final origDst = _board[move.to.row][move.to.col];

    // Temporarily apply move
    _board[move.to.row][move.to.col] = origSrc;
    _board[move.from.row][move.from.col] = null;

    final inCheck = isKingInCheck(color);

    // Revert move
    _board[move.from.row][move.from.col] = origSrc;
    _board[move.to.row][move.to.col] = origDst;

    return !inCheck;
  }

  List<ChessMove> generateAllLegalMoves() {
    final allMoves = <ChessMove>[];
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final p = _board[r][c];
        if (p != null && p.color == _turn) {
          allMoves.addAll(generateLegalMovesForPiece(BoardPosition(r, c)));
        }
      }
    }
    return allMoves;
  }

  bool get isCheckmate => isKingInCheck(_turn) && generateAllLegalMoves().isEmpty;
  bool get isStalemate => !isKingInCheck(_turn) && generateAllLegalMoves().isEmpty;

  String _formatSan(ChessMove move, ChessPiece piece) {
    if (piece.type == PieceType.king && (move.to.col - move.from.col).abs() == 2) {
      return move.to.col == 6 ? 'O-O' : 'O-O-O';
    }
    final prefix = piece.type == PieceType.pawn
        ? (move.from.col != move.to.col ? move.from.algebraic[0] : '')
        : piece.fenChar.toUpperCase();
    final capture = pieceAtPos(move.to) != null || move.isEnPassant ? 'x' : '';
    final promo = move.promotion != null ? '=${move.promotion.toString().split('.').last[0].toUpperCase()}' : '';
    return '$prefix$capture${move.to.algebraic}$promo';
  }

  /// Reverts the most recent move
  bool undoMove() {
    if (_fenHistory.length <= 1) return false;
    _fenHistory.removeLast();
    final previousFen = _fenHistory.last;
    
    if (_moveHistory.isNotEmpty) _moveHistory.removeLast();
    if (_sanHistory.isNotEmpty) _sanHistory.removeLast();

    final prevMoves = List<ChessMove>.from(_moveHistory);
    final prevSans = List<String>.from(_sanHistory);
    final prevFens = List<String>.from(_fenHistory);

    loadFen(previousFen);

    _moveHistory.clear();
    _moveHistory.addAll(prevMoves);
    _sanHistory.clear();
    _sanHistory.addAll(prevSans);
    _fenHistory.clear();
    _fenHistory.addAll(prevFens);

    _lastMove = _moveHistory.isNotEmpty ? _moveHistory.last : null;
    notifyListeners();
    return true;
  }

  void clearSelection() {
    _selectedSquare = null;
    _legalMovesForSelected = [];
    notifyListeners();
  }

  /// Reverts two consecutive moves (e.g. player's move + engine's reply)
  bool undoTwoMoves() {
    if (_fenHistory.length > 2) {
      undoMove();
      undoMove();
      return true;
    } else if (_fenHistory.length == 2) {
      undoMove();
      return true;
    }
    return false;
  }

  /// Generates standard PGN text with move SAN history
  String generatePgn({
    String white = 'White Player',
    String black = 'Black Player',
    String event = 'Casual Match',
    String result = '*',
  }) {
    final now = DateTime.now();
    final dateStr = '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';
    final buffer = StringBuffer();

    buffer.writeln('[Event "$event"]');
    buffer.writeln('[Site "BlurChess App"]');
    buffer.writeln('[Date "$dateStr"]');
    buffer.writeln('[White "$white"]');
    buffer.writeln('[Black "$black"]');
    buffer.writeln('[Result "$result"]');
    buffer.writeln();

    for (int i = 0; i < _sanHistory.length; i++) {
      if (i % 2 == 0) {
        final moveNum = (i ~/ 2) + 1;
        buffer.write('$moveNum. ');
      }
      buffer.write('${_sanHistory[i]} ');
    }
    buffer.write(result);
    return buffer.toString();
  }
}
