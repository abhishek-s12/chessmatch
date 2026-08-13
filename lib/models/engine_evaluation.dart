import 'dart:math' as math;

class EngineEvaluation {
  final double scoreCp; // In pawns, e.g. +1.50
  final int? mateInMoves; // positive for White mate, negative for Black mate
  final String bestMove;
  final String? ponderMove;
  final int depth;
  final int nodes;
  final List<String> pvLine;
  final bool isThinking;

  const EngineEvaluation({
    this.scoreCp = 0.0,
    this.mateInMoves,
    required this.bestMove,
    this.ponderMove,
    this.depth = 0,
    this.nodes = 0,
    this.pvLine = const [],
    this.isThinking = false,
  });

  /// Formatted score string (e.g. "+1.4", "-0.8", "M3", "-M1", "0.0")
  String get displayScore {
    if (mateInMoves != null) {
      return mateInMoves! > 0 ? 'M${mateInMoves!}' : '-M${mateInMoves!.abs()}';
    }
    if (scoreCp == 0.0) return '0.0';
    final sign = scoreCp > 0 ? '+' : '';
    return '$sign${scoreCp.toStringAsFixed(1)}';
  }

  /// Percentage for evaluation bar (0.0 = total Black win, 0.5 = equal, 1.0 = total White win)
  double get winProbability {
    if (mateInMoves != null) {
      return mateInMoves! > 0 ? 0.98 : 0.02;
    }
    // Sigmoid scaling: 1 / (1 + 10^(-score / 4))
    final val = 1.0 / (1.0 + math.pow(10, -scoreCp / 4.0));
    return val.clamp(0.03, 0.97);
  }

  factory EngineEvaluation.initial() {
    return const EngineEvaluation(
      scoreCp: 0.0,
      bestMove: '--',
      depth: 0,
    );
  }
}
