import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/chess_game_state.dart';
import '../models/chess_piece.dart';
import '../models/engine_evaluation.dart';
import '../services/stockfish_engine_service.dart';
import '../services/overlay_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chess_board_widget.dart';
import '../widgets/engine_analysis_panel.dart';
import '../widgets/evaluation_bar_widget.dart';
import '../widgets/move_history_widget.dart';
import 'game_review_screen.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final StockfishEngineService _engineService = StockfishEngineService();
  EngineEvaluation _currentEval = EngineEvaluation.initial();
  bool _isEngineActive = true;
  Timer? _evalDebounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runEngineEvaluation();
    });
  }

  @override
  void dispose() {
    _evalDebounceTimer?.cancel();
    _engineService.stop();
    super.dispose();
  }

  void _runEngineEvaluation() {
    if (!_isEngineActive) return;

    _evalDebounceTimer?.cancel();
    _evalDebounceTimer = Timer(const Duration(milliseconds: 150), () async {
      final game = Provider.of<ChessGameState>(context, listen: false);
      final eval = await _engineService.evaluatePosition(game, depth: 4);

      if (mounted) {
        setState(() {
          _currentEval = eval;
        });

        // Broadcast to floating overlay service if running
        OverlayService.updateOverlay(
          eval: eval.displayScore,
          bestMove: eval.bestMove,
          isWhite: game.turn == PieceColor.white,
          depth: eval.depth,
        );
      }
    });
  }

  void _showFenDialog() {
    final game = Provider.of<ChessGameState>(context, listen: false);
    final textController = TextEditingController(text: game.generateFen());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Load / Export FEN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              maxLines: 3,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Paste FEN position string here...',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: textController.text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('FEN copied to clipboard!')),
              );
            },
            child: const Text('Copy FEN', style: TextStyle(color: AppTheme.primaryNeon)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryNeon,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final fen = textController.text.trim();
              if (fen.isNotEmpty) {
                game.loadFen(fen);
                _runEngineEvaluation();
              }
              Navigator.pop(ctx);
            },
            child: const Text('Load Position'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<ChessGameState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CHESS ENGINE ANALYZER',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 15),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            tooltip: 'Game Review',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GameReviewScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.swap_vert),
            tooltip: 'Flip Board',
            onPressed: () => game.toggleBoardFlip(),
          ),
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: 'FEN Import/Export',
            onPressed: _showFenDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Top Engine Analysis Panel
              EngineAnalysisPanel(
                evaluation: _currentEval,
                isEngineActive: _isEngineActive,
                onToggleEngine: () {
                  setState(() {
                    _isEngineActive = !_isEngineActive;
                    if (_isEngineActive) {
                      _runEngineEvaluation();
                    } else {
                      _engineService.stop();
                    }
                  });
                },
              ),
              const SizedBox(height: 12),

              // Chessboard with Side Evaluation Bar
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vertical Eval Bar
                  EvaluationBarWidget(
                    evaluation: _currentEval,
                    isFlipped: game.isFlipped,
                  ),
                  const SizedBox(width: 8),

                  // Main 8x8 Board
                  Expanded(
                    child: ChessBoardWidget(
                      bestMoveUci: _isEngineActive ? _currentEval.bestMove : null,
                      onMoveMade: (_) {
                        _runEngineEvaluation();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Move History Bar
              MoveHistoryWidget(sanHistory: game.sanHistory),
              const SizedBox(height: 12),

              // Board Control Toolbar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildToolButton(
                    icon: Icons.refresh,
                    label: 'New Game',
                    onTap: () {
                      game.resetGame();
                      _runEngineEvaluation();
                    },
                  ),
                  _buildToolButton(
                    icon: Icons.undo,
                    label: 'Undo',
                    onTap: () {
                      game.undoMove();
                      _runEngineEvaluation();
                    },
                  ),
                  _buildToolButton(
                    icon: Icons.lightbulb,
                    label: 'Best Move',
                    onTap: () {
                      if (_currentEval.bestMove != '--') {
                        final move = ChessMove.fromUci(_currentEval.bestMove);
                        if (move != null) {
                          game.makeMove(move);
                          _runEngineEvaluation();
                        }
                      }
                    },
                  ),
                  _buildToolButton(
                    icon: Icons.insights,
                    label: 'Review',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GameReviewScreen()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryNeon),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
