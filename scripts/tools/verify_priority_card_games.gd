extends SceneTree

const PokerEvaluator := preload("res://scripts/games/poker/poker_evaluator.gd")
const TexasHoldemModel := preload("res://scripts/games/texas_holdem/texas_holdem_model.gd")
const KlondikeModel := preload("res://scripts/games/klondike/klondike_model.gd")
const BasicRummyModel := preload("res://scripts/games/basic_rummy/basic_rummy_model.gd")
const CanastaModel := preload("res://scripts/games/canasta/canasta_model.gd")
const PinochleModel := preload("res://scripts/games/pinochle/pinochle_model.gd")
const TrickTakingModel := preload("res://scripts/games/trick_taking/trick_taking_model.gd")
const RummyTools := preload("res://scripts/games/rummy/rummy_tools.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_verify_best_poker_hand()
	_verify_texas_holdem_flow()
	_verify_klondike_setup()
	_verify_basic_rummy_scoring()
	_verify_trick_taking_modes()
	_verify_pinochle_setup()
	_verify_canasta_melds()
	print("Priority card game verification passed.")
	quit()

func _verify_best_poker_hand() -> void:
	var cards := [_card("A", "S"), _card("K", "S"), _card("Q", "S"), _card("J", "S"), _card("10", "S"), _card("2", "D"), _card("3", "C")]
	var eval := PokerEvaluator.evaluate_best(cards)
	_assert(eval["name"] == "straight flush", "best seven-card evaluator should find a straight flush")

func _verify_texas_holdem_flow() -> void:
	var model := TexasHoldemModel.new()
	model.new_hand()
	_assert(model.player.size() == 2, "Texas Hold'em should deal two player hole cards")
	_assert(model.community.is_empty(), "Texas Hold'em should start preflop")
	model.check_call()
	_assert(model.stage == "flop", "Check/call should advance to flop")
	_assert(model.community.size() == 3, "Flop should have three community cards")
	model.check_call()
	model.check_call()
	model.check_call()
	_assert(model.done, "River check/call should finish showdown")
	_assert(model.hands_played == 1, "Showdown should increment hands played")

func _verify_klondike_setup() -> void:
	var model := KlondikeModel.new()
	model.new_game()
	_assert(model.tableau.size() == 7, "Klondike should create seven tableau columns")
	_assert(model.stock.size() == 24, "Klondike should leave 24 stock cards after deal")
	for col in range(7):
		_assert(model.tableau[col].size() == col + 1, "Klondike tableau column size should match deal pattern")
		_assert(bool(model.tableau[col][-1].get("face_up", false)), "Klondike tableau top card should be face up")

func _verify_basic_rummy_scoring() -> void:
	var model := BasicRummyModel.new()
	model.deck = []
	model.discard = []
	model.player = []
	model.bot = [_card("9", "S"), _card("4", "H")]
	model.selected = []
	model.player_melds = []
	model.bot_melds = []
	model.done = false
	model.player_score = 0
	model.computer_score = 0
	model.hands_played = 0
	model.finish_hand("You went out.")
	_assert(model.player_score == 13, "Basic Rummy winner should score opponent hand points")
	_assert(model.computer_score == 0, "Basic Rummy loser should not score")
	_assert(model.hands_played == 1, "Basic Rummy finished hand should increment hand count")
	_assert(RummyTools.is_valid_meld([_card("2", "C"), _card("3", "C"), _card("4", "C")]), "Basic Rummy should share rummy meld validation")

func _verify_trick_taking_modes() -> void:
	for mode in ["euchre", "spades", "bridge", "whist"]:
		var model := TrickTakingModel.new()
		model.new_round(mode)
		_assert(model.hands.size() == 4, "%s should deal four hands" % mode)
		_assert(model.hands[0].size() == model.hand_size, "%s player hand should match configured hand size" % mode)
		var legal := model.legal_cards(0)
		_assert(not legal.is_empty(), "%s should have legal player cards" % mode)
		var suggestion := model.suggest_player_card()
		_assert(suggestion.size() > 0, "%s should provide a suggested player card" % mode)

func _verify_pinochle_setup() -> void:
	var model := PinochleModel.new()
	model.new_round("pinochle")
	_assert(model.deck.size() == 48, "Pinochle should use a 48-card deck")
	_assert(model.hands[0].size() == 12, "Pinochle should deal twelve cards per player")
	_assert(model.trump_suit in ["S", "H", "D", "C"], "Pinochle should choose a trump suit")
	_assert(model.suggest_player_card().size() > 0, "Pinochle should provide a suggested player card")

func _verify_canasta_melds() -> void:
	var model := CanastaModel.new()
	model.new_hand()
	var meld := [_card("8", "S"), _card("8", "H"), _card("8", "D")]
	_assert(model.is_valid_meld(meld), "Canasta should allow same-rank melds")
	_assert(model.meld_points(meld) == 30, "Canasta three eights should score 30")
	var canasta := [_card("Q", "S"), _card("Q", "H"), _card("Q", "D"), _card("Q", "C"), _card("Q", "S"), _card("Q", "H"), _card("Q", "D")]
	_assert(model.meld_points(canasta) == 370, "Canasta seven-card meld should include bonus")

func _card(rank: String, suit: String) -> Dictionary:
	return {"rank": rank, "suit": suit}

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
