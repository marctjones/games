extends SceneTree

const BasicRummyModel := preload("res://scripts/games/basic_rummy/basic_rummy_model.gd")
const BlackjackModel := preload("res://scripts/games/blackjack/blackjack_model.gd")
const CanastaModel := preload("res://scripts/games/canasta/canasta_model.gd")
const CheckersModel := preload("res://scripts/games/checkers/checkers_model.gd")
const CribbageModel := preload("res://scripts/games/cribbage/cribbage_model.gd")
const FiveCardDrawModel := preload("res://scripts/games/five_card_draw/five_card_draw_model.gd")
const GinRummyModel := preload("res://scripts/games/gin_rummy/gin_rummy_model.gd")
const HeartsModel := preload("res://scripts/games/hearts/hearts_model.gd")
const KlondikeModel := preload("res://scripts/games/klondike/klondike_model.gd")
const PinochleModel := preload("res://scripts/games/pinochle/pinochle_model.gd")
const Rummy500Model := preload("res://scripts/games/rummy_500/rummy_500_model.gd")
const TexasHoldemModel := preload("res://scripts/games/texas_holdem/texas_holdem_model.gd")
const TicTacToeModel := preload("res://scripts/games/tic_tac_toe/tic_tac_toe_model.gd")
const TrickTakingModel := preload("res://scripts/games/trick_taking/trick_taking_model.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_verify_card_game_guidance()
	_verify_five_card_draw_plans()
	_verify_texas_holdem_draw_guidance()
	_verify_trick_taking_partner_guidance()
	_verify_hearts_void_guidance()
	_verify_klondike_reveal_hint()
	_verify_board_game_guidance()
	print("Strategy guidance verification passed.")
	quit()

func _verify_card_game_guidance() -> void:
	var blackjack := BlackjackModel.new()
	blackjack.player = [_card("10", "S"), _card("6", "H")]
	blackjack.dealer = [_card("10", "D"), _card("7", "C")]
	_assert_structured(blackjack.basic_strategy_hint(), "Blackjack guidance")

	var cribbage := CribbageModel.new()
	cribbage.player = [_card("5", "S"), _card("5", "H"), _card("6", "C"), _card("7", "C"), _card("K", "D"), _card("2", "S")]
	_assert_structured(cribbage.guidance_text(), "Cribbage guidance")

	var gin := GinRummyModel.new()
	gin.player = [_card("5", "H"), _card("6", "H"), _card("7", "H"), _card("9", "S")]
	gin.discard = [_card("8", "H")]
	gin.phase = "draw"
	_assert_structured(gin.guidance_text(), "Gin Rummy guidance")

	var rummy500 := Rummy500Model.new()
	rummy500.player = [_card("5", "H"), _card("6", "H"), _card("7", "H"), _card("9", "S")]
	rummy500.discard = [_card("8", "H")]
	rummy500.phase = "draw"
	_assert_structured(rummy500.guidance_text(), "Rummy 500 guidance")

	var basic_rummy := BasicRummyModel.new()
	basic_rummy.player = [_card("5", "H"), _card("6", "H"), _card("7", "H"), _card("9", "S")]
	basic_rummy.discard = [_card("8", "H")]
	basic_rummy.phase = "draw"
	_assert_structured(basic_rummy.guidance_text(), "Basic Rummy guidance")

	var canasta := CanastaModel.new()
	canasta.player = [_card("8", "S"), _card("8", "H"), _card("8", "D"), _card("Q", "C")]
	canasta.discard = [_card("8", "C")]
	canasta.phase = "draw"
	_assert_structured(canasta.guidance_text(), "Canasta guidance")

func _verify_five_card_draw_plans() -> void:
	var model := FiveCardDrawModel.new()
	var straight_draw := [_card("2", "H"), _card("3", "S"), _card("4", "D"), _card("5", "C"), _card("K", "S")]
	var plan := model.draw_plan_for(straight_draw)
	_assert(_cards_have(plan["keep"], ["2H", "3S", "4D", "5C"]), "Five Card Draw should keep four-card straight draws")
	_assert(_cards_have(plan["discards"], ["KS"]), "Five Card Draw should discard the outside high card on a straight draw")
	model.player = straight_draw
	_assert_structured(model.guidance_text(), "Five Card Draw guidance")

	var two_pair := [_card("Q", "H"), _card("Q", "S"), _card("4", "D"), _card("4", "C"), _card("9", "S")]
	plan = model.draw_plan_for(two_pair)
	_assert(plan["discards"].size() == 1, "Five Card Draw should draw one card with two pair")

func _verify_texas_holdem_draw_guidance() -> void:
	var model := TexasHoldemModel.new()
	model.player = [_card("A", "S"), _card("7", "S")]
	model.community = [_card("2", "S"), _card("9", "S"), _card("K", "D")]
	model.stage = "flop"
	model.done = false
	model.pot = 40
	var text := model.guidance_text()
	_assert_structured(text, "Texas Hold'em guidance")
	_assert(text.contains("flush"), "Texas Hold'em should identify a flush draw")

func _verify_trick_taking_partner_guidance() -> void:
	var model := TrickTakingModel.new()
	model.new_round("spades")
	_assert_structured(model.guidance_text(), "Spades bidding guidance")
	model.select_contract_option(0)
	model.confirm_contract_selection()
	model.hands[0] = [_card("2", "H"), _card("K", "H")]
	model.current_trick = [
		{"player": 2, "card": _card("Q", "H")},
		{"player": 3, "card": _card("5", "H")}
	]
	model.turn = 0
	var suggestion := model.suggest_player_card()
	_assert(suggestion == _card("2", "H"), "Trick-taking should avoid overtaking partner when possible")
	_assert_structured(model.guidance_text(), "Trick-taking guidance")

	var bridge := TrickTakingModel.new()
	bridge.new_round("bridge")
	if bridge.is_waiting_for_player_contract():
		_assert_structured(bridge.guidance_text(), "Bridge contract guidance")

	var pinochle := PinochleModel.new()
	pinochle.new_round("pinochle")
	pinochle.hands[0] = [_card("9", "H"), _card("A", "H")]
	pinochle.current_trick = [{"player": 1, "card": _card("10", "H")}]
	pinochle.turn = 0
	_assert_structured(pinochle.guidance_text(), "Pinochle guidance")

func _verify_hearts_void_guidance() -> void:
	var model := HeartsModel.new()
	model.hands = [[_card("Q", "S"), _card("2", "D")], [], [], []]
	model.current_trick = [{"player": 1, "card": _card("5", "H")}]
	model.turn = 0
	var text := model.player_guidance_text()
	_assert_structured(text, "Hearts guidance")
	_assert(text.contains("void") or text.contains("penalty"), "Hearts guidance should explain void penalty dumping")

func _verify_klondike_reveal_hint() -> void:
	var model := KlondikeModel.new()
	model.foundations = {"S": [], "H": [], "D": [], "C": []}
	model.stock = []
	model.waste = []
	model.tableau = [
		[_face_card("9", "S", false), _face_card("8", "H", true)],
		[_face_card("9", "C", true)],
		[], [], [], [], []
	]
	var text := model.hint_text()
	_assert_structured(text, "Klondike hint")
	_assert(text.contains("Revealing"), "Klondike should prioritize revealing hidden tableau cards")

func _verify_board_game_guidance() -> void:
	var tic := TicTacToeModel.new()
	tic.board = ["X", "", "", "", "O", "", "", "", ""]
	_assert_structured(tic.guidance_text(), "Tic-tac-toe guidance")

	var checkers := CheckersModel.new()
	checkers.new_game()
	_assert_structured(checkers.guidance_text(), "Checkers guidance")

func _card(rank: String, suit: String) -> Dictionary:
	return {"rank": rank, "suit": suit}

func _face_card(rank: String, suit: String, face_up: bool) -> Dictionary:
	return {"rank": rank, "suit": suit, "face_up": face_up}

func _cards_have(cards: Array, expected_names: Array) -> bool:
	var names := []
	for card in cards:
		names.append("%s%s" % [card.rank, card.suit])
	names.sort()
	var expected := expected_names.duplicate()
	expected.sort()
	return names == expected

func _assert_structured(text: String, context: String) -> void:
	_assert(text.contains("Do:"), "%s should include a concrete action" % context)
	_assert(text.contains("Why:") or text.contains("Watch:") or text.contains("Drill:"), "%s should include a strategic explanation" % context)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
