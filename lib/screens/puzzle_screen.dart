import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chess_game_state.dart';
import '../models/chess_piece.dart';
import '../models/puzzle_model.dart';
import '../services/puzzle_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chess_board_widget.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  final PuzzleService _puzzleService = PuzzleService();
  int _currentPuzzleIndex = 0;
  int _solutionStep = 0;

  bool _isSolved = false;
  bool _isFailed = false;
  String? _hintMoveUci;
  String _statusText = 'Find the best move!';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPuzzle(_currentPuzzleIndex);
    });
  }

  void _loadPuzzle(int index) {
    final puzzle = _puzzleService.getPuzzleByIndex(index);
    final game = Provider.of<ChessGameState>(context, listen: false);

    game.loadFen(puzzle.fen);

    // Auto flip if Black to move
    if (game.turn == PieceColor.black && !game.isFlipped) {
      game.toggleBoardFlip();
    } else if (game.turn == PieceColor.white && game.isFlipped) {
      game.toggleBoardFlip();
    }

    setState(() {
      _currentPuzzleIndex = index;
      _solutionStep = 0;
      _isSolved = false;
      _isFailed = false;
      _hintMoveUci = null;
      _statusText = '${game.turn == PieceColor.white ? "White" : "Black"} to move • ${puzzle.theme}';
    });
  }

  void _onMoveMade(ChessMove move) async {
    final puzzle = _puzzleService.getPuzzleByIndex(_currentPuzzleIndex);
    final expectedUci = puzzle.solutionMoves[_solutionStep];

    if (move.uci == expectedUci) {
      _solutionStep++;
      _hintMoveUci = null;

      // Check if puzzle completed
      if (_solutionStep >= puzzle.solutionMoves.length) {
        SoundService.playGameOver();
        _puzzleService.onPuzzleSuccess(puzzle);
        setState(() {
          _isSolved = true;
          _statusText = '🎉 Puzzle Solved! +15 Rating';
        });
      } else {
        // Engine auto-replies with next expected opponent move
        setState(() {
          _statusText = 'Great! Keep going...';
        });

        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;

        final opponentUci = puzzle.solutionMoves[_solutionStep];
        final opponentMove = ChessMove.fromUci(opponentUci);
        if (opponentMove != null) {
          final game = Provider.of<ChessGameState>(context, listen: false);
          game.makeMove(opponentMove);
          SoundService.playMove();
          _solutionStep++;
          setState(() {
            _statusText = 'Your turn! Find the continuation.';
          });
        }
      }
    } else {
      // Incorrect move
      SoundService.playCheck();
      _puzzleService.onPuzzleFailure(puzzle);
      setState(() {
        _isFailed = true;
        _statusText = '❌ Incorrect move. Try another idea!';
      });

      // Auto revert incorrect move
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      final game = Provider.of<ChessGameState>(context, listen: false);
      game.undoMove();
      setState(() {
        _isFailed = false;
      });
    }
  }

  void _showHint() {
    final puzzle = _puzzleService.getPuzzleByIndex(_currentPuzzleIndex);
    if (_solutionStep < puzzle.solutionMoves.length) {
      final hintUci = puzzle.solutionMoves[_solutionStep];
      setState(() {
        _hintMoveUci = hintUci;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💡 Hint: Look around ${hintUci.substring(0, 2)}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _nextPuzzle() {
    _loadPuzzle(_currentPuzzleIndex + 1);
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = _puzzleService.getPuzzleByIndex(_currentPuzzleIndex);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TACTICAL PUZZLE TRAINER', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        actions: [
          IconButton(
            icon: const Icon(Icons.skip_next),
            tooltip: 'Next Puzzle',
            onPressed: _nextPuzzle,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Rating & Streak Header
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHeaderMetric(
                      icon: Icons.military_tech,
                      label: 'Tactics Rating',
                      value: '${_puzzleService.userRating}',
                      color: AppTheme.primaryNeon,
                    ),
                    Container(height: 35, width: 1, color: const Color(0xFF334155)),
                    _buildHeaderMetric(
                      icon: Icons.local_fire_department,
                      label: 'Streak',
                      value: '${_puzzleService.currentStreak} 🔥',
                      color: Colors.orange,
                    ),
                    Container(height: 35, width: 1, color: const Color(0xFF334155)),
                    _buildHeaderMetric(
                      icon: Icons.extension,
                      label: 'Puzzle ELO',
                      value: '${puzzle.rating}',
                      color: AppTheme.secondaryNeon,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Puzzle Info & Status Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _isSolved
                      ? AppTheme.secondaryNeon.withOpacity(0.2)
                      : (_isFailed ? AppTheme.alertRed.withOpacity(0.2) : AppTheme.surfaceDark),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSolved
                        ? AppTheme.secondaryNeon
                        : (_isFailed ? AppTheme.alertRed : const Color(0xFF334155)),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      puzzle.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isSolved
                            ? AppTheme.secondaryNeon
                            : (_isFailed ? const Color(0xFFFCA5A5) : AppTheme.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Puzzle Chessboard
              ChessBoardWidget(
                bestMoveUci: _hintMoveUci,
                interactive: !_isSolved,
                onMoveMade: _onMoveMade,
              ),
              const SizedBox(height: 14),

              // Description & Theme Tags
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        puzzle.description,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Toolbar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildButton(
                    icon: Icons.lightbulb,
                    label: 'Hint',
                    color: Colors.amber,
                    onTap: _isSolved ? () {} : _showHint,
                  ),
                  _buildButton(
                    icon: Icons.refresh,
                    label: 'Reset',
                    color: AppTheme.primaryNeon,
                    onTap: () => _loadPuzzle(_currentPuzzleIndex),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryNeon,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next Puzzle', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _nextPuzzle,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
