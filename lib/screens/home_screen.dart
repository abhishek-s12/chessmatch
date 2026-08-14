import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'analysis_screen.dart';
import 'bot_match_screen.dart';
import 'game_review_screen.dart';
import 'overlay_mode_screen.dart';
import 'puzzle_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Header & Branding
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.sports_esports, color: AppTheme.primaryNeon, size: 28),
                            SizedBox(width: 8),
                            Text(
                              'CHESSMATCH',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'v2.0',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondaryNeon,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'AI Engine, Bot Matches, Game Review & Floating Overlay',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: AppTheme.textMuted),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Hero Feature 1: Play vs AI Bots
              _buildFeatureCard(
                context,
                title: 'Play vs Engine Bots',
                subtitle: 'Challenge 6 adaptive AI personalities (800 to 2600+ ELO) with chess clocks & takebacks.',
                icon: Icons.smart_toy_outlined,
                gradientColors: [const Color(0xFF0284C7), const Color(0xFF0369A1)],
                accentColor: AppTheme.primaryNeon,
                badgeText: 'BOT MATCHES',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BotMatchScreen()),
                  );
                },
              ),
              const SizedBox(height: 14),

              // Hero Feature 2: Post-Game Review & Move Analysis
              _buildFeatureCard(
                context,
                title: 'Post-Game Review & Accuracies',
                subtitle: 'Deep analysis with move classification (Brilliant, Best, Blunder) and eval graph.',
                icon: Icons.insights_outlined,
                gradientColors: [const Color(0xFF7C3AED), const Color(0xFF6D28D9)],
                accentColor: AppTheme.accentPurple,
                badgeText: 'GAME REVIEW',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GameReviewScreen()),
                  );
                },
              ),
              const SizedBox(height: 14),

              // Hero Feature 3: Tactical Puzzle Trainer
              _buildFeatureCard(
                context,
                title: 'Tactical Puzzle Trainer',
                subtitle: 'Sharpen your calculation with curated chess tactics (Mate in 1/2, Forks, Pins, Deflections).',
                icon: Icons.extension_outlined,
                gradientColors: [const Color(0xFFD97706), const Color(0xFFB45309)],
                accentColor: Colors.amber,
                badgeText: 'TACTICS DRILLS',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PuzzleScreen()),
                  );
                },
              ),
              const SizedBox(height: 14),

              // Hero Feature 4: Live Engine Analysis Board
              _buildFeatureCard(
                context,
                title: 'Live Engine Analyzer',
                subtitle: 'Analyze any position, calculate top engine lines, explore PV lines, and import/export FEN.',
                icon: Icons.analytics_outlined,
                gradientColors: [const Color(0xFF059669), const Color(0xFF047857)],
                accentColor: AppTheme.secondaryNeon,
                badgeText: 'STOCKFISH 2.0',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AnalysisScreen()),
                  );
                },
              ),
              const SizedBox(height: 14),

              // Hero Feature 5: Floating Screen Overlay
              _buildFeatureCard(
                context,
                title: 'Floating Screen Overlay',
                subtitle: 'Android floating pill assistant displaying live eval score and best move on top of third-party apps.',
                icon: Icons.picture_in_picture_alt,
                gradientColors: [const Color(0xFF475569), const Color(0xFF334155)],
                accentColor: const Color(0xFF94A3B8),
                badgeText: 'ANDROID OVERLAY',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OverlayModeScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Fair Play & Ethics Footer Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.shield_outlined, color: AppTheme.textMuted, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Designed for offline study, bot practice, and post-game review. Respect fair play guidelines across chess communities.',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required Color accentColor,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradientColors),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
