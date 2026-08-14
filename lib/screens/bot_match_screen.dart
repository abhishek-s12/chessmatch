import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chess_game_state.dart';
import '../models/chess_piece.dart';
import '../services/sound_service.dart';
import '../services/stockfish_engine_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chess_board_widget.dart';
import '../widgets/move_history_widget.dart';
import 'game_review_screen.dart';

enum TimeControlMode {
  untimed(name: 'Unlimited', seconds: 0, increment: 0),
  bullet(name: '1 min Bullet', seconds: 60, increment: 0),
  blitz(name: '3 | 2 Blitz', seconds: 180, increment: 2),
  rapid(name: '10 min Rapid', seconds: 600, increment: 0);

  final String name;
  final int seconds;
  final int increment;

  const TimeControlMode({
    required this.name,
    required this.seconds,
    required this.increment,
  });
}

class BotMatchScreen extends StatefulWidget {
  const BotMatchScreen({super.key});

  @override
  State<BotMatchScreen> createState() => _BotMatchScreenState();
}

class _BotMatchScreenState extends State<BotMatchScreen> {
  final StockfishEngineService _engineService = StockfishEngineService();

  BotDifficulty _selectedBot = BotDifficulty.intermediate;
  TimeControlMode _timeControl = TimeControlMode.rapid;
  PieceColor _playerColor = PieceColor.white;

  bool _gameStarted = false;
  bool _isBotThinking = false;
  String? _hintMoveUci;

