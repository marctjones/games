# Classic Games Coach

Godot 4 prototype for learning classic multiplayer card and board games as one human player against computer opponents.

## Current playable modules

- Hearts: one human player against three computer opponents, automatic pass direction, trick scoring, and match score tracking.
- Blackjack: one human player against a rule-controlled dealer, with optional computer seats, split/double actions, and table score tracking.
- Cribbage: 2-4 player round-flow trainer with dealer rotation, crib ownership, discard selection, cut / his-heels handling, pegging simulation, hand and crib scoring, and race-to-121 tracking.
- Gin Rummy: one human player against a basic deadwood-reduction bot, with knock/gin flow, defender layoffs, gin and undercut bonuses, and 100-point match score tracking.
- Rummy 500: one human player against a basic computer opponent, with stock draw, visible discard-spread pickup, forced use of lower discard pickups, melds, layoffs, discard-to-end-turn flow, and hand scoring toward 500.
- Klondike Solitaire: one-player tableau/foundation trainer with stock/waste draw, legal tableau moves, foundation moves, and move hints.
- Five-Card Draw Poker: one human player against one to five basic draw/discard bots with hand evaluation.
- Texas Hold'em: simplified cash-game trainer with one human player, one to five computer seats, community-card stages, fold/check-call decisions, dollar bankrolls, and seven-card showdown evaluation.
- Basic Rummy: one human player against a basic computer opponent, sharing the rummy meld/layoff workflow with simpler go-out scoring.
- Euchre: four-player partnership trick-taking trainer with a 24-card deck, random trump, bowers, follow-suit play, hidden/revealed opponent hands, and maker-team scoring.
- Spades: four-player partnership trick-taking trainer with spades as trump, visible South bidding after the other three seats estimate theirs, bags, follow-suit play, hidden/revealed opponent hands, and team scoring.
- Bridge Trainer: four-player partnership trick-taking trainer with simplified high-card-point contract suggestions, a visible You/North contract choice when that side is favored, suit following, and hand-reading practice.
- Pinochle: four-player partnership trick-taking trainer with a 48-card double deck, random trump, point-card trick scoring, simplified meld/bid scoring, hidden/revealed opponent hands, and coach card suggestions.
- Whist: four-player partnership trick-taking trainer with full-deck follow-suit play, hidden/revealed opponent hands, and team trick scoring.
- Canasta: one human player against a basic computer opponent with two-deck draw/discard flow, same-rank melds, seven-card canasta bonuses, automatic hand scoring, and revealable opponent hand.
- Tic-tac-toe: one human player against a simple tactical AI.
- Checkers / Draughts: one human player against a simple move-ranking AI.
- Skat, Piquet, and Ombre / Quadrille: first-pass historic trick-taking trainer modules with legal-card play, follow-suit enforcement, basic computer opponents, and trick scoring. Full bidding/contract/payment systems are reserved for deeper passes.
- Chess: first-pass movement trainer with standard piece movement patterns and a basic computer reply. Check, checkmate, castling, en passant, and promotion details are reserved for the deeper chess pass.
- Nine Men's Morris: first-pass board trainer for moving toward three-in-a-row patterns.
- Reversi: playable disc-flipping trainer with legal move detection.
- Backgammon and Ludo / Pachisi-style: simplified race-game trainers focused on movement tempo. Full dice/bar/bearing-off/safe-square rules are reserved for deeper passes.
- Go 9x9 and Go 19x19: placement trainers with basic capture by liberties. Ko, suicide, and territory scoring are reserved for deeper passes.
- Fox and Geese: movement trainer with one fox against basic geese.
- Halma: corner-race trainer with step and jump movement.

Playable modules show valid player counts, computer-opponent counts, and automatic session scores. Blackjack, Cribbage, Five-Card Draw, and Texas Hold'em expose valid table-size controls. The home game-selection tiles, game logos, cards, and board controls resize from the current window size. Opponent hands are hidden during live play by default, with reveal selectors for one opponent, all opponents, or no opponents. Revealed hands include compact strategy annotations such as poker hand type, blackjack action, gin/rummy deadwood, cribbage raw value, and hearts danger cards. Public actions, completed tricks, showdowns, table melds, and recent board-game moves remain visible.

Each playable game uses a right-side Learning Coach with separate high-contrast sections for advice / next move, score, and rules / strategy, so current guidance stays visible without mixing every kind of text into one small status strip. Current hints use the shared `StrategyText` format: concrete action, reason, watch-out, drill, and post-hand review notes. Blackjack suggests hit/stand/double/split from the hand and dealer up-card, draw poker and cribbage suggest discards, rummy/canasta games identify meld or discard choices, Texas Hold'em explains preflop and board-stage reads, Klondike suggests visible legal moves, trick-taking games suggest legal cards, Hearts suggests a penalty-avoidance card, and board games name a simple tactical move.

## Opponent difficulty and fair play

The sidebar difficulty selector applies to the current game and the next game opened. Difficulty levels are Beginner, Casual, Standard, Advanced, and Expert. Lower levels choose weaker legal moves or discard plans; higher levels use the strongest available non-cheating heuristic for that game.

Computer opponents must not cheat. In card games they may use their own private hand, public table cards, public discards/melds/tricks, score, and rules context. They must not inspect the human player's hidden hand unless the user explicitly reveals it for display, and they must not inspect unknown stock/deck cards. In board games all board state is public, so stronger opponents can use legal move search over the visible position.

## Queued modules

No catalog entries are currently placeholders. The former queued entries now route to first-pass trainer modules. The next roadmap layer is to deepen individual rule systems rather than merely making the entries clickable.

## Remaining roadmap

