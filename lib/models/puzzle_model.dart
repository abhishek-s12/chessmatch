class ChessPuzzle {
  final String id;
  final String title;
  final String fen;
  final List<String> solutionMoves; // UCI format moves
  final int rating;
  final String theme;
  final String description;

  const ChessPuzzle({
    required this.id,
    required this.title,
    required this.fen,
    required this.solutionMoves,
    required this.rating,
    required this.theme,
    required this.description,
  });
}
