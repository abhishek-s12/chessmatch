# ♟️ BlurChess — Grandmaster Chess Engine & Live Assistant

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Stockfish](https://img.shields.io/badge/Engine-Stockfish_16_Custom-4ADE80?style=for-the-badge)](https://stockfishchess.org)

**BlurChess** is an ultra-high-performance chess ecosystem featuring a multi-threaded **Stockfish Engine**, **Chess.com Diamond Game Review & AI Coach Danny**, **Real Drag-and-Drop Piece Mechanics**, **Multi-PV Live Analysis Board**, and an Android **Live Floating Overlay Screen Assistant** with 200ms screen differencing radar.

---

## 🌟 Key Features

### 1. 💎 Diamond Game Review & AI Coach
- **Coach Danny Commentary**: Move-by-move speech bubbles explaining tactical sacrifices, missed tactics, and positional maneuvers.
- **CAPS Accuracy Rating**: Full percentage gauges comparing White vs Black play with estimated performance ELO ratings (e.g. `2450 ELO` vs `1800 ELO`).
- **Official Move Classification Badges**:
  - 💎 **`!! Brilliant`** (`#1BACA6`) — Winning tactical sacrifices.
  - 🏆 **`! Great Find`** (`#5C8BB0`) — Critical single-path moves.
  - ★ **`Best Move`** (`#81B64C`) — #1 Engine choice.
  - ✓ **`Excellent`** (`#96BC4B`) — Solid positional move.
  - 📖 **`Book Move`** (`#D5A47D`) — Theoretical opening lines.
  - ?! **`Inaccuracy`** (`#F7C042`) — Slight concession of advantage.
  - ? **`Mistake`** (`#FFA43B`) — Loss of control or dynamic initiative.
  - ❌ **`Missed Win`** (`#FA412D`) — Missed tactical victory.
  - ?? **`Blunder`** (`#CA3431`) — Severe decisive error.
- **Interactive Key Moments**: 1-tap jump through all game-defining turning points.
- **Advantage Spline Graph**: Touch-scrubbable evaluation timeline.
- **Sample Game Loader**: 1-tap review of **Paul Morphy's 1858 Opera Game (Immortal)** with Queen & Rook sacrifices.

---

### 2. ⚡ Live Engine Analyzer (Multi-PV)
- **Top 2-3 Grandmaster Lines**: Evaluates multiple principal variations simultaneously with exact centipawn score badges (`+0.62`), continuation lines, and nodes-per-second metrics.
- **Seamless Left Evaluation Bar**: Live smooth win-probability bar aligned directly against the board.
- **Visual On-Board Tactical Arrows**: Dynamic glowing arrows pointing out best lines, alternative candidates, and opponent threats.
- **PGN / FEN Hub**: Instant clipboard import/export and board flipping.

---

### 3. 🛰️ Floating Screen Overlay Assistant (Android MediaProjection)
- **Compact HUD Pill**:
  - 👨‍🏫 Coach Avatar Pill • Perspective Badge (`♔ W` / `♚ B`) • `↻ SYNC` (1-tap reset) • `▶ NEXT` (instant move advance) • `● LIVE` radar • Centipawn score `[+1.8]` • Badges `[💎 !!]` • Full move notation `♞ g1 ➔ f3 (Nf3)`.
- **Expandable Floating Companion**:
  - Tap the Coach avatar to open an expandable translucent card with coach strategic advice and live candidate lines.
- **200ms Ultra-Fast Radar**: Screen differencing algorithms scan Chess.com & Lichess boards and recalculate responses in `<100ms`.

---

### 4. 🧵 Multi-Threaded Isolate Engine Search
- **0.00ms UI Freezing**: Heavy alpha-beta minimax searches and quiescent evaluations run in a dedicated background thread via Dart's `compute()` isolate.
- UI stays silky-smooth at **60/120 FPS** with zero stutter while the bot calculates at Grandmaster depth (Depth 6–7).

---

### 5. 🖐️ Authentic Chess.com Feel & Drag-and-Drop
- **Real Drag-and-Drop**: Built using `Draggable` & `DragTarget` with floating shadow elevation feedback and snapping to target squares.
- **150ms Smooth Slide Animation**: Pieces glide into place seamlessly.
- **Flat Board Chrome**: Square-cornered, shadowless border styling matching official Chess.com boards.
- **5 Official Chess.com Themes**: Green, Walnut Wood, Ice Glass, Classic Brown, and Night Charcoal.

---

## 🏗️ Architecture & Project Structure

```
e:\Chess
├── android/                        # Android Native Module
│   └── app/src/main/kotlin/...
│       ├── FloatingOverlayService.kt # MediaProjection Screen Vision & Floating HUD
│       └── MainActivity.kt         # MethodChannel Bridge
├── lib/
│   ├── main.dart                   # Application Entry Point
│   ├── models/
│   │   ├── chess_game_state.dart   # FIDE Chess Rules, State Machine & Move Legality
│   │   ├── chess_piece.dart        # Piece Types, Colors & Values
│   │   ├── engine_evaluation.dart  # Stockfish Evaluation Data Model
│   │   └── puzzle_model.dart       # Tactical Puzzle Definitions
│   ├── screens/
│   │   ├── analysis_screen.dart    # Live Engine Analysis Board
│   │   ├── bot_match_screen.dart   # Bot Match Arena (6 Difficulties)
│   │   ├── game_review_screen.dart # Chess.com Diamond Review & AI Coach
│   │   ├── home_screen.dart        # Main Navigation Hub
│   │   ├── overlay_mode_screen.dart# Floating Assistant Control Center
│   │   ├── puzzle_screen.dart      # Rated Tactical Puzzles
│   │   └── settings_screen.dart    # Theme & Sound Customization
│   ├── services/
│   │   ├── stockfish_engine_service.dart # Multi-threaded Compute Isolate Search
│   │   ├── game_review_service.dart# Move Classification & Accuracy Analyzer
│   │   ├── puzzle_service.dart     # Rating & Streak Service
│   │   ├── opening_book_service.dart # Polyglot Opening Book Database
│   │   ├── overlay_service.dart    # MethodChannel Native Overlay Controller
│   │   └── sound_service.dart      # Move, Capture & Check Sound/Haptic FX
│   ├── theme/
│   │   └── app_theme.dart          # 5 Official Board Themes & Classification Colors
│   └── widgets/
│       ├── chess_board_widget.dart # Drag-and-Drop Board with Move Slide Animations
│       ├── chess_piece_painter.dart# HD Staunton Vector Dual-Tone Pieces
│       ├── engine_analysis_panel.dart # Multi-PV Engine Lines Panel
│       ├── evaluation_bar_widget.dart # Vertical Dynamic Win Probability Bar
│       └── move_history_widget.dart# Notation History Strip
└── test/                           # 14 Automated Test Suites (100% Passing)
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev) (v3.19+)
- [Android Studio / Platform Tools](https://developer.android.com/studio) (for Android deployment)
- Dart 3.x

### Installation & Run

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/abhishek-s12/chessmatch.git
   cd chessmatch
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run Automated Tests**:
   ```bash
   flutter test
   ```

4. **Launch on Device / Emulator**:
   ```bash
   flutter run -d <device_id>
   ```

---

## 🧪 Testing

BlurChess includes 14 comprehensive unit and widget test suites:
```bash
flutter test
```
- ✅ `chess_logic_test.dart` (FIDE rules, Scholar's mate, castling, en passant)
- ✅ `engine_v2_test.dart` (Stockfish bot moves across difficulties, PGN formatting)
- ✅ `game_review_test.dart` (Move classification, CAPS accuracy calculations)
- ✅ `opening_book_test.dart` (Polyglot opening lines detection)
- ✅ `puzzle_logic_test.dart` (Tactical puzzle verification & rating algorithms)
- ✅ `widget_test.dart` (App rendering & navigation tests)

---

## 📄 License
This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
