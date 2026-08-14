import 'package:flutter/material.dart';
import '../models/engine_evaluation.dart';

class EvaluationBarWidget extends StatelessWidget {
  final EngineEvaluation evaluation;
  final bool isFlipped;
  final double height;

  const EvaluationBarWidget({
    super.key,
    required this.evaluation,
    this.isFlipped = false,
    this.height = 330.0,
  });

  @override
  Widget build(BuildContext context) {
    // Probability: 1.0 is full white win, 0.0 is full black win
    final whiteProb = evaluation.winProbability.clamp(0.05, 0.95);
    final whiteHeightFactor = isFlipped ? (1.0 - whiteProb) : whiteProb;

    return Container(
      width: 24,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Black bar background
          Container(
            color: const Color(0xFF1E293B),
          ),

          // Animated White advantage portion
          Align(
            alignment: isFlipped ? Alignment.topCenter : Alignment.bottomCenter,
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              heightFactor: whiteHeightFactor,
              widthFactor: 1.0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // Score text pill
          Align(
            alignment: isFlipped
                ? (whiteHeightFactor > 0.5 ? Alignment.topCenter : Alignment.bottomCenter)
                : (whiteHeightFactor > 0.5 ? Alignment.bottomCenter : Alignment.topCenter),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  evaluation.displayScore,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: whiteHeightFactor > 0.5 ? Colors.black87 : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
