extends SceneTree

const RummyTools := preload("res://scripts/games/rummy/rummy_tools.gd")
const Rummy500Model := preload("res://scripts/games/rummy_500/rummy_500_model.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_verify_meld_rules()
	_verify_model_flow()
	print("Rummy 500 verification passed.")
	quit()

func _verify_meld_rules() -> void:
	_assert(RummyTools.is_valid_meld([_card("7", "S"), _card("7", "H"), _card("7", "D")]), "three-card set should be valid")
	_assert(RummyTools.is_valid_meld([_card("6", "H"), _card("7", "H"), _card("8", "H")]), "three-card run should be valid")
	_assert(not RummyTools.is_valid_meld([_card("Q", "S"), _card("K", "S"), _card("A", "S")]), "Q-K-A should not be a low-ace run")

	var split_hand := [
		_card("7", "S"), _card("7", "H"), _card("7", "D"), _card("7", "C"),
		_card("5", "S"), _card("6", "S"), _card("8", "S")
	]
	var groups := RummyTools.best_meld_groups(split_hand)
	_assert(groups.size() == 2, "four-of-kind plus run hand should split into two melds")
	_assert(RummyTools.deadwood_score(split_hand) == 0, "split meld hand should have zero deadwood")

func _verify_model_flow() -> void:
	var model := Rummy500Model.new()
	model.deck = [_card("9", "C")]
	model.discard = [_card("3", "S")]
	model.player = [_card("3", "H"), _card("3", "D"), _card("4", "C")]
	model.bot = [_card("A", "H"), _card("8", "D"), _card("K", "C")]
	model.selected = []
	model.player_melds = []
	model.bot_melds = []
	model.phase = "draw"
	model.done = false
	model.player_score = 0
	model.computer_score = 0
	model.hands_played = 0
	model.player_hand_points = 0
	model.computer_hand_points = 0

	model.draw_discard()
	_assert(model.phase == "act", "drawing discard should enter action phase")
	_assert(model.last_drawn_card == _card("3", "S"), "drawn discard should be tracked")

	model.toggle_selected(_card("3", "S"))
	model.toggle_selected(_card("3", "H"))
	model.toggle_selected(_card("3", "D"))
	model.meld_selected()
	_assert(model.player_melds.size() == 1, "selected set should be melded")
	_assert(model.player_hand_points == 9, "melded threes should score nine hand points")

	model.toggle_selected(_card("4", "C"))
	model.discard_selected()
	_assert(model.done, "discarding final card should finish the hand")
	_assert(model.player_score == 9, "player should score melded points when going out")
	_assert(model.hands_played == 1, "finished hand should increment hand count")

func _card(rank: String, suit: String) -> Dictionary:
	return {"rank": rank, "suit": suit}

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
