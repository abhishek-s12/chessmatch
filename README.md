# ♟️ ChessMatch v2.0 - Grandmaster AI Engine, Bot Matches, Game Review & Overlay

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-Floating%20Overlay%202.0-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

**ChessMatch v2.0** is an all-in-one, high-performance Flutter Android Chess Engine, AI Match, Post-Game Review, and Floating Overlay application equipped with real-time positional evaluation, adaptive AI bots (800 to 2600+ ELO), tactical puzzle drills, move classification reports (*Brilliant, Best, Inaccuracy, Blunder*), and a native Android floating overlay assistant.

---

## 🌟 What's New in Version 2.0

### 1. 🤖 Play vs Engine Bots (AI Matches)
- **6 Adaptive Difficulty Personalities**: *Novice Nina (800 ELO)*, *Casual Carl (1200 ELO)*, *Intermediate Iris (1500 ELO)*, *Advanced Alex (1800 ELO)*, *Master Marcus (2200 ELO)*, and *Grandmaster Stockfish (2600+ ELO)*.
- **Time Controls**: Untimed, Bullet (1 min), Blitz (3+2), and Rapid (10 min) with live clocks.
- **In-Game Assistance**: Takeback (Undo), Hint (Best move vector), and direct post-game transition to Game Review.

### 2. 📊 Post-Game Review & Move Accuracies
- **Automated Move Classification**:
  - 🌟 **Brilliant (!!)**: Tactical sacrifice winning advantage.
  - 🟢 **Best Move (!)**: Optimal engine choice.
  - 🔵 **Excellent / Good**: Solid positional continuations.
  - 🟡 **Inaccuracy (?!)**: Minor loss of advantage.
  - 🟠 **Mistake (?)**: Concedes significant advantage.
  - 🔴 **Blunder (??)**: Critical tactical loss.
  - 📖 **Book Move**: Standard opening book theory.
- **CAPS Move Accuracy**: 0% - 100% precision rating for White and Black.
- **Centipawn Eval Graph**: Visual timeline of win probability and advantage swings.
- **PGN Export**: Export games formatted with full headers and SAN move history.

### 3. 🧩 Tactical Puzzle Trainer
- **Curated Tactics Database**: Mate in 1, Mate in 2, Royal Forks, Absolute Pins, Skewers, and Deflections.
- **Interactive Solver**: Automatic opponent replies, streak counter, and dynamic tactical rating progression.

### 4. ⚡ Engine 2.0 Core & Opening Book
- **Transposition Tables (TT)**: Fast position caching to eliminate redundant search branches.
- **Quiescence Search**: Solves the horizon effect by resolving capture sequences.
- **Opening Book**: Instant theoretical lines for Sicilian, Ruy Lopez, Queen's Gambit, French, Caro-Kann, King's Indian, and more.

### 5. 🪟 Floating Overlay 2.0
- **Compact & Click-to-Expand**: Tap to reveal calculation depth and quick metrics.
- **Draggable Window**: Persistent floating pill (`SYSTEM_ALERT_WINDOW`) over third-party chess apps for offline study.

### 6. 🎨 Customization, Audio & Haptic Feedback
- **4 Luxury Board Themes**: *Cyberpunk Neon*, *Emerald Tournament*, *Classic Walnut*, and *Midnight Obsidian*.
- **Haptics & Audio**: Tactile vibrations and sounds for piece moves, captures, checks, and game endings.

---

## 🏗️ Project Architecture

```
Chess/
├── android/
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── AndroidManifest.xml                  # Alert window & Foreground service permissions
│   │   │   └── kotlin/com/example/chess_engine_app/
│   │   │       ├── MainActivity.kt                  # MethodChannel bridge
│   │   │       └── FloatingOverlayService.kt        # Android Floating Overlay 2.0 Service
│   │   └── build.gradle
│   ├── build.gradle
│   └── settings.gradle
├── lib/
│   ├── models/
│   │   ├── chess_piece.dart                         # Piece representations & values
│   │   ├── chess_game_state.dart                    # Game state machine, rules, FEN, PGN, undo
│   │   ├── engine_evaluation.dart                   # Evaluation metrics & PV lines
│   │   └── puzzle_model.dart                        # Tactical puzzle data schema
│   ├── services/
│   │   ├── stockfish_engine_service.dart            # Minimax alpha-beta, TT, Quiescence, Bot ELOs
│   │   ├── opening_book_service.dart                # ECO opening book database
│   │   ├── game_review_service.dart                 # Move classification & accuracy calculation
│   │   ├── puzzle_service.dart                      # Puzzle repository & user rating tracker
│   │   ├── sound_service.dart                       # Haptic and audio feedback service
│   │   └── overlay_service.dart                     # Flutter to Android MethodChannel client
│   ├── theme/
│   │   └── app_theme.dart                           # Multi-theme system (Cyberpunk, Emerald, Wood, Midnight)
│   ├── widgets/
│   │   ├── chess_board_widget.dart                  # Themeable board with best-move vector painter
│   │   ├── evaluation_bar_widget.dart               # Vertical continuous centipawn/mate bar
│   │   ├── engine_analysis_panel.dart               # Live depth, nodes, and PV line tracker
│   │   └── move_history_widget.dart                 # SAN move history display
│   ├── screens/
│   │   ├── home_screen.dart                         # 5-card luxury navigation hub
│   │   ├── bot_match_screen.dart                    # Interactive AI game mode with chess clocks
│   │   ├── analysis_screen.dart                     # Live Stockfish engine analysis & FEN tools
│   │   ├── game_review_screen.dart                  # Move-by-move accuracy report & eval graph
│   │   ├── puzzle_screen.dart                       # Tactical puzzle drills & streak tracker
│   │   ├── overlay_mode_screen.dart                 # Floating assistant permission & launcher
│   │   └── settings_screen.dart                     # Board themes, audio, haptics & engine settings
│   └── main.dart                                    # App entry point
├── test/
│   ├── chess_logic_test.dart                        # Core chess rule & checkmate unit tests
│   ├── opening_book_test.dart                       # Opening tree & ECO line lookup tests
│   ├── engine_v2_test.dart                          # Engine 2.0, bot moves, and undo tests
│   ├── game_review_test.dart                        # Accuracy score & classification tests
│   └── puzzle_logic_test.dart                       # Puzzle solver & streak progression tests
├── pubspec.yaml
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.0.0`)
- [Android Studio](https://developer.android.com/studio) / Android SDK (API Level 21+)
- Git

### Installation & Run

1. **Clone the repository**:
   ```bash
   git clone https://github.com/abhishek-s12/chessmatch.git
   cd chessmatch
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run unit test suite**:
   ```bash
   flutter test
   ```

4. **Launch on connected device / emulator**:
   ```bash
   flutter run
   ```

5. **Build Release APK**:
   ```bash
   flutter build apk --release
   ```

---

## 📱 Android Permissions Note
To use the **Floating Overlay Feature**, the application requires the `Display over other apps` (`SYSTEM_ALERT_WINDOW`) permission on Android. The app automatically prompts for this permission when enabling overlay mode.

---

## 📄 License
This project is open source and available under the [MIT License](LICENSE).
