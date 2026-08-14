# Changelog

All notable changes to the **BlurChess** platform are documented in this file.

## [2.1.0] - 2026-08-15
### Added
- **Multi-Threaded Isolate Engine**: Dispatched Stockfish minimax search via `compute()` background isolate (0.0ms main thread blocking).
- **Real Drag-and-Drop Piece Mechanics**: `Draggable` & `DragTarget` integration with floating shadow elevation and square snapping.
- **Move Slide Animation**: Smooth 150ms ease-out cubic transitions for piece movements.
- **Chess.com Flat Chrome**: Edge-to-edge square-cornered chessboard styling.
- **Chess.com Diamond Game Review**: Coach Danny avatar, CAPS accuracy percentage gauges, and Key Moments stepper.
- **Master Live Analysis Board**: Multi-PV 2-Line Stockfish evaluation with integrated vertical evaluation bar and on-board best-move arrows.
- **Rated Tactical Puzzles**: Themed motifs with "Coach Tactical Hint" dialogue and streak multipliers.
- **Opera Game (1858) 1-Tap Review**: Instant loader for Paul Morphy's Immortal Game to review brilliancies (`!!`).
- **Coach Floating Screen Overlay**: Android MediaProjection live screen companion with 200ms radar polling and expandable tactical card.

### Fixed
- Fixed main UI thread freezing during bot calculations.
- Fixed piece extraction bug in Game Review sacrifice detection.
- Fixed unbounded height layout crash on `EvaluationBarWidget`.
- Fixed 27px toolbar right overflow on standard mobile screens.