  int _playerTimeSeconds = 600;
  int _botTimeSeconds = 600;
  Timer? _clockTimer;
  bool _isGameOver = false;
  String _gameOverReason = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _engineService.stop();
    super.dispose();
  }

  void _startNewGame() {
    final game = Provider.of<ChessGameState>(context, listen: false);
    game.resetGame();

    if (_playerColor == PieceColor.black && !game.isFlipped) {
      game.toggleBoardFlip();
    } else if (_playerColor == PieceColor.white && game.isFlipped) {
      game.toggleBoardFlip();
    }

    setState(() {
      _gameStarted = true;
      _isGameOver = false;
      _gameOverReason = '';
      _hintMoveUci = null;
      _playerTimeSeconds = _timeControl.seconds;
      _botTimeSeconds = _timeControl.seconds;
    });

    _startClockTimer();

    // If player is Black, bot makes the first move
    if (_playerColor == PieceColor.black) {
      _triggerBotMove();
    }
  }

  void _startClockTimer() {
    _clockTimer?.cancel();
    if (_timeControl == TimeControlMode.untimed) return;

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isGameOver) {
        timer.cancel();
        return;
      }

      final game = Provider.of<ChessGameState>(context, listen: false);
      final isPlayerTurn = game.turn == _playerColor;

      setState(() {
        if (isPlayerTurn) {
          if (_playerTimeSeconds > 0) {
            _playerTimeSeconds--;
          } else {
            _handleGameOver('Time Out! Bot won on time.');
          }
        } else {
          if (_botTimeSeconds > 0) {
            _botTimeSeconds--;
          } else {
            _handleGameOver('Time Out! You won on time.');
          }
        }
      });
    });
  }

  Future<void> _triggerBotMove() async {
    final game = Provider.of<ChessGameState>(context, listen: false);
    if (game.isCheckmate || game.isStalemate || _isGameOver) return;

    setState(() {
      _isBotThinking = true;
      _hintMoveUci = null;
    });

    // Realistic bot human delay (600ms - 1500ms)
    final delay = 600 + math.Random().nextInt(600);
    await Future.delayed(Duration(milliseconds: delay));

    if (!mounted || _isGameOver) return;

    final botMove = await _engineService.getBotMove(game, _selectedBot);
    final isCap = game.pieceAtPos(botMove.to) != null || botMove.isEnPassant;
    game.makeMove(botMove);

    if (isCap) {
      SoundService.playCapture();
    } else {
      SoundService.playMove();
    }
    if (game.isKingInCheck(game.turn)) {
      SoundService.playCheck();
    }

    if (_timeControl.increment > 0) {
      _botTimeSeconds += _timeControl.increment;
    }

    if (mounted) {
      setState(() {
        _isBotThinking = false;
      });
      _checkGameEndCondition();
    }
  }

  void _onPlayerMoveMade(ChessMove move) {
    setState(() {
      _hintMoveUci = null;
    });

    if (_timeControl.increment > 0) {
      _playerTimeSeconds += _timeControl.increment;
    }

    if (!_checkGameEndCondition()) {
      _triggerBotMove();
    }
  }

  bool _checkGameEndCondition() {
    final game = Provider.of<ChessGameState>(context, listen: false);
    if (game.isCheckmate) {
      final winner = game.turn == _playerColor ? 'Bot' : 'You';
      _handleGameOver('Checkmate! $winner won the match.');
      return true;
    } else if (game.isStalemate) {
      _handleGameOver('Draw by Stalemate!');
      return true;
    }
    return false;
  }

  void _handleGameOver(String reason) {
    _clockTimer?.cancel();
    SoundService.playGameOver();
    setState(() {
      _isGameOver = true;
      _gameOverReason = reason;
      _isBotThinking = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: AppTheme.primaryNeon, size: 28),
            const SizedBox(width: 10),
            const Text('Game Finished', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _gameOverReason,
              style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              'Opponent: ${_selectedBot.name}',
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startNewGame();
            },
            child: const Text('Play Again', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNeon,
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('Review Game'),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GameReviewScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  void _requestHint() async {
    final game = Provider.of<ChessGameState>(context, listen: false);
    if (game.turn != _playerColor || _isGameOver) return;

    final eval = await _engineService.evaluatePosition(game, depth: 5);
    if (eval.bestMove != '--') {
      setState(() {
        _hintMoveUci = eval.bestMove;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💡 Engine Hint: Recommended move ${eval.bestMove}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _undoMove() {
    final game = Provider.of<ChessGameState>(context, listen: false);
    if (_isBotThinking || _isGameOver) return;

    game.undoTwoMoves();
    setState(() {
      _hintMoveUci = null;
    });
  }

  void _resignGame() {
    _handleGameOver('You resigned. Bot won the match.');
  }

  String _formatTime(int totalSeconds) {
    final min = totalSeconds ~/ 60;
    final sec = totalSeconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<ChessGameState>();
    final isPlayerTurn = game.turn == _playerColor;

    if (!_gameStarted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('PLAY VS ENGINE BOTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Bot Difficulty Selection
              const Text('Select Bot Difficulty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ...BotDifficulty.values.map((bot) {
                final isSel = _selectedBot == bot;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    tileColor: isSel ? AppTheme.surfaceDark : AppTheme.cardDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isSel ? AppTheme.primaryNeon : const Color(0xFF334155),
                        width: isSel ? 2 : 1,
                      ),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isSel ? AppTheme.primaryNeon : const Color(0xFF334155),
                      child: Icon(Icons.smart_toy, color: isSel ? Colors.black : Colors.white),
                    ),
                    title: Text(bot.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Minimax Depth ${bot.depth} • Blunder ${(bot.blunderRate * 100).toInt()}%'),
                    trailing: isSel ? const Icon(Icons.check_circle, color: AppTheme.primaryNeon) : null,
                    onTap: () => setState(() => _selectedBot = bot),
                  ),
                );
              }),

              const SizedBox(height: 16),
              // Play As Side
              const Text('Play As Side', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildSideSelector(
                      title: 'White',
                      icon: Icons.circle,
                      iconColor: Colors.white,
                      isSelected: _playerColor == PieceColor.white,
                      onTap: () => setState(() => _playerColor = PieceColor.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSideSelector(
                      title: 'Black',
                      icon: Icons.circle,
                      iconColor: Colors.black,
                      isSelected: _playerColor == PieceColor.black,
                      onTap: () => setState(() => _playerColor = PieceColor.black),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              // Time Controls
              const Text('Time Control', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: TimeControlMode.values.map((tc) {
                  final isSel = _timeControl == tc;
                  return ChoiceChip(
                    label: Text(tc.name),
                    selected: isSel,
                    selectedColor: AppTheme.secondaryNeon.withOpacity(0.3),
                    backgroundColor: AppTheme.cardDark,
                    labelStyle: TextStyle(
                      color: isSel ? AppTheme.secondaryNeon : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    side: BorderSide(
                      color: isSel ? AppTheme.secondaryNeon : const Color(0xFF334155),
                    ),
                    onSelected: (_) => setState(() => _timeControl = tc),
                  );
                }).toList(),
              ),

              const SizedBox(height: 28),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNeon,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.play_arrow, size: 26),
                label: const Text(
                  'START BOT MATCH',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                onPressed: _startNewGame,
              ),
            ],
          ),
        ),
      );
    }

    // Active Bot Match Screen
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'VS ${_selectedBot.name.toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'New Match Setup',
            onPressed: () {
              setState(() {
                _gameStarted = false;
                _clockTimer?.cancel();
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Top Player Card (Bot)
              _buildPlayerCard(
                name: _selectedBot.name,
                isBot: true,
                isActive: !isPlayerTurn && !_isGameOver,
                timeText: _timeControl == TimeControlMode.untimed ? '∞' : _formatTime(_botTimeSeconds),
                isThinking: _isBotThinking,
              ),
              const SizedBox(height: 8),

              // Interactive Chess Board
              ChessBoardWidget(
                bestMoveUci: _hintMoveUci,
                interactive: isPlayerTurn && !_isBotThinking && !_isGameOver,
                onMoveMade: _onPlayerMoveMade,
              ),
              const SizedBox(height: 8),

              // Bottom Player Card (User)
              _buildPlayerCard(
                name: 'You (${_playerColor == PieceColor.white ? "White" : "Black"})',
                isBot: false,
                isActive: isPlayerTurn && !_isGameOver,
                timeText: _timeControl == TimeControlMode.untimed ? '∞' : _formatTime(_playerTimeSeconds),
                isThinking: false,
              ),
              const SizedBox(height: 10),

              // Move History
              MoveHistoryWidget(sanHistory: game.sanHistory),
              const SizedBox(height: 12),

              // Controls Action Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.undo,
                    label: 'Takeback',
                    onTap: _undoMove,
                  ),
                  _buildActionButton(
                    icon: Icons.lightbulb,
                    label: 'Hint',
                    onTap: _requestHint,
                  ),
                  _buildActionButton(
                    icon: Icons.flag,
                    label: 'Resign',
                    color: AppTheme.alertRed,
                    onTap: _resignGame,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard({
    required String name,
    required bool isBot,
    required bool isActive,
    required String timeText,
    required bool isThinking,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.surfaceDark : AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? AppTheme.primaryNeon : const Color(0xFF334155),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isBot ? const Color(0xFF3B82F6) : AppTheme.secondaryNeon,
                child: Icon(isBot ? Icons.smart_toy : Icons.person, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                  if (isThinking)
                    const Row(
                      children: [
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryNeon),
                        ),
                        SizedBox(width: 6),
                        Text('Thinking...', style: TextStyle(fontSize: 11, color: AppTheme.primaryNeon)),
                      ],
                    ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? Colors.black : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isActive ? AppTheme.primaryNeon : const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: AppTheme.primaryNeon),
                const SizedBox(width: 4),
                Text(
                  timeText,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideSelector({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surfaceDark : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryNeon : const Color(0xFF334155),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color color = AppTheme.primaryNeon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color == AppTheme.alertRed ? color : Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
