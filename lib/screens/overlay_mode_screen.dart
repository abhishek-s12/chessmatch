import 'package:flutter/material.dart';
import '../services/overlay_service.dart';
import '../theme/app_theme.dart';

class OverlayModeScreen extends StatefulWidget {
  const OverlayModeScreen({super.key});

  @override
  State<OverlayModeScreen> createState() => _OverlayModeScreenState();
}

class _OverlayModeScreenState extends State<OverlayModeScreen> {
  bool _hasPermission = false;
  bool _isOverlayRunning = false;
  String _statusMessage = 'Checking overlay permissions...';

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await OverlayService.checkPermission();
    setState(() {
      _hasPermission = granted;
      _statusMessage = granted
          ? 'Overlay permission granted. Ready to launch floating assistant.'
          : 'Permission required: "Display over other apps" is needed for floating bubble.';
    });
  }

  Future<void> _requestPermission() async {
    await OverlayService.requestPermission();
    await _checkPermission();
  }

  Future<void> _toggleOverlay() async {
    if (_isOverlayRunning) {
      await OverlayService.stopOverlay();
      setState(() {
        _isOverlayRunning = false;
      });
    } else {
      if (!_hasPermission) {
        await _requestPermission();
        return;
      }
      await OverlayService.startOverlay();
      setState(() {
        _isOverlayRunning = true;
      });

      // Send initial test payload
      await OverlayService.updateOverlay(
        eval: "+0.3",
        bestMove: "e2e4",
        isWhite: true,
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
              // Notice & Fair Play Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.accentPurple, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.security, color: AppTheme.primaryNeon, size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'Study & Post-Game Analysis Mode',
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
                      'The floating bubble floats over other apps on Android, giving you instant move evaluations and positional scores for offline games, bot matches, and post-game reviews.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0x33EF4444),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x66EF4444)),
                      ),
                      child: const Text(
                        'Fair Play Note: Using real-time move assistance during live rated games on Chess.com/Lichess is strictly prohibited.',
                        style: TextStyle(fontSize: 11, color: Color(0xFFFCA5A5)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Permission & Control Status
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Android Overlay Service',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          fontSize: 13,
                          color: _hasPermission ? AppTheme.secondaryNeon : AppTheme.alertRed,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (!_hasPermission)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryNeon,
                            foregroundColor: Colors.black,
                            minimumSize: const Size.fromHeight(46),
                          ),
                          icon: const Icon(Icons.lock_open),
                          label: const Text('Grant Overlay Permission'),
                          onPressed: _requestPermission,
                        )
                      else
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isOverlayRunning ? AppTheme.alertRed : AppTheme.secondaryNeon,
                            foregroundColor: Colors.black,
                            minimumSize: const Size.fromHeight(46),
                          ),
                          icon: Icon(_isOverlayRunning ? Icons.stop : Icons.play_arrow),
                          label: Text(
                            _isOverlayRunning ? 'Stop Floating Overlay' : 'Start Floating Overlay',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: _toggleOverlay,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Visual Preview of the Floating Bubble
              const Text(
                'Overlay Pill Preview',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xE60F172A),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppTheme.primaryNeon, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryNeon.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '+1.4',
                        style: TextStyle(
                          color: AppTheme.secondaryNeon,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Next: e2e4',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
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
