import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _engineDepth = 12.0;
  bool _autoAnalysis = true;
  bool _showArrows = true;
  String _selectedTheme = 'Cyber Dark';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SETTINGS & ENGINE CONFIG',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 15),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Engine Search Depth
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
                          'Stockfish Calculation Depth',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primaryNeon),
                          ),
                          child: Text(
                            'Depth ${_engineDepth.toInt()}',
                            style: const TextStyle(
                              color: AppTheme.primaryNeon,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _engineDepth,
                      min: 4.0,
                      max: 24.0,
                      divisions: 10,
                      activeColor: AppTheme.primaryNeon,
                      inactiveColor: const Color(0xFF334155),
                      onChanged: (val) {
                        setState(() {
                          _engineDepth = val;
                        });
                      },
                    ),
                    const Text(
                      'Higher depth provides deeper grandmaster calculation lines at the cost of slight battery/CPU usage.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Visual Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Visual & Board Customization',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Live Best Move Arrow', style: TextStyle(fontSize: 14)),
                      subtitle: const Text('Renders glowing directional vector overlay on board', style: TextStyle(fontSize: 12)),
                      value: _showArrows,
                      activeColor: AppTheme.secondaryNeon,
                      onChanged: (val) {
                        setState(() {
                          _showArrows = val;
                        });
                      },
                    ),
                    const Divider(color: Color(0xFF334155)),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Instant Position Auto-Evaluation', style: TextStyle(fontSize: 14)),
                      subtitle: const Text('Automatically updates score whenever pieces move', style: TextStyle(fontSize: 12)),
                      value: _autoAnalysis,
                      activeColor: AppTheme.primaryNeon,
                      onChanged: (val) {
                        setState(() {
                          _autoAnalysis = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // About App
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('About Chess Engine & Overlay App', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    SizedBox(height: 8),
                    Text(
                      'Version 1.0.0 (Pro Engine Edition)\nBuilt with Flutter & Android Native Overlay Services for chess analysis, engine training, and post-game study.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
