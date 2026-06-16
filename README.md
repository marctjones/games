# Classic Games Coach

Godot 4 prototype for learning classic multiplayer card and board games as one human player against computer opponents.

## Current playable modules

- Hearts: one human player against three basic bot opponents. Passing is omitted in this first rules prototype.
- Blackjack: one human player against a basic dealer AI that stands on 17, with optional computer seats at the table.
- Cribbage: 2-4 player discard-selection trainer with basic computer opponents. This first module covers discard choice and hand scoring; pegging is not implemented yet.
- Gin Rummy: one human player against a basic deadwood-reduction bot.
- Rummy 500: one human player against a basic computer opponent, with stock/discard draw, melds, layoffs, discard-to-end-turn flow, and hand scoring toward 500.
- Klondike Solitaire: one-player tableau/foundation trainer with stock/waste draw, legal tableau moves, foundation moves, and move hints.
- Five-Card Draw Poker: one human player against one to five basic draw/discard bots with hand evaluation.
- Texas Hold'em: simplified cash-game trainer with one human player, one to five computer seats, community-card stages, fold/check-call decisions, dollar bankrolls, and seven-card showdown evaluation.
- Basic Rummy: one human player against a basic computer opponent, sharing the rummy meld/layoff workflow with simpler go-out scoring.
- Euchre: four-player partnership trick-taking trainer with a 24-card deck, random trump, follow-suit play, hidden/revealed opponent hands, and team trick scoring. Bidding, bowers, and going alone are reserved for a deeper rules pass.
- Spades: four-player partnership trick-taking trainer with spades as trump, follow-suit play, hidden/revealed opponent hands, and team trick scoring. Bidding and bags are reserved for the next scoring pass.
- Bridge Trainer: four-player partnership trick-taking trainer for suit-following and hand-reading practice. Contract bidding is reserved for the next bridge pass.
- Pinochle: four-player partnership trick-taking trainer with a 48-card double deck, random trump, point-card trick scoring, hidden/revealed opponent hands, and coach card suggestions. Bidding and meld scoring are reserved for the next deeper rules pass.
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

## Queued modules

No catalog entries are currently placeholders. The former queued entries now route to first-pass trainer modules. The next roadmap layer is to deepen individual rule systems rather than merely making the entries clickable.

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
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://scripts/tools/verify_playable_views.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://scripts/tools/verify_gin_rummy_discard.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://scripts/tools/verify_rummy_500.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://scripts/tools/verify_priority_card_games.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://scripts/tools/verify_strategy_guidance.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://scripts/tools/verify_queued_trainers.gd
```

## Architecture

- `scripts/main.gd`: app router and shared header/rules-coach host.
- `scripts/app/app_shell.gd`: reusable sidebar and content-shell construction.
- `scripts/app/dashboard_view.gd`: home dashboard for playable modules.
- `scripts/app/game_catalog.gd`: ordered game roadmap and playable/queued metadata.
- `scripts/core/card_tools.gd`: shared card/deck/rank/sorting/text helpers used by card games.
- `scripts/games/*/*_model.gd`: game state, legal moves, scoring, and basic computer play.
- `scripts/games/*/*_view.gd`: game-specific Godot controls and interaction wiring.
- `scripts/games/poker/poker_evaluator.gd`: reusable poker hand evaluator for Five-Card Draw and Texas Hold'em.
- `scripts/games/rummy/rummy_tools.gd`: reusable rummy-family meld, layoff, deadwood, and discard helpers.
- `scripts/games/trick_taking/trick_taking_model.gd` and `scripts/games/trick_taking/trick_taking_view.gd`: reusable partnership trick-taking prototype engine/view used by Euchre, Spades, Bridge Trainer, and Whist.
- `scripts/games/queued_trainer/queued_trainer_model.gd` and `scripts/games/queued_trainer/queued_trainer_view.gd`: reusable first-pass trainer modules for the formerly queued historic card and board games.
- `scripts/games/tic_tac_toe/tic_tac_toe_model.gd`: Tic-tac-toe board state, win detection, and basic AI.
- `scripts/core/strategy_text.gd`: shared structured coaching and post-hand review text.
- `scripts/ui/ui_factory.gd`: shared panel, menu button, action button, Learning Coach sections, responsive game-selection tile/card/board sizing, recommended/new-card styling, and Kenney/generated card texture loading.
- `scripts/tools/generate_assets.gd`: generates PNG card/checker assets under `assets/generated/`.
- `scripts/tools/verify_card_assets.gd`: verifies the Kenney card texture path.
- `scripts/tools/verify_playable_views.gd`: smoke-tests playable view construction, coach text, and resize refresh paths.
- `scripts/tools/verify_rummy_500.gd`: verifies shared rummy meld handling and a Rummy 500 hand flow.
- `scripts/tools/verify_priority_card_games.gd`: verifies Klondike setup, Texas Hold'em stage flow, seven-card poker evaluation, Basic Rummy scoring, Canasta meld scoring, Pinochle setup, and trick-taking mode setup.
- `scripts/tools/verify_strategy_guidance.gd`: verifies structured coaching across the strategy helpers.
- `scripts/tools/verify_queued_trainers.gd`: verifies that formerly queued trainer modules are playable and expose legal moves or legal cards.

Recent roadmap work moved Gin Rummy deadwood/meld optimization onto the shared `RummyTools` path, added post-hand review text, and deepened first-rule layers for Hearts passing, Cribbage pegging drills, Blackjack double/split actions, Spades bids/bags, Euchre bowers/maker scoring, Bridge auto-contracts, Pinochle meld/bid scoring, and Canasta wild/red-three/frozen-discard rules. The next architecture step is to replace the remaining first-pass trainer approximations with fuller rules engines one game at a time.
