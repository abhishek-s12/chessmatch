import '../models/puzzle_model.dart';

class PuzzleService {
  static final PuzzleService _instance = PuzzleService._internal();
  factory PuzzleService() => _instance;
  PuzzleService._internal();

  int userRating = 1200;
  int currentStreak = 0;
  int highestStreak = 0;
  final Set<String> solvedPuzzleIds = {};

  static const List<ChessPuzzle> puzzles = [
    // 1. Mate in 1 - Back Rank
    ChessPuzzle(
      id: 'puzzle_1',
      title: 'Back Rank Execution',
      fen: '6k1/5ppp/8/8/8/8/4R3/4K3 w - - 0 1',
      solutionMoves: ['e2e8'],
      rating: 800,
      theme: 'Back Rank Mate',
      description: 'The enemy king is trapped by its own pawns. Deliver checkmate in 1 move!',
    ),

    // 2. Scholar's Queen Mate
    ChessPuzzle(
      id: 'puzzle_2',
      title: "Queen's Infiltration",
      fen: 'r1bqkb1r/pppp1ppp/2n5/4p3/2B1n3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 0 1',
      solutionMoves: ['f3f7'],
      rating: 900,
      theme: 'Checkmate Pattern',
      description: 'Spot the vulnerable f7 square protected by the bishop on c4.',
    ),

    // 3. Royal Knight Fork
    ChessPuzzle(
      id: 'puzzle_3',
      title: 'Royal Knight Fork',
      fen: 'r1b1k2r/pp3ppp/2n5/3q4/4n3/2N5/PPP2PPP/R1BQK2R w KQkq - 0 1',
      solutionMoves: ['c3d5'],
      rating: 1100,
      theme: 'Fork',
      description: 'Capture the undefended queen with tempo.',
    ),

    // 4. Anastasia's Mate
    ChessPuzzle(
      id: 'puzzle_4',
      title: "Anastasia's Knight Net",
      fen: '5rk1/5ppp/8/3N4/8/8/5PPP/R5K1 w - - 0 1',
      solutionMoves: ['d5e7', 'g8h8', 'a1a8'],
      rating: 1300,
      theme: 'Mate in 2',
      description: 'Force the king into the corner with check, then slide the rook down.',
    ),

    // 5. Queen & Bishop Battery
    ChessPuzzle(
      id: 'puzzle_5',
      title: 'Diagonal Battery',
      fen: 'r1b2rk1/pp3ppp/8/8/1bB1Q3/8/P4PPP/R1B2RK1 w - - 0 1',
      solutionMoves: ['c4f7', 'f8f7', 'e4b4'],
      rating: 1400,
      theme: 'Discovery & Win Material',
      description: 'Uncover an attack on the bishop while giving check on f7.',
    ),

    // 6. Smothered Mate Setup
    ChessPuzzle(
      id: 'puzzle_6',
      title: 'Smothered Geometry',
      fen: '6k1/5ppp/8/6N1/8/8/5PPP/4R1K1 w - - 0 1',
      solutionMoves: ['e1e8'],
      rating: 850,
      theme: 'Back Rank Mate',
      description: 'Deliver checkmate on the back rank.',
    ),

    // 7. Pin Exploitation
    ChessPuzzle(
      id: 'puzzle_7',
      title: 'Absolute Pin',
      fen: 'r1b1k2r/pppp1ppp/8/4q3/1bP5/2N1P3/PP3PPP/R1BQKB1R w KQkq - 0 1',
      solutionMoves: ['c1d2'],
      rating: 1050,
      theme: 'Pin & Defense',
      description: 'Neutralize the pin on the knight gracefully.',
    ),

    // 8. Queen Sacrifice to Mate
    ChessPuzzle(
      id: 'puzzle_8',
      title: 'Opera House Finish',
      fen: '4kb1r/p2n1ppp/4p3/3p4/3P4/4P3/P2q1PPP/1R4K1 w - - 0 1',
      solutionMoves: ['b1b8', 'd7b8'],
      rating: 1550,
      theme: 'Deflection',
      description: 'Deflect the defender with a back rank rook strike.',
    ),
  ];

  ChessPuzzle getPuzzleByIndex(int index) {
    return puzzles[index % puzzles.length];
  }

  void onPuzzleSuccess(ChessPuzzle puzzle) {
    solvedPuzzleIds.add(puzzle.id);
    currentStreak++;
    if (currentStreak > highestStreak) {
      highestStreak = currentStreak;
    }
    userRating += 15;
  }

  void onPuzzleFailure(ChessPuzzle puzzle) {
    currentStreak = 0;
    if (userRating > 600) {
      userRating -= 10;
    }
  }
}
