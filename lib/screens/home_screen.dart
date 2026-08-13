import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'analysis_screen.dart';
import 'overlay_mode_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Title & Tagline
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.sports_esports, color: AppTheme.primaryNeon, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'CHESS ENGINE',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Instant Move Analyzer & Android Floating Overlay',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
              const SizedBox(height: 28),

              // Hero Action Card 1: Interactive Analysis Board
              _buildFeatureCard(
                context,
                title: 'Live Engine Analysis',
                subtitle: 'Analyze any position, calculate top engine lines, view eval bar, and test best moves.',
                icon: Icons.analytics_outlined,
                gradientColors: [const Color(0xFF0284C7), const Color(0xFF0369A1)],
                accentColor: AppTheme.primaryNeon,
                badgeText: 'REAL-TIME STOCKFISH',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AnalysisScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Hero Action Card 2: Floating Overlay Mode
              _buildFeatureCard(
                context,
                title: 'Floating Screen Overlay',
                subtitle: 'Android floating bubble widget that stays on screen during review or bot practice.',
                icon: Icons.picture_in_picture_alt,
                gradientColors: [const Color(0xFF059669), const Color(0xFF047857)],
                accentColor: AppTheme.secondaryNeon,
                badgeText: 'ANDROID OVERLAY',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OverlayModeScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Hero Action Card 3: Bot Practice & Puzzle Study
              _buildFeatureCard(
                context,
                title: 'Engine Practice & Study',
                subtitle: 'Play against offline engine difficulty levels and study grandmaster opening lines.',
                icon: Icons.psychology_outlined,
                gradientColors: [const Color(0xFF7C3AED), const Color(0xFF6D28D9)],
                accentColor: AppTheme.accentPurple,
                badgeText: 'OFFLINE STUDY',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AnalysisScreen()),
                  );
                },
              ),
              const SizedBox(height: 24),

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
                    Icon(Icons.info_outline, color: AppTheme.textMuted, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Designed for offline study, bot practice, and post-game review. Comply with fair play rules on online platforms.',
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
          padding: const EdgeInsets.all(20),
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
                    child: Icon(icon, color: Colors.white, size: 26),
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
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
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