1. Continue making priority card games rules-complete: trick-taking bidding/contracts, poker betting, blackjack table-rule options, deeper cribbage pegging / multiplayer detail, Rummy 500 variants, and remaining edge cases.
2. Replace trainer-grade board games with full rules engines: chess check/checkmate/castling/en passant/promotion, Go ko/suicide/territory scoring, backgammon dice/bar/bearing-off/doubling, Nine Men's Morris mill captures/flying, and full Ludo/Pachisi race rules.
3. Improve AI quality without hidden information: deeper heuristics first, then search/simulation where appropriate.
4. Build the learning system: mistake review, hand/trick replay, drills, spaced repetition, progress tracking, and richer explanations.
5. Add persistence for player profile, lesson history, match scores, bankrolls, and long-running sessions.
6. Polish UX per game: drag/drop cards, clearer turn prompts, animations, undo where valid, keyboard shortcuts, and accessibility sizing.
7. Finish release engineering: explicit project license, CI validation, macOS export, then Windows/Linux exports before mobile.

## Run

Open this folder in Godot 4 and run the project. The main scene is `res://main.tscn`.

Card faces and card backs use Kenney's Playing Cards Pack under `assets/external/` when available. The pack is CC0 licensed; see `assets/external/License.txt`. Generated project-owned card/checker assets remain available as fallbacks and for checker pieces. Checker pieces use explicit generated filenames such as `red_man.png` and `black_king.png` to avoid case-collision issues on macOS filesystems.

To regenerate gameplay image assets:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://scripts/tools/generate_assets.gd
```

Validation helpers:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://scripts/tools/verify_card_assets.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://scripts/tools/verify_cribbage.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://scripts/tools/verify_playable_views.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://scripts/tools/verify_gin_rummy_discard.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://scripts/tools/verify_rummy_500.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://scripts/tools/verify_priority_card_games.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://scripts/tools/verify_strategy_guidance.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://scripts/tools/verify_queued_trainers.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://scripts/tools/verify_opponent_policy.gd
```

## Architecture

- `scripts/main.gd`: app router and shared header/rules-coach host.
- `scripts/app/app_shell.gd`: reusable sidebar and content-shell construction.
- `scripts/app/dashboard_view.gd`: home dashboard for playable modules.
- `scripts/app/game_catalog.gd`: ordered game roadmap and playable/queued metadata.
- `scripts/core/card_tools.gd`: shared card/deck/rank/sorting/text helpers used by card games.
- `scripts/core/opponent_policy.gd`: shared difficulty levels, fair-play policy text, and legal-choice selection helpers.
- `scripts/games/*/*_model.gd`: game state, legal moves, scoring, and basic computer play.
- `scripts/games/*/*_view.gd`: game-specific Godot controls and interaction wiring.
- `scripts/games/poker/poker_evaluator.gd`: reusable poker hand evaluator for Five-Card Draw and Texas Hold'em.
- `scripts/games/rummy/rummy_tools.gd`: reusable rummy-family meld, layoff, deadwood, and discard helpers.
- `scripts/games/trick_taking/trick_taking_model.gd` and `scripts/games/trick_taking/trick_taking_view.gd`: reusable partnership trick-taking prototype engine/view used by Euchre, Spades, Bridge Trainer, and Whist, including shared contract-phase UI hooks.
- `scripts/games/queued_trainer/queued_trainer_model.gd` and `scripts/games/queued_trainer/queued_trainer_view.gd`: reusable first-pass trainer modules for the formerly queued historic card and board games.
- `scripts/games/tic_tac_toe/tic_tac_toe_model.gd`: Tic-tac-toe board state, win detection, and basic AI.
- `scripts/core/strategy_text.gd`: shared structured coaching and post-hand review text.
- `scripts/ui/ui_factory.gd`: shared panel, menu button, action button, Learning Coach sections, responsive game-selection tile/card/board sizing, recommended/new-card styling, and Kenney/generated card texture loading.
- `scripts/tools/generate_assets.gd`: generates PNG card/checker assets under `assets/generated/`.
- `scripts/tools/verify_card_assets.gd`: verifies the Kenney card texture path.
- `scripts/tools/verify_cribbage.gd`: verifies cribbage hand scoring details, crib ownership, heels scoring, and dealer rotation.
- `scripts/tools/verify_playable_views.gd`: smoke-tests playable view construction, coach text, and resize refresh paths.
- `scripts/tools/verify_rummy_500.gd`: verifies shared rummy meld handling and a Rummy 500 hand flow.
- `scripts/tools/verify_priority_card_games.gd`: verifies Klondike setup, Texas Hold'em stage flow, seven-card poker evaluation, Basic Rummy scoring, Canasta meld scoring, Pinochle setup, and trick-taking mode setup.
- `scripts/tools/verify_strategy_guidance.gd`: verifies structured coaching across the strategy helpers.
- `scripts/tools/verify_queued_trainers.gd`: verifies that formerly queued trainer modules are playable and expose legal moves or legal cards.
- `scripts/tools/verify_opponent_policy.gd`: verifies the difficulty policy, legal move selection, and no hidden-stock peeking in rummy bots.

Recent roadmap work moved Gin Rummy deadwood/meld optimization onto the shared `RummyTools` path, added real knock/gin/layoff/undercut scoring, added Rummy 500 discard-spread pickup with forced lower-card use, upgraded Cribbage from discard-only drill to round-flow scoring with dealer rotation and crib ownership, added post-hand review text, added the shared opponent difficulty/fair-play policy, removed rummy hidden-stock peeking, and deepened first-rule layers for Hearts passing, Blackjack double/split actions, visible Spades bidding, visible Bridge contract selection when You/North are favored, Euchre bowers/maker scoring, Pinochle meld/bid scoring, and Canasta wild/red-three/frozen-discard rules. The next architecture step is to replace the remaining first-pass trainer approximations with fuller rules engines one game at a time.
