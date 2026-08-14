# Architecture & Engineering Specifications

## Overview
BlurChess is structured in a reactive, decoupled architecture separating game logic, rendering, engine computation, and native OS services.

```
┌─────────────────────────────────────────────────────────────┐
│                       Flutter UI Layer                      │
│   (Game Review, Live Analysis, Bot Arena, Tactical Puzzles) │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Provider State Binding)
┌──────────────────────────────▼──────────────────────────────┐
│                    ChessGameState (Model)                   │
│   (FIDE Rules, Move Generation, Legality Check, FEN/PGN)    │
└──────────────┬──────────────────────────────┬───────────────┘
               │                              │
┌──────────────▼─────────────┐ ┌──────────────▼───────────────┐
│  Stockfish Engine Service  │ │   Native Floating Overlay    │
│  (compute() Worker Isolate)│ │   (MediaProjection Vision)   │
│  - Alpha-Beta Minimax      │ │   - 200ms Highlight Scanner  │
│  - Quiescent Search        │ │   - Coach Danny Pill HUD     │
│  - Transposition Tables    │ │   - Auto Board Alignment     │
│  - Polyglot Opening Book   │ │   - 1-Tap SYNC & NEXT        │
└────────────────────────────┘ └──────────────────────────────┘
```

---

## 1. Multi-Threaded Isolate Engine Architecture
- **Problem**: Complex minimax tree evaluations with deep branching factors block the Flutter UI event loop.
- **Solution**: Evaluator is dispatched via Dart's `compute(_isolateSearchWorker, args)` isolate.
- **Data Serialization**: Board states are passed across threads using compact FEN strings, returning a serialized `EngineEvaluation` record.

---

## 2. Real-Time Screen Differencing & Highlight Tracker
- **Mechanism**: Captures live device display frames via Android `MediaProjection` & `ImageReader` in RGBA_8888.
- **Algorithm**:
  1. Frames are sampled on a dedicated background `HandlerThread`.
  2. 64-square color variance is calculated against baseline standard square palettes.
  3. Highlighted move pairs (`from` and `to` squares in yellow/cyan `#F5F682`) are translated to logical BoardPositions.
  4. Best responses and tactical sacrifice classifications (`!!`, `!`, `★`) are computed deterministically.

---

## 3. Diamond Move Classification System
Every move played is evaluated against the position before and after the move:
$$\Delta \text{Eval} = \text{Eval}_{\text{before}} - \text{Eval}_{\text{after}}$$

- **Brilliant (`!!`)**: Top engine move that sacrifices material ($V_{\text{moved}} > V_{\text{captured}}$) resulting in a winning tactical position ($\text{Eval} > +1.5$).
- **Great Find (`!`)**: The only move preserving a winning advantage ($\Delta \text{Eval} < -0.4$).
- **Best (`★`)**: Engine's #1 move.
- **Excellent (`✓`)**: Minor deviation ($\Delta \text{Eval} \le 0.25$).
- **Inaccuracy (`?!`)**: $\Delta \text{Eval} \le 0.90$.
- **Mistake (`?`)**: $\Delta \text{Eval} \le 2.20$.
- **Missed Win (`❌`)**: Player went from winning ($> +3.0$) to equal/losing ($< +0.5$).
- **Blunder (`??`)**: Severe error ($\Delta \text{Eval} > 2.20$).
