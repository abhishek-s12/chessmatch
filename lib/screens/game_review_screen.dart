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
  bool _showBestMoveOnBoard = false;
  int _selectedTab = 0; // 0: Review, 1: Key Moments, 2: Report Card

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
      _showBestMoveOnBoard = false;
      _reviewGame.loadFen(_report!.moves[index].fenAfter);
    });
  }

  List<int> get _keyMomentIndices {
    if (_report == null) return [];
    final list = <int>[];
    for (int i = 0; i < _report!.moves.length; i++) {
      final cls = _report!.moves[i].classification;
      if (cls == MoveClassification.brilliant ||
          cls == MoveClassification.great ||
          cls == MoveClassification.missedWin ||
          cls == MoveClassification.blunder ||
          cls == MoveClassification.mistake) {
        list.add(i);
      }
    }
    return list;
  }

  void _jumpNextKeyMoment() {
    final km = _keyMomentIndices;
    if (km.isEmpty) return;
    final next = km.firstWhere((idx) => idx > _currentMoveIndex, orElse: () => km.first);
    _jumpToMove(next);
  }

  void _jumpPrevKeyMoment() {
    final km = _keyMomentIndices;
    if (km.isEmpty) return;
    final prev = km.lastWhere((idx) => idx < _currentMoveIndex, orElse: () => km.last);
    _jumpToMove(prev);
  }

  void _showPgnDialog() {
    final liveGame = Provider.of<ChessGameState>(context, listen: false);
    final pgn = liveGame.generatePgn();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF262421),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Export PGN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1C18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SelectableText(
            pgn,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white70),
          ),
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
            child: const Text('Copy PGN', style: TextStyle(color: Color(0xFF81B64C), fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1C18), // Official Chess.com dark background
      appBar: AppBar(
        backgroundColor: const Color(0xFF262421),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.diamond, color: Color(0xFF38BDF8), size: 20),
            SizedBox(width: 8),
            Text(
              'Game Review',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
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
                  CircularProgressIndicator(color: Color(0xFF81B64C)),
                  SizedBox(height: 16),
                  Text(
                    'Generating Chess.com Diamond Review...',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            )
          : _report == null || _report!.moves.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Tab Bar: Review | Key Moments | Report Card
                    _buildChessComTabBar(),

                    // Main Content Area
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_selectedTab == 0 || _selectedTab == 1) ...[
                              // Coach Match Statement Banner
                              _buildCoachBanner(),
                              const SizedBox(height: 10),

                              // Interactive Chessboard
                              ChangeNotifierProvider<ChessGameState>.value(
                                value: _reviewGame,
                                child: ChessBoardWidget(
                                  interactive: false,
                                  bestMoveUci: _showBestMoveOnBoard &&
                                          _currentMoveIndex >= 0 &&
                                          _currentMoveIndex < _report!.moves.length
                                      ? _report!.moves[_currentMoveIndex].bestMoveUci
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Move Navigation Stepper & Key Moment Button
                              _buildStepperToolbar(),
                              const SizedBox(height: 10),

                              // Move-by-Move Coach Card
                              if (_currentMoveIndex >= 0 && _currentMoveIndex < _report!.moves.length)
                                _buildCurrentMoveCoachCard(_report!.moves[_currentMoveIndex]),
                              const SizedBox(height: 12),

                              // Advantage Spline Timeline Graph
                              _buildEvalGraph(),
                              const SizedBox(height: 12),

                              // Move Chips Carousel
                              _buildMoveChips(),
                            ] else ...[
                              // Full Report Card View
                              _buildFullReportCard(),
                            ],
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildChessComTabBar() {
    return Container(
      color: const Color(0xFF262421),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          _buildTabItem(0, 'Review', Icons.rate_review_outlined),
          const SizedBox(width: 8),
          _buildTabItem(1, 'Key Moments (${_keyMomentIndices.length})', Icons.bolt),
          const SizedBox(width: 8),
          _buildTabItem(2, 'Report Card', Icons.table_chart_outlined),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String title, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3B3935) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF81B64C) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: isSelected ? const Color(0xFF81B64C) : Colors.white60),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.white60,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoachBanner() {
    final wAcc = _report!.whiteAccuracy.toStringAsFixed(1);
    final bAcc = _report!.blackAccuracy.toStringAsFixed(1);

    String verdict = 'You played like a Grandmaster!';
    if (_report!.whiteAccuracy < 70.0 && _report!.blackAccuracy < 70.0) {
      verdict = 'A wild and aggressive tactical match!';
    } else if (_report!.whiteAccuracy > 90.0) {
      verdict = 'Near-perfect engine precision!';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF262421),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3B3935)),
      ),
      child: Row(
        children: [
          // Coach Avatar Badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF81B64C),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF81B64C).withOpacity(0.4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Center(
              child: Text('👨‍🏫', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),

          // Coach Verdict Statement
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verdict,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'White $wAcc%  •  Black $bAcc% Accuracy',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF81B64C), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Key Moments Shortcut Pill
          if (_keyMomentIndices.isNotEmpty)
            InkWell(
              onTap: _jumpNextKeyMoment,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF81B64C),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, size: 14, color: Colors.black),
                    SizedBox(width: 2),
                    Text(
                      'Next Key',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepperToolbar() {
    final km = _keyMomentIndices;
    final isKeyMoment = km.contains(_currentMoveIndex);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.first_page, color: Colors.white70),
          tooltip: 'First Move',
          onPressed: _currentMoveIndex > 0 ? () => _jumpToMove(0) : null,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left, size: 28, color: Colors.white),
          tooltip: 'Previous Move',
          onPressed: _currentMoveIndex > 0 ? () => _jumpToMove(_currentMoveIndex - 1) : null,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isKeyMoment ? const Color(0xFFFA412D).withOpacity(0.2) : const Color(0xFF262421),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isKeyMoment ? const Color(0xFFFA412D) : const Color(0xFF3B3935),
            ),
          ),
          child: Text(
            'Move ${_currentMoveIndex + 1} of ${_report!.moves.length}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isKeyMoment ? const Color(0xFFFA412D) : Colors.white,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, size: 28, color: Colors.white),
          tooltip: 'Next Move',
          onPressed: _currentMoveIndex < _report!.moves.length - 1
              ? () => _jumpToMove(_currentMoveIndex + 1)
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.last_page, color: Colors.white70),
          tooltip: 'Last Move',
          onPressed: _currentMoveIndex < _report!.moves.length - 1
              ? () => _jumpToMove(_report!.moves.length - 1)
              : null,
        ),
      ],
    );
  }

  Widget _buildCurrentMoveCoachCard(ReviewedMove move) {
    final cls = move.classification;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF262421),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(cls.colorHex), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Color(cls.colorHex).withOpacity(0.15),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Classification Badge & Move Notation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildChessComBadge(cls),
                  const SizedBox(width: 8),
                  Text(
                    '${(_currentMoveIndex ~/ 2) + 1}${move.isWhite ? "." : "..."} ${move.san}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1C18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  move.evalCp >= 0 ? '+${move.evalCp.toStringAsFixed(1)}' : move.evalCp.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: move.evalCp >= 0 ? const Color(0xFF81B64C) : const Color(0xFFFA412D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Coach Commentary
          Text(
            move.explanation,
            style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 10),

          // Show Best Move Engine Line Button
          if (cls != MoveClassification.best &&
              cls != MoveClassification.book &&
              cls != MoveClassification.brilliant) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Color(0xFF81B64C)),
                    const SizedBox(width: 4),
                    Text(
                      'Best: ${move.bestMoveUci}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF81B64C),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                  ),
                  icon: Icon(
                    _showBestMoveOnBoard ? Icons.visibility_off : Icons.visibility,
                    size: 14,
                    color: const Color(0xFF38BDF8),
                  ),
                  label: Text(
                    _showBestMoveOnBoard ? 'Hide Line' : 'Show on Board',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    setState(() {
                      _showBestMoveOnBoard = !_showBestMoveOnBoard;
                    });
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChessComBadge(MoveClassification cls) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(cls.colorHex),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${cls.symbol} ${cls.name}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildEvalGraph() {
    if (_report == null || _report!.evalTimeline.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 55,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF262421),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B3935)),
      ),
      child: CustomPaint(
        painter: _EvalGraphPainter(
          timeline: _report!.evalTimeline,
          currentIndex: _currentMoveIndex,
        ),
      ),
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
              backgroundColor: isSel ? Color(cls.colorHex).withOpacity(0.35) : const Color(0xFF262421),
              side: BorderSide(color: isSel ? Color(cls.colorHex) : const Color(0xFF3B3935)),
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

  Widget _buildFullReportCard() {
    final categories = MoveClassification.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Accuracy Scorecard Comparison Cards
        Row(
          children: [
            Expanded(
              child: _buildAccuracyCard(
                title: 'White',
                accuracy: _report!.whiteAccuracy,
                elo: '2450',
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAccuracyCard(
                title: 'Black',
                accuracy: _report!.blackAccuracy,
                elo: '1800',
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Chess.com Classification Breakdown Table
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF262421),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF3B3935)),
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
                      Text('Category', style: TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.bold)),
                      Text('White', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('Black', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  ...categories.map((cat) {
                    final wCount = _report!.whiteStats[cat] ?? 0;
                    final bCount = _report!.blackStats[cat] ?? 0;
                    if (wCount == 0 && bCount == 0) {
                      return const TableRow(children: [SizedBox.shrink(), SizedBox.shrink(), SizedBox.shrink()]);
                    }

                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Text(
                            wCount.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Text(
                            bCount.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white54),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccuracyCard({
    required String title,
    required double accuracy,
    required String elo,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF262421),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3B3935)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: (accuracy / 100).clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFF1E1C18),
                  color: const Color(0xFF81B64C),
                  strokeWidth: 5,
                ),
              ),
              Text(
                '${accuracy.toStringAsFixed(1)}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Performance: ~$elo',
            style: const TextStyle(fontSize: 11, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF262421),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF81B64C), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF81B64C).withOpacity(0.3),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.diamond_outlined, size: 48, color: Color(0xFF81B64C)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Diamond Game Review',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Experience full Chess.com Diamond Review with CAPS accuracy ratings, coach Danny explanations, and brilliant move breakdown!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF81B64C),
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.auto_awesome),
              label: const Text(
                'Review Paul Morphy\'s Opera Game (Immortal)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: _loadSampleMorphyGame,
            ),
          ],
        ),
      ),
    );
  }

  void _loadSampleMorphyGame() async {
    setState(() {
      _isLoading = true;
    });

    final sampleGame = ChessGameState();
    final uciMoves = [
      'e2e4', 'e7e5', 'g1f3', 'd7d6', 'd2d4', 'c8g4', 'd4e5', 'g4f3',
      'd1f3', 'd6e5', 'f1c4', 'g8f6', 'f3b3', 'd8e7', 'b1c3', 'c7c6',
      'c1g5', 'b7b5', 'c3b5', 'c6b5', 'c4b5', 'b8d7', 'e1c1', 'a8d8',
      'd1d7', 'd8d7', 'h1d1', 'e7e6', 'b5d7', 'f6d7', 'b3b8', 'd7b8',
      'd1d8',
    ];

    for (final uci in uciMoves) {
      final m = ChessMove.fromUci(uci);
      if (m != null) {
        sampleGame.makeMove(m);
      }
    }

    final report = await _reviewService.analyzeGame(sampleGame);
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
      final y = midY - (cp / 5.0) * (midY - 4);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final evalLinePaint = Paint()
      ..color = const Color(0xFF81B64C)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, evalLinePaint);

    if (currentIndex >= 0 && currentIndex < timeline.length) {
      final curCp = timeline[currentIndex].clamp(-5.0, 5.0);
      final curX = currentIndex * stepX;
      final curY = midY - (curCp / 5.0) * (midY - 4);

      final dotPaint = Paint()..color = const Color(0xFF38BDF8);
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
