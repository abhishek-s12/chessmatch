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
  bool _isScreenCaptureEnabled = false;
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
    await Future.delayed(const Duration(milliseconds: 400));
    await _checkPermission();
  }

  Future<void> _toggleOverlay() async {
    if (_isOverlayRunning) {
      await OverlayService.stopOverlay();
      if (!mounted) return;
      setState(() {
        _isOverlayRunning = false;
        _isScreenCaptureEnabled = false;
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
        bestMove: "e4",
        isWhite: true,
      );
    }
  }

  Future<void> _enableScreenCapture() async {
    if (!_isOverlayRunning) {
      await _toggleOverlay();
    }
    final success = await OverlayService.startScreenCapture();
    if (mounted) {
      setState(() {
        _isScreenCaptureEnabled = success;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '📸 Screen Capture Enabled! Tap 📸 on the floating bubble to scan the screen.'
                : 'Screen capture permission was not granted.',
          ),
          backgroundColor: success ? AppTheme.secondaryNeon : AppTheme.alertRed,
          duration: const Duration(seconds: 3),
        ),
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
          'FLOATING OVERLAY & SCREEN DETECTOR',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 14),
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
                        Icon(Icons.camera_alt_outlined, color: AppTheme.primaryNeon, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Live Screen Chessboard Auto-Detect',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'BlurChess can capture your live Android screen, detect the 8x8 chessboard and pieces from Chess.com or Lichess, and calculate instant Stockfish moves on the floating bubble.',
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
                            'Overlay & Screen Capture',
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
                              _isOverlayRunning ? 'OVERLAY ACTIVE' : 'OFFLINE',
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
                      else ...[
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isOverlayRunning ? AppTheme.alertRed : AppTheme.primaryNeon,
                            foregroundColor: Colors.black,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: Icon(_isOverlayRunning ? Icons.stop_circle : Icons.play_arrow),
                          label: Text(
                            _isOverlayRunning ? 'STOP FLOATING OVERLAY' : 'START FLOATING OVERLAY',
                            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                          onPressed: _toggleOverlay,
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            side: BorderSide(
                              color: _isScreenCaptureEnabled ? AppTheme.secondaryNeon : AppTheme.primaryNeon,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: Icon(
                            _isScreenCaptureEnabled ? Icons.check_circle : Icons.camera_alt,
                            color: _isScreenCaptureEnabled ? AppTheme.secondaryNeon : AppTheme.primaryNeon,
                          ),
                          label: Text(
                            _isScreenCaptureEnabled ? 'SCREEN CAPTURE AUTHORIZED (READY)' : 'ENABLE SCREEN AUTO-DETECT (MEDIA PROJECTION)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: _isScreenCaptureEnabled ? AppTheme.secondaryNeon : AppTheme.primaryNeon,
                            ),
                          ),
                          onPressed: _enableScreenCapture,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Visual Preview of the Floating HUD Bubble
              const Text(
                'Luxury Floating HUD Preview',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xF4090D16),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(color: AppTheme.primaryNeon, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryNeon.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          '♔ W',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0x2038BDF8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x4038BDF8)),
                        ),
                        child: const Text(
                          '↻ SYNC',
                          style: TextStyle(
                            color: AppTheme.primaryNeon,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '● LIVE',
                        style: TextStyle(
                          color: AppTheme.secondaryNeon,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0x2022C55E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x4022C55E)),
                        ),
                        child: const Text(
                          '+0.4',
                          style: TextStyle(
                            color: AppTheme.secondaryNeon,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Nf3',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '✕',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // How to Use Guide
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📱 How to use with Chess.com:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 8),
                    Text('1. Tap "START FLOATING OVERLAY" and "ENABLE SCREEN AUTO-DETECT".', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    SizedBox(height: 4),
                    Text('2. Switch to the Chess.com app or a browser showing a chess match.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    SizedBox(height: 4),
                    Text('3. Tap the 📸 icon on the floating bubble anytime to scan and calculate the best move in <150ms!', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

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
                        'Send real-time eval presets directly to your floating overlay to test live responses.',
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
