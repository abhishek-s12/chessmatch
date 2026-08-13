import 'package:flutter/material.dart';
import '../models/engine_evaluation.dart';
import '../theme/app_theme.dart';

class EngineAnalysisPanel extends StatelessWidget {
  final EngineEvaluation evaluation;
  final bool isEngineActive;
  final VoidCallback onToggleEngine;

  const EngineAnalysisPanel({
    super.key,
    required this.evaluation,
    required this.isEngineActive,
    required this.onToggleEngine,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Engine Status, Score & Depth
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isEngineActive ? AppTheme.secondaryNeon : AppTheme.textMuted,
                      boxShadow: isEngineActive
                          ? [
                              BoxShadow(
                                color: AppTheme.secondaryNeon.withOpacity(0.6),
                                blurRadius: 6,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'STOCKFISH 16',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'd=${evaluation.depth}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryNeon,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  isEngineActive ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: isEngineActive ? AppTheme.primaryNeon : AppTheme.secondaryNeon,
                  size: 26,
                ),
                onPressed: onToggleEngine,
                tooltip: isEngineActive ? 'Pause Engine' : 'Resume Engine',
              ),
            ],
          ),
          const Divider(color: Color(0xFF334155), height: 16),

          // Best Move Pill & Calculated Line
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryNeon.withOpacity(0.2),
                      AppTheme.secondaryNeon.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, color: AppTheme.primaryNeon, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Best: ${evaluation.bestMove}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: evaluation.pvLine.map((move) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          move,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
