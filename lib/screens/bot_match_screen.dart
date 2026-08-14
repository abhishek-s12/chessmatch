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
      setState(() {
        if (game.turn == _playerColor) {
          if (_playerTimeSeconds > 0) {
            _playerTimeSeconds--;
          } else {
            _handleGameOver('Time out! Bot wins on time.');
          }
        } else {
          if (_botTimeSeconds > 0) {
            _botTimeSeconds--;
          } else {
            _handleGameOver('Bot ran out of time! You win!');
          }
        }
      });
    });
  }

  void _onPlayerMoveMade(ChessMove move) {
    setState(() {
      _hintMoveUci = null;
      if (_timeControl != TimeControlMode.untimed && _timeControl.increment > 0) {
        _playerTimeSeconds += _timeControl.increment;
      }
    });

    final game = Provider.of<ChessGameState>(context, listen: false);
    if (game.isCheckmate) {
      _handleGameOver('Checkmate! You won against ${_selectedBot.name}!');
      return;
    } else if (game.isStalemate) {
      _handleGameOver('Stalemate! The match is drawn.');
      return;
    }

    _triggerBotMove();
  }

  void _triggerBotMove() async {
    final game = Provider.of<ChessGameState>(context, listen: false);
    if (_isGameOver || game.turn == _playerColor) return;

    setState(() {
      _isBotThinking = true;
    });

    // Human-like response delay (600ms - 1500ms)
    final delayMs = 600 + math.Random().nextInt(700);
    await Future.delayed(Duration(milliseconds: delayMs));

    if (!mounted || _isGameOver) return;

    final botMove = await _engineService.getBestMoveForBot(game, _selectedBot);

    if (mounted && botMove != null && !_isGameOver) {
      final legalMoves = game.generateAllLegalMoves();
      final move = legalMoves.firstWhere(
        (m) => m.uci == botMove,
        orElse: () => legalMoves.first,
      );

      game.makeMove(move);
      SoundService.playMoveSound(isCapture: move.isCapture, isCheck: game.isKingInCheck(game.turn));

      setState(() {
        _isBotThinking = false;
        if (_timeControl != TimeControlMode.untimed && _timeControl.increment > 0) {
          _botTimeSeconds += _timeControl.increment;
        }
      });

      if (game.isCheckmate) {
        _handleGameOver('Checkmate! ${_selectedBot.name} wins.');
      } else if (game.isStalemate) {
        _handleGameOver('Stalemate! The game ended in a draw.');
      }
    } else {
      if (mounted) setState(() => _isBotThinking = false);
    }
  }

  void _handleGameOver(String reason) {
    _clockTimer?.cancel();
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
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: AppTheme.primaryNeon, size: 28),
            SizedBox(width: 10),
            Text('Game Finished', style: TextStyle(fontWeight: FontWeight.bold)),
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
          title: const Text('Play vs Engine Bots', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Bot Personality Cards
              const Text('Choose Your Opponent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ...BotDifficulty.values.map((bot) {
                final isSel = _selectedBot == bot;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _selectedBot = bot),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSel ? AppTheme.surfaceDark : AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSel ? AppTheme.primaryNeon : const Color(0xFF334155),
                            width: isSel ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSel ? AppTheme.primaryNeon.withOpacity(0.2) : const Color(0xFF0F172A),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSel ? AppTheme.primaryNeon : const Color(0xFF334155),
                                ),
                              ),
                              child: Icon(
                                Icons.smart_toy_outlined,
                                color: isSel ? AppTheme.primaryNeon : Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        bot.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentGold.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Depth ${bot.depth}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.accentGold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Blunder rate: ${(bot.blunderRate * 100).toInt()}% • Tactical evaluation',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            if (isSel)
                              const Icon(Icons.check_circle, color: AppTheme.primaryNeon, size: 22),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),
              // Play As Side
              const Text('Play As', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildSideSelector(
                      title: 'White (First)',
                      icon: Icons.circle,
                      iconColor: Colors.white,
                      isSelected: _playerColor == PieceColor.white,
                      onTap: () => setState(() => _playerColor = PieceColor.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSideSelector(
                      title: 'Black (Second)',
                      icon: Icons.circle,
                      iconColor: const Color(0xFF1E293B),
                      isSelected: _playerColor == PieceColor.black,
                      onTap: () => setState(() => _playerColor = PieceColor.black),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
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
                    selectedColor: AppTheme.primaryNeon.withOpacity(0.25),
                    backgroundColor: AppTheme.cardDark,
                    side: BorderSide(color: isSel ? AppTheme.primaryNeon : const Color(0xFF334155)),
                    labelStyle: TextStyle(
                      color: isSel ? AppTheme.primaryNeon : Colors.white,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => setState(() => _timeControl = tc),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),
              // Launch Match Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNeon,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.play_arrow, size: 28),
                  label: const Text(
                    'START BOT MATCH',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                  ),
                  onPressed: _startNewGame,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    }

    // Active Live Bot Match View
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vs ${_selectedBot.name}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'New Game',
            onPressed: _startNewGame,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Opponent Bot Header
            _buildPlayerHeader(
              name: _selectedBot.name,
              isBot: true,
              isTurn: !isPlayerTurn && !_isGameOver,
              timeFormatted: _formatTime(_botTimeSeconds),
              timeSeconds: _botTimeSeconds,
              isThinking: _isBotThinking,
            ),

            // Chess Board
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: ChessBoardWidget(
                    bestMoveUci: _hintMoveUci,
                    onMoveMade: _onPlayerMoveMade,
                    interactive: isPlayerTurn && !_isGameOver && !_isBotThinking,
                  ),
                ),
              ),
            ),

            // Human Player Header
            _buildPlayerHeader(
              name: 'You (${_playerColor == PieceColor.white ? "White" : "Black"})',
              isBot: false,
              isTurn: isPlayerTurn && !_isGameOver,
              timeFormatted: _formatTime(_playerTimeSeconds),
              timeSeconds: _playerTimeSeconds,
              isThinking: false,
            ),

            // Bottom In-Game Controls
            _buildControlBar(context, isPlayerTurn),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerHeader({
    required String name,
    required bool isBot,
    required bool isTurn,
    required String timeFormatted,
    required int timeSeconds,
    required bool isThinking,
  }) {
    final isLowTime = timeSeconds > 0 && timeSeconds <= 30;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isTurn ? AppTheme.surfaceDark : AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTurn ? AppTheme.primaryNeon.withOpacity(0.6) : const Color(0xFF334155),
          width: isTurn ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isBot ? AppTheme.accentPurple : AppTheme.primaryNeon,
                child: Icon(
                  isBot ? Icons.smart_toy : Icons.person,
                  size: 18,
                  color: Colors.white,
                ),
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
                          width: 8,
                          height: 8,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.secondaryNeon),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Calculating move...',
                          style: TextStyle(fontSize: 10, color: AppTheme.secondaryNeon),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),

          // Digital Tournament Clock
          if (_timeControl != TimeControlMode.untimed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isLowTime ? const Color(0xFF7F1D1D) : const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isLowTime ? AppTheme.alertRed : const Color(0xFF334155),
                ),
              ),
              child: Text(
                timeFormatted,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isLowTime ? Colors.white : (isTurn ? AppTheme.primaryNeon : AppTheme.textMuted),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlBar(BuildContext context, bool isPlayerTurn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(top: BorderSide(color: Color(0xFF334155))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.undo,
            label: 'Takeback',
            onTap: _undoMove,
          ),
          _buildActionButton(
            icon: Icons.lightbulb_outline,
            label: 'Hint',
            color: AppTheme.accentGold,
            onTap: isPlayerTurn && !_isGameOver ? _requestHint : null,
          ),
          _buildActionButton(
            icon: Icons.history,
            label: 'Moves',
            onTap: () {
              final game = Provider.of<ChessGameState>(context, listen: false);
              showModalBottomSheet(
                context: context,
                backgroundColor: AppTheme.cardDark,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: MoveHistoryWidget(sanHistory: game.sanHistory),
                ),
              );
            },
          ),
          _buildActionButton(
            icon: Icons.flag_outlined,
            label: 'Resign',
            color: AppTheme.alertRed,
            onTap: !_isGameOver ? _resignGame : null,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color color = AppTheme.textMuted,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: onTap != null ? color : const Color(0xFF475569), size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: onTap != null ? color : const Color(0xFF475569),
              ),
            ),
          ],
        ),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surfaceDark : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryNeon : const Color(0xFF334155),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
