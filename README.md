# ♟️ ChessMatch - Flutter Chess Engine & Overlay App

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-Floating%20Overlay-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

**ChessMatch** is a modern, high-performance Flutter Android Chess Engine & Live Analysis application equipped with real-time evaluation, dynamic best-move vector overlays, and a native **Android Floating Overlay Window** that can hover over third-party chess apps.

---

## 🌟 Key Features

### 1. 🎯 Interactive Chessboard & Visuals
- **Dynamic Best-Move Vector Arrows**: Real-time rendering of arrows indicating engine-recommended tactical moves.
- **Glowing Move Highlights**: Sleek visual feedback for legal moves, captures, checkmates, and checks.
- **Drag-and-Drop & Tap Controls**: Smooth gesture-driven piece movements with full validation.
- **Board Flipping**: One-tap orientation toggle between White and Black perspectives.

### 2. 📊 Real-Time Engine Evaluation
- **Live Evaluation Bar**: Dynamic continuous centipawn/mate score bar visualizing win probabilities.
- **Minimax & Positional Evaluation**: Built-in chess evaluation engine utilizing Piece-Square Tables (PST), king safety evaluation, material balance, and mobility analysis.
- **Engine Dashboard**: Multi-depth calculation tracker, Principal Variation (PV) line explorer, and engine controls.

### 3. 🪟 Android Native Floating Overlay
- **Draggable Floating Pill**: Native Android overlay widget (`SYSTEM_ALERT_WINDOW`) displaying instant evaluation and best-move recommendations on top of other chess apps.
- **MethodChannel Bridge**: Seamless two-way communication between Flutter and Android Native Services.

### 4. 📜 Notation & Move History
- **Standard Algebraic Notation (SAN)**: Real-time recording of game turns (`1. e4 e5 2. Nf3 Nc6`).
- **FEN Parser & State Machine**: Full support for FEN import/export, castling rights, en passant, and pawn promotions.

---

## 🏗️ Project Architecture

```
Chess/
├── android/
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── AndroidManifest.xml                  # System permissions (Alert window, Foreground)
│   │   │   └── kotlin/com/example/chess_engine_app/
│   │   │       ├── MainActivity.kt                  # MethodChannel bridge
│   │   │       └── FloatingOverlayService.kt        # Android WindowManager Floating Service
│   │   └── build.gradle
│   ├── build.gradle
│   └── settings.gradle
├── lib/
│   ├── models/
│   │   ├── chess_piece.dart                         # Piece types & color representations
│   │   ├── chess_game_state.dart                    # Rules, moves, FEN parser, checkmate logic
│   │   └── engine_evaluation.dart                   # Evaluation score & PV models
│   ├── services/
│   │   ├── stockfish_engine_service.dart            # Minimax alpha-beta & PST heuristics
│   │   └── overlay_service.dart                     # Flutter MethodChannel client
│   ├── theme/
│   │   └── app_theme.dart                           # Dark luxury UI styling & colors
│   ├── widgets/
│   │   ├── chess_board_widget.dart                  # Board rendering & arrow painter
│   │   ├── evaluation_bar_widget.dart               # Live score bar
│   │   ├── engine_analysis_panel.dart               # Depth, PV line, engine metrics
│   │   └── move_history_widget.dart                 # SAN move history display
│   ├── screens/
│   │   ├── home_screen.dart                         # Main navigation hub
│   │   ├── analysis_screen.dart                     # Full engine analysis board
│   │   ├── overlay_mode_screen.dart                 # Floating assistant controls
│   │   └── settings_screen.dart                     # App configuration & preferences
│   └── main.dart                                    # App entry point
├── test/
│   └── chess_logic_test.dart                        # Unit tests for game state & engine
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

3. **Run tests**:
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
