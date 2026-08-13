# Flutter Android Chess Engine & Overlay App Implementation Plan

A feature-rich **Flutter Android Application** providing real-time Stockfish engine evaluation, floating overlay controls on Android, interactive chessboard GUI, FEN/PGN analysis, and screen board recognition.

> [!IMPORTANT]
> **Fair Play & Ethical Use Disclaimer**: Using real-time move suggestions during live rated matches on online platforms (e.g., Chess.com, Lichess) strictly violates their Terms of Service and Fair Play rules. This Flutter app is intended for **offline play**, **post-game analysis**, **training against engines**, and **educational position study**.

---

## User Review Required

> [!NOTE]
> The app will be built using **Flutter (Dart)** for cross-platform Android UI and **Android Native Foreground Services (Kotlin)** for screen overlay bubble controls and engine process communication.

- **Engine Core**: Stockfish Chess Engine running as a native Android process or Dart isolates via FFI/Plugins.
- **Android Floating Overlay**: Uses `SYSTEM_ALERT_WINDOW` and foreground service to show a floating evaluation pill and best move hint on screen.
- **State Management**: Clean architecture using Provider/Riverpod or StateNotifier for reactive board updates.

---

## Open Questions

- Do you want the floating overlay widget to be a small collapsible bubble (bubble icon expand/collapse)?
- Should we add custom theme options for the chessboard (e.g., Wood, Cyber Dark, Emerald, Classic Canvas)?

---

## Proposed Changes

### Flutter Android Project Structure (`e:\Chess`)

#### [NEW] [pubspec.yaml](file:///e:/Chess/pubspec.yaml)
- Project dependencies: `chess` (rules & move generation), `flutter_svg`, `provider`, `shared_preferences`, `google_fonts`.

#### [NEW] [android/app/src/main/AndroidManifest.xml](file:///e:/Chess/android/app/src/main/AndroidManifest.xml)
- Android permissions for `SYSTEM_ALERT_WINDOW` (Floating Overlay), `FOREGROUND_SERVICE`, and `POST_NOTIFICATIONS`.

#### [NEW] [android/app/src/main/kotlin/.../MainActivity.kt](file:///e:/Chess/android/app/src/main/kotlin/com/example/chess_engine_app/MainActivity.kt)
- Method channels for starting/stopping the floating overlay service and native Stockfish bridge.

#### [NEW] [lib/main.dart](file:///e:/Chess/lib/main.dart)
- App entry point, MaterialApp setup with Dark Cyber/Glassmorphism design system.

#### [NEW] [lib/models/chess_engine.dart](file:///e:/Chess/lib/models/chess_engine.dart)
- UCI communication handler for Stockfish (eval, depth, best move parser, PV lines).

#### [NEW] [lib/screens/analysis_screen.dart](file:///e:/Chess/lib/screens/analysis_screen.dart)
- Main analysis screen featuring 2D Board, Live Eval Bar, Best Move Arrow indicators, FEN input/output, and Engine Controls.

#### [NEW] [lib/screens/overlay_config_screen.dart](file:///e:/Chess/lib/screens/overlay_config_screen.dart)
- Floating Overlay permission manager and floating window position controller.

#### [NEW] [lib/widgets/chess_board_widget.dart](file:///e:/Chess/lib/widgets/chess_board_widget.dart)
- Interactive, draggable custom 2D chessboard widget with square highlight overlays and move target markers.

---

## Verification Plan

### Automated Tests
- `flutter test`: Run unit tests for FEN parsing, UCI Stockfish output parsing, and legal move validation.

### Manual Verification
- Test interactive board drag-and-drop on Android emulator / physical device.
- Verify Floating Overlay permission flow (`SYSTEM_ALERT_WINDOW`) and floating bubble rendering.
- Verify Stockfish engine evaluation bar responsiveness and best-move calculations.
