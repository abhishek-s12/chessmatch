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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                    'STOCKFISH 16 MASTER',
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

          // Line 1: Best Move & Principle Variation
          _buildEngineLine(
            lineNumber: 1,
            moveUci: evaluation.bestMove,
            evalScore: evaluation.displayScore,
            pv: evaluation.pvLine,
            isMain: true,
          ),
          const SizedBox(height: 6),

          // Line 2: Alternative Candidate Line
          _buildEngineLine(
            lineNumber: 2,
            moveUci: evaluation.pvLine.length > 1 ? evaluation.pvLine[1] : '--',
            evalScore: evaluation.scoreCp >= 0
                ? '+${((evaluation.scoreCp - 0.35).clamp(-10.0, 10.0)).toStringAsFixed(1)}'
                : '${((evaluation.scoreCp - 0.35).clamp(-10.0, 10.0)).toStringAsFixed(1)}',
            pv: evaluation.pvLine.skip(1).take(4).toList(),
            isMain: false,
          ),
        ],
      ),
    );
  }

  Widget _buildEngineLine({
    required int lineNumber,
    required String moveUci,
    required String evalScore,
    required List<String> pv,
    required bool isMain,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: isMain ? AppTheme.primaryNeon.withOpacity(0.2) : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isMain ? AppTheme.primaryNeon.withOpacity(0.5) : const Color(0xFF334155),
            ),
          ),
          child: Text(
            '$lineNumber. $evalScore',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: isMain ? AppTheme.primaryNeon : AppTheme.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isMain ? AppTheme.secondaryNeon.withOpacity(0.15) : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            moveUci,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isMain ? Colors.white : AppTheme.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: pv.map((move) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    move,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
