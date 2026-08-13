import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MoveHistoryWidget extends StatelessWidget {
  final List<String> sanHistory;

  const MoveHistoryWidget({
    super.key,
    required this.sanHistory,
  });

  @override
  Widget build(BuildContext context) {
    if (sanHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        alignment: Alignment.center,
        child: const Text(
          'No moves made yet. Make a move or paste FEN.',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
      );
    }

    final movePairs = <Map<String, String>>[];
    for (int i = 0; i < sanHistory.length; i += 2) {
      final whiteMove = sanHistory[i];
      final blackMove = (i + 1 < sanHistory.length) ? sanHistory[i + 1] : '';
      movePairs.add({'white': whiteMove, 'black': blackMove});
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: SizedBox(
        height: 48,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: movePairs.length,
          itemBuilder: (context, index) {
            final moveNum = index + 1;
            final pair = movePairs[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '$moveNum. ',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      pair['white']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (pair['black']!.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        pair['black']!,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
