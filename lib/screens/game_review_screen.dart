import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/chess_game_state.dart';
import '../models/chess_piece.dart';
import '../services/game_review_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chess_board_widget.dart';

class GameReviewScreen extends StatefulWidget {
  const GameReviewScreen({super.key});

  @override
  State<GameReviewScreen> createState() => _GameReviewScreenState();
}

class _GameReviewScreenState extends State<GameReviewScreen> {
  final GameReviewService _reviewService = GameReviewService();
  final ChessGameState _reviewGame = ChessGameState();

  GameReviewReport? _report;
  bool _isLoading = true;
  int _currentMoveIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAnalysis();
    });
  }

  Future<void> _runAnalysis() async {
    final liveGame = Provider.of<ChessGameState>(context, listen: false);
    if (liveGame.moveHistory.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final report = await _reviewService.analyzeGame(liveGame);
    if (mounted) {
      setState(() {
        _report = report;
        _isLoading = false;
        if (report.moves.isNotEmpty) {
          _currentMoveIndex = 0;
          _reviewGame.loadFen(report.moves.first.fenAfter);
        }
      });
    }
  }

  void _jumpToMove(int index) {
    if (_report == null || index < 0 || index >= _report!.moves.length) return;
    setState(() {
      _currentMoveIndex = index;
      _reviewGame.loadFen(_report!.moves[index].fenAfter);
    });
  }

  void _showPgnDialog() {
    final liveGame = Provider.of<ChessGameState>(context, listen: false);
    final pgn = liveGame.generatePgn();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Export PGN', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                pgn,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: pgn));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PGN copied to clipboard!')),
              );
            },
            child: const Text('Copy PGN', style: TextStyle(color: AppTheme.primaryNeon)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryNeon, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChessGameState>.value(
      value: _reviewGame,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('GAME REVIEW & ACCURACY', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Export PGN',
              onPressed: _showPgnDialog,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryNeon),
                    SizedBox(height: 16),
                    Text('Evaluating every move...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    SizedBox(height: 6),
                    Text('Calculating accuracies & blunder detections', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              )
            : (_report == null || _report!.moves.isEmpty)
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline, color: AppTheme.textMuted, size: 48),
                        const SizedBox(height: 12),
                        const Text('No moves played yet to review.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Play a game or load a FEN first!', style: TextStyle(color: AppTheme.textMuted)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNeon, foregroundColor: Colors.black),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  )
                : SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          // Accuracies Scorecard
                          _buildAccuracyCard(),
                          const SizedBox(height: 12),

                          // Move Explanation Card
                          if (_currentMoveIndex >= 0 && _currentMoveIndex < _report!.moves.length)
                            _buildMoveFeedbackCard(_report!.moves[_currentMoveIndex]),
                          const SizedBox(height: 10),

                          // Review Board
                          ChessBoardWidget(
                            interactive: false,
                            bestMoveUci: _currentMoveIndex >= 0 ? _report!.moves[_currentMoveIndex].bestMoveUci : null,
                          ),
                          const SizedBox(height: 10),

                          // Eval Timeline Graph
                          _buildEvalGraph(),
                          const SizedBox(height: 10),

                          // Stepper Controls
                          _buildStepperToolbar(),
                          const SizedBox(height: 12),

                          // Move History Chips
                          _buildMoveChips(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildAccuracyCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildAccuracyPlayer(
            label: 'White Player',
            accuracy: _report!.whiteAccuracy,
            isWhite: true,
          ),
          Container(height: 45, width: 1, color: const Color(0xFF334155)),
          _buildAccuracyPlayer(
            label: 'Black Player',
            accuracy: _report!.blackAccuracy,
            isWhite: false,
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyPlayer({
    required String label,
    required double accuracy,
    required bool isWhite,
  }) {
    Color accColor = AppTheme.secondaryNeon;
    if (accuracy < 60) accColor = AppTheme.alertRed;
    else if (accuracy < 80) accColor = Colors.amber;

    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.circle, color: isWhite ? Colors.white : Colors.grey, size: 12),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$accuracy%',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: accColor,
          ),
        ),
        const Text('Move Accuracy', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildMoveFeedbackCard(ReviewedMove move) {
    final cls = move.classification;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(cls.colorHex), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Color(cls.colorHex).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(cls.colorHex)),
            ),
            child: Text(
              '${cls.symbol} ${cls.name}',
              style: TextStyle(
                color: Color(cls.colorHex),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${(move.moveIndex ~/ 2) + 1}${move.isWhite ? "." : "..."} ${move.san}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  move.explanation,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvalGraph() {
    if (_report == null || _report!.evalTimeline.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 50,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: CustomPaint(
        painter: _EvalGraphPainter(
          timeline: _report!.evalTimeline,
          currentIndex: _currentMoveIndex,
        ),
      ),
    );
  }

  Widget _buildStepperToolbar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.first_page),
          tooltip: 'First Move',
          onPressed: _currentMoveIndex > 0 ? () => _jumpToMove(0) : null,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous Move',
          onPressed: _currentMoveIndex > 0 ? () => _jumpToMove(_currentMoveIndex - 1) : null,
        ),
        Text(
          'Move ${_currentMoveIndex + 1} / ${_report!.moves.length}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next Move',
          onPressed: _currentMoveIndex < _report!.moves.length - 1
              ? () => _jumpToMove(_currentMoveIndex + 1)
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.last_page),
          tooltip: 'Last Move',
          onPressed: _currentMoveIndex < _report!.moves.length - 1
              ? () => _jumpToMove(_report!.moves.length - 1)
              : null,
        ),
      ],
    );
  }

  Widget _buildMoveChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_report!.moves.length, (idx) {
          final m = _report!.moves[idx];
          final isSel = idx == _currentMoveIndex;
          final cls = m.classification;

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ActionChip(
              backgroundColor: isSel ? Color(cls.colorHex).withOpacity(0.3) : AppTheme.cardDark,
              side: BorderSide(color: isSel ? Color(cls.colorHex) : const Color(0xFF334155)),
              label: Text(
                '${(idx ~/ 2) + 1}${m.isWhite ? "." : "..."} ${m.san} ${cls.symbol}',
                style: TextStyle(
                  color: isSel ? Color(cls.colorHex) : Colors.white,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
              onPressed: () => _jumpToMove(idx),
            ),
          );
        }),
      ),
    );
  }
}

class _EvalGraphPainter extends CustomPainter {
  final List<double> timeline;
  final int currentIndex;

  _EvalGraphPainter({required this.timeline, required this.currentIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final linePaint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), linePaint);

    if (timeline.isEmpty) return;

    final stepX = size.width / math.max(1, timeline.length - 1);
    final path = Path();

    for (int i = 0; i < timeline.length; i++) {
      final cp = timeline[i].clamp(-5.0, 5.0);
      final x = i * stepX;
      // White advantage -> higher, Black advantage -> lower
      final y = midY - (cp / 5.0) * (midY - 4);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final evalLinePaint = Paint()
      ..color = AppTheme.primaryNeon
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, evalLinePaint);

    // Indicator dot for current move
    if (currentIndex >= 0 && currentIndex < timeline.length) {
      final curCp = timeline[currentIndex].clamp(-5.0, 5.0);
      final curX = currentIndex * stepX;
      final curY = midY - (curCp / 5.0) * (midY - 4);

      final dotPaint = Paint()..color = AppTheme.secondaryNeon;
      canvas.drawCircle(Offset(curX, curY), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EvalGraphPainter oldDelegate) =>
      oldDelegate.timeline != timeline || oldDelegate.currentIndex != currentIndex;
}
