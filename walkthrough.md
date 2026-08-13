# Chess Engine & Overlay Flutter Android Application Walkthrough

We have built a **Flutter Android Application** for real-time chess engine evaluation, interactive analysis, and Android floating overlay assistance.

---

## What Was Built

### 1. Flutter UI & Analysis Architecture
- **Interactive Chessboard ([lib/widgets/chess_board_widget.dart](file:///e:/Chess/lib/widgets/chess_board_widget.dart))**:
  - Full drag-and-drop & tap piece movement.
  - Glowing legal move indicators and capture rings.
  - Glowing checkmate and check highlight.
  - **Dynamic Best-Move Vector Arrow** dynamically pointing to top engine moves.
  - Board flip toggle and rank/file coordinate labels.
- **Live Evaluation Bar ([lib/widgets/evaluation_bar_widget.dart](file:///e:/Chess/lib/widgets/evaluation_bar_widget.dart))**:
  - Continuous vertical visual bar displaying White vs Black win probability.
  - Real-time centipawn (`+1.4`, `-0.8`) and mate (`M2`) score indicators.
- **Engine Analysis Dashboard ([lib/widgets/engine_analysis_panel.dart](file:///e:/Chess/lib/widgets/engine_analysis_panel.dart))**:
  - Stockfish calculation depth tracker.
  - Real-time Principal Variation (PV) multi-move line preview.
  - Play/Pause engine toggles.
- **Move History ([lib/widgets/move_history_widget.dart](file:///e:/Chess/lib/widgets/move_history_widget.dart))**:
  - SAN algebraic notation (`1. e4 e5 2. Nf3 Nc6`) tracker.

---

### 2. Android Native Floating Overlay Service
- **Android Manifest Permissions ([android/app/src/main/AndroidManifest.xml](file:///e:/Chess/android/app/src/main/AndroidManifest.xml))**:
  - Configured `SYSTEM_ALERT_WINDOW`, `FOREGROUND_SERVICE`, `POST_NOTIFICATIONS`.
- **MethodChannel Bridge ([android/app/src/main/kotlin/com/example/chess_engine_app/MainActivity.kt](file:///e:/Chess/android/app/src/main/kotlin/com/example/chess_engine_app/MainActivity.kt))**:
  - Handles permission checks (`Settings.canDrawOverlays`) and launches the background service.
- **Floating Window Service ([android/app/src/main/kotlin/com/example/chess_engine_app/FloatingOverlayService.kt](file:///e:/Chess/android/app/src/main/kotlin/com/example/chess_engine_app/FloatingOverlayService.kt))**:
  - Draggable Android floating pill widget that floats over chess apps.
  - Displays instant evaluation score and best next move.

---

### 3. Core Chess Engine & Positional Evaluation
- **Game State Logic ([lib/models/chess_game_state.dart](file:///e:/Chess/lib/models/chess_game_state.dart))**:
  - FEN parser/generator, en-passant, castling rights, promotion, and checkmate detection.
- **Alpha-Beta Engine Service ([lib/services/stockfish_engine_service.dart](file:///e:/Chess/lib/services/stockfish_engine_service.dart))**:
  - Piece-square positional tables, mobility analysis, king safety, and minimax calculation.

---

## Project Structure Overview

```
e:\Chess\
├── android\
│   ├── app\
│   │   ├── src\main\
│   │   │   ├── AndroidManifest.xml
│   │   │   └── kotlin\com\example\chess_engine_app\
│   │   │       ├── MainActivity.kt
│   │   │       └── FloatingOverlayService.kt
│   │   └── build.gradle
│   ├── build.gradle
│   └── settings.gradle
├── lib\
│   ├── models\
│   │   ├── chess_piece.dart
│   │   ├── chess_game_state.dart
│   │   └── engine_evaluation.dart
│   ├── services\
│   │   ├── stockfish_engine_service.dart
│   │   └── overlay_service.dart
│   ├── theme\
│   │   └── app_theme.dart
│   ├── widgets\
│   │   ├── chess_board_widget.dart
│   │   ├── evaluation_bar_widget.dart
│   │   ├── engine_analysis_panel.dart
│   │   └── move_history_widget.dart
│   ├── screens\
│   │   ├── home_screen.dart
│   │   ├── analysis_screen.dart
│   │   ├── overlay_mode_screen.dart
│   │   └── settings_screen.dart
│   └── main.dart
├── test\
│   └── chess_logic_test.dart
├── pubspec.yaml
└── implementation_plan.md
```

---

## How to Run & Build the Application

When running in an environment with Flutter SDK installed:

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run unit tests
flutter test

# 3. Run the application on connected Android device or emulator
flutter run

# 4. Build release Android APK
flutter build apk --release
```
