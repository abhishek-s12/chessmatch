import 'dart:math' as math;
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppTheme.textMuted)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Game Review & Coach',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
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
                  Text(
                    'Analyzing game with Stockfish Engine...',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                  ),
                ],
              ),
            )
          : _report == null || _report!.moves.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Coach Review Banner & Accuracy Gauges
                      _buildCoachSummaryCard(),
                      const SizedBox(height: 14),

                      // Interactive Chess Board in Review Mode
                      ChangeNotifierProvider<ChessGameState>.value(
                        value: _reviewGame,
                        child: ChessBoardWidget(
                          interactive: false,
                          bestMoveUci: _currentMoveIndex >= 0 && _currentMoveIndex < _report!.moves.length
                              ? _report!.moves[_currentMoveIndex].bestMoveUci
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Interactive Eval Spline Graph
                      _buildEvalGraph(),
                      const SizedBox(height: 8),

                      // Move Stepper Navigation Toolbar
                      _buildStepperToolbar(),
                      const SizedBox(height: 12),

                      // Current Move Detail & Explanation Card
                      if (_currentMoveIndex >= 0 && _currentMoveIndex < _report!.moves.length)
                        _buildCurrentMoveCard(_report!.moves[_currentMoveIndex]),
                      const SizedBox(height: 14),

                      // Horizontal Scrollable Move Chips
                      _buildMoveChips(),
                      const SizedBox(height: 16),

                      // Classification Scorecard Table
                      _buildScorecardTable(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: const Icon(Icons.analytics_outlined, size: 52, color: AppTheme.primaryNeon),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Game to Review Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Play a match against an engine bot or analyze moves in Live Analysis to generate deep game review reports.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachSummaryCard() {
    final wAcc = _report!.whiteAccuracy.toStringAsFixed(1);
    final bAcc = _report!.blackAccuracy.toStringAsFixed(1);

    String coachTitle = 'Solid Battle!';
    String coachSubtitle = 'Well-contested game with great positional maneuvers.';
    if (_report!.whiteAccuracy > 85.0 || _report!.blackAccuracy > 85.0) {
      coachTitle = 'Master-Level Accuracy!';
      coachSubtitle = 'Remarkable play with near-flawless tactical precision.';
    } else if (_report!.whiteAccuracy < 60.0 && _report!.blackAccuracy < 60.0) {
      coachTitle = 'Wild Tactical Game!';
      coachSubtitle = 'Both sides had exciting tactical swings and opportunities.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF0369A1)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.psychology, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coachTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      coachSubtitle,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAccuracyMeter(
                  player: 'White',
                  accuracy: wAcc,
                  color: Colors.white,
                  fillPercent: _report!.whiteAccuracy / 100.0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAccuracyMeter(
                  player: 'Black',
                  accuracy: bAcc,
                  color: const Color(0xFF94A3B8),
                  fillPercent: _report!.blackAccuracy / 100.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyMeter({
    required String player,
    required String accuracy,
    required Color color,
    required double fillPercent,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                player,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                '$accuracy%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.secondaryNeon,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fillPercent.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF1E293B),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondaryNeon),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentMoveCard(ReviewedMove move) {
    final cls = move.classification;
    final isWhite = move.isWhite;
    final moveNum = (move.moveIndex ~/ 2) + 1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(cls.colorHex).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildClassificationBadge(cls),
                  const SizedBox(width: 8),
                  Text(
                    '$moveNum.${isWhite ? "" : ".."} ${move.san}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Eval: ${move.evalCp >= 0 ? "+" : ""}${move.evalCp.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: move.evalCp >= 0 ? AppTheme.primaryNeon : AppTheme.alertRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            move.explanation,
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.3),
          ),
          if (cls != MoveClassification.best && cls != MoveClassification.book && cls != MoveClassification.brilliant) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: AppTheme.bestGreen),
                const SizedBox(width: 4),
                Text(
                  'Engine Best Move: ${move.bestMoveUci}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.bestGreen,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClassificationBadge(MoveClassification cls) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(cls.colorHex),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Color(cls.colorHex).withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '${cls.symbol} ${cls.name}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildEvalGraph() {
    if (_report == null || _report!.evalTimeline.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final localPos = details.localPosition;
        final totalMoves = _report!.moves.length;
        if (totalMoves == 0) return;

        final percent = (localPos.dx / 320).clamp(0.0, 1.0);
        final targetIndex = (percent * (totalMoves - 1)).round();
        _jumpToMove(targetIndex);
      },
      child: Container(
        height: 60,
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
              backgroundColor: isSel ? Color(cls.colorHex).withOpacity(0.35) : AppTheme.cardDark,
              side: BorderSide(color: isSel ? Color(cls.colorHex) : const Color(0xFF334155)),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Color(cls.colorHex),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      cls.symbol,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(idx ~/ 2) + 1}${m.isWhite ? "." : "..."} ${m.san}',
                    style: TextStyle(
                      color: isSel ? Color(cls.colorHex) : Colors.white,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              onPressed: () => _jumpToMove(idx),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildScorecardTable() {
    final categories = MoveClassification.values;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Move Classification Breakdown',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
            children: [
              const TableRow(
                children: [
                  Text('Category', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                  Text('White', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('Black', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                ],
              ),
              ...categories.map((cat) {
                final wCount = _report!.whiteStats[cat] ?? 0;
                final bCount = _report!.blackStats[cat] ?? 0;
                if (wCount == 0 && bCount == 0) return const TableRow(children: [SizedBox.shrink(), SizedBox.shrink(), SizedBox.shrink()]);

                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Color(cat.colorHex),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              cat.symbol,
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(cat.name, style: const TextStyle(fontSize: 12, color: Colors.white)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        wCount.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        bCount.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
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
      canvas.drawCircle(Offset(curX, curY), 4.5, dotPaint);

      final ringPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(curX, curY), 6.5, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EvalGraphPainter oldDelegate) =>
      oldDelegate.timeline != timeline || oldDelegate.currentIndex != currentIndex;
}
