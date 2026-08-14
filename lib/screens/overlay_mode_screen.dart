import 'package:flutter/material.dart';
import '../services/overlay_service.dart';
import '../services/stockfish_engine_service.dart';
import '../models/chess_game_state.dart';
import '../theme/app_theme.dart';

class OverlayModeScreen extends StatefulWidget {
  const OverlayModeScreen({super.key});

  @override
  State<OverlayModeScreen> createState() => _OverlayModeScreenState();
}

class _OverlayModeScreenState extends State<OverlayModeScreen> with WidgetsBindingObserver {
  final StockfishEngineService _engineService = StockfishEngineService();
  final ChessGameState _testGame = ChessGameState();

  bool _hasPermission = false;
  bool _isOverlayRunning = false;
  bool _isTestingLiveEngine = false;
  String _statusMessage = 'Checking overlay permissions...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _engineService.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final granted = await OverlayService.checkPermission();
    if (!mounted) return;
    setState(() {
      _hasPermission = granted;
      _statusMessage = granted
          ? 'Overlay permission granted. Ready to launch floating assistant.'
          : 'Permission required: "Display over other apps" is needed for the floating pill.';
    });
  }

  Future<void> _requestPermission() async {
    await OverlayService.requestPermission();
    // Allow small delay for OS intent
    await Future.delayed(const Duration(milliseconds: 400));
    await _checkPermission();
  }

  Future<void> _toggleOverlay() async {
    if (_isOverlayRunning) {
      await OverlayService.stopOverlay();
      if (!mounted) return;
      setState(() {
        _isOverlayRunning = false;
        _isTestingLiveEngine = false;
      });
    } else {
      if (!_hasPermission) {
        await _requestPermission();
        return;
      }
      await OverlayService.startOverlay();
      if (!mounted) return;
      setState(() {
        _isOverlayRunning = true;
      });

      // Send initial test evaluation
      await OverlayService.updateOverlay(
        eval: "+0.3",
        bestMove: "e2e4",
        isWhite: true,
      );
    }
  }

  Future<void> _sendTestEvaluation(String eval, String move, bool isWhite) async {
    if (!_isOverlayRunning) {
      await _toggleOverlay();
    }
    await OverlayService.updateOverlay(
      eval: eval,
      bestMove: move,
      isWhite: isWhite,
    );
  }

  Future<void> _runLiveEngineCalc() async {
    setState(() {
      _isTestingLiveEngine = true;
    });

    final eval = await _engineService.evaluatePosition(_testGame, depth: 5);

    if (mounted) {
      setState(() {
        _isTestingLiveEngine = false;
      });
      await OverlayService.updateOverlay(
        eval: eval.displayScore,
        bestMove: eval.bestMove,
        isWhite: eval.scoreCp >= 0,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated overlay with Stockfish eval: ${eval.displayScore} (Best: ${eval.bestMove})'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FLOATING OVERLAY ASSISTANT',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 15),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Study Mode & Fair Play Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.picture_in_picture_alt, color: AppTheme.primaryNeon, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'BlurChess Floating Bubble',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'The floating pill stays on top of your screen while using other apps, displaying live Stockfish engine evaluations and top moves for post-game study and bot practice.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Permission & Master Launch Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Overlay Service Status',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (_isOverlayRunning ? AppTheme.secondaryNeon : const Color(0xFF64748B)).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _isOverlayRunning ? AppTheme.secondaryNeon : const Color(0xFF64748B),
                              ),
                            ),
                            child: Text(
                              _isOverlayRunning ? 'ACTIVE' : 'OFFLINE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _isOverlayRunning ? AppTheme.secondaryNeon : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          fontSize: 12,
                          color: _hasPermission ? AppTheme.secondaryNeon : const Color(0xFFFCA5A5),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (!_hasPermission)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryNeon,
                            foregroundColor: Colors.black,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.lock_open),
                          label: const Text('Grant Overlay Permission', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: _requestPermission,
                        )
                      else
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isOverlayRunning ? AppTheme.alertRed : AppTheme.primaryNeon,
                            foregroundColor: Colors.black,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: Icon(_isOverlayRunning ? Icons.stop_circle : Icons.play_arrow),
                          label: Text(
                            _isOverlayRunning ? 'STOP FLOATING OVERLAY' : 'LAUNCH FLOATING OVERLAY',
                            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                          onPressed: _toggleOverlay,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Visual Preview of the Floating Bubble
              const Text(
                'Interactive Preview',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xEE0B0F19),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: AppTheme.primaryNeon, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryNeon.withOpacity(0.3),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+1.8',
                        style: TextStyle(
                          color: AppTheme.secondaryNeon,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 14),
                      Text(
                        'Next: Nf3',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'D12',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Test Presets & Live Engine Trigger
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Engine Broadcasts',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Send real-time eval presets directly to your floating overlay to verify live updates.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () => _sendTestEvaluation('+2.4', 'Nf3', true),
                            child: const Text('White +2.4 (Nf3)'),
                          ),
                          OutlinedButton(
                            onPressed: () => _sendTestEvaluation('-3.1', 'Qxd4', false),
                            child: const Text('Black -3.1 (Qxd4)'),
                          ),
                          OutlinedButton(
                            onPressed: () => _sendTestEvaluation('+0.0', 'e4', true),
                            child: const Text('Equal 0.0 (e4)'),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryNeon,
                              foregroundColor: Colors.black,
                            ),
                            icon: _isTestingLiveEngine
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                  )
                                : const Icon(Icons.psychology, size: 18),
                            label: const Text('Run Stockfish Eval'),
                            onPressed: _isTestingLiveEngine ? null : _runLiveEngineCalc,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
