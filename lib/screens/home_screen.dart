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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grandmaster Header & App Branding
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppTheme.primaryNeon, Color(0xFF0284C7)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.sports_esports, color: Colors.black, size: 20),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'BLURCHESS',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accentGold.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.accentGold.withOpacity(0.5)),
                              ),
                              child: const Text(
                                'PRO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.accentGold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Stockfish AI • Game Review Coach • Floating Assistant',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune_outlined, color: AppTheme.textMuted),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Hero Feature 1: Play vs Engine Bots (Large Feature Banner)
              _buildHeroPlayBanner(context),
              const SizedBox(height: 14),

              // Hero Feature 2: Post-Game Review Coach (Chess.com style)
              _buildFeatureTile(
                context,
                title: 'Game Review & Coach',
                subtitle: 'Accuracies, move classifications (!!, !, ★, ??), and interactive eval timeline.',
                badge: 'COACH',
                badgeColor: AppTheme.brilliantCyan,
                icon: Icons.psychology_outlined,
                gradient: const [Color(0xFF0F766E), Color(0xFF115E59)],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GameReviewScreen()),
                ),
              ),
              const SizedBox(height: 12),

              // Hero Feature 3: Tactical Puzzle Trainer
              _buildFeatureTile(
                context,
                title: 'Tactical Puzzle Trainer',
                subtitle: 'Mate in 1/2, Forks, Pins, & Deflections with streak counter and rating progress.',
                badge: 'TACTICS',
                badgeColor: AppTheme.accentGold,
                icon: Icons.extension_outlined,
                gradient: const [Color(0xFFB45309), Color(0xFF92400E)],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PuzzleScreen()),
                ),
              ),
              const SizedBox(height: 12),

              // Hero Feature 4: Live Engine Analyzer
              _buildFeatureTile(
                context,
                title: 'Live Engine Analyzer',
                subtitle: 'Deep position evaluation, PV lines, best move arrows, FEN/PGN import & export.',
                badge: 'STOCKFISH',
                badgeColor: AppTheme.secondaryNeon,
                icon: Icons.analytics_outlined,
                gradient: const [Color(0xFF065F46), Color(0xFF064E3B)],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnalysisScreen()),
                ),
              ),
              const SizedBox(height: 12),

              // Hero Feature 5: Floating Screen Overlay
              _buildFeatureTile(
                context,
                title: 'Floating Screen Overlay',
                subtitle: 'Live eval pill overlay on top of any third-party app with Stockfish calculations.',
                badge: 'ANDROID',
                badgeColor: AppTheme.primaryNeon,
                icon: Icons.picture_in_picture_alt,
                gradient: const [Color(0xFF1E293B), Color(0xFF0F172A)],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OverlayModeScreen()),
                ),
              ),
              const SizedBox(height: 20),

              // Fair Play & Ethics Footer Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_outlined, color: AppTheme.textMuted, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Designed for offline study, engine practice, and post-game review. Respect fair play across all chess communities.',
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

  Widget _buildHeroPlayBanner(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BotMatchScreen()),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38BDF8).withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNeon.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.5)),
                    ),
                    child: const Text(
                      'FEATURED ARENA',
                      style: TextStyle(
                        color: AppTheme.primaryNeon,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: AppTheme.primaryNeon, size: 16),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Play vs Engine Bots',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Challenge 6 adaptive AI bots (800 to 2600+ ELO) with live tournament clocks, takebacks, and hints.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildBotChip('Novice 800'),
                  const SizedBox(width: 6),
                  _buildBotChip('Club 1600'),
                  const SizedBox(width: 6),
                  _buildBotChip('GM 2600+'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFeatureTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: badgeColor.withOpacity(0.4)),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        height: 1.3,
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
}
