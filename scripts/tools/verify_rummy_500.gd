extends SceneTree

const RummyTools := preload("res://scripts/games/rummy/rummy_tools.gd")
const Rummy500Model := preload("res://scripts/games/rummy_500/rummy_500_model.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_verify_meld_rules()
	_verify_model_flow()
	_verify_lower_discard_pickup_requires_immediate_meld()
	_verify_invalid_lower_discard_pickup_is_blocked()
	_verify_lower_discard_pickup_can_be_satisfied_by_layoff()
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

func _verify_lower_discard_pickup_requires_immediate_meld() -> void:
	var model := Rummy500Model.new()
	model.deck = [_card("Q", "C")]
	model.discard = [_card("5", "S"), _card("K", "D"), _card("9", "H")]
	model.player = [_card("6", "S"), _card("7", "S"), _card("2", "C")]
	model.bot = [_card("A", "H"), _card("8", "D"), _card("K", "C")]
	model.selected = []
	model.player_melds = []
	model.bot_melds = []
	model.phase = "draw"
	model.done = false
	model.player_hand_points = 0
	model.computer_hand_points = 0

	_assert(model.can_take_discard_at(0), "5S should be takeable because it can immediately join 6S-7S")
	model.draw_discard_at(0)
	_assert(model.phase == "act", "lower discard pickup should enter action phase")
	_assert(model.discard.is_empty(), "lower discard pickup should take the selected card and every newer discard")
	_assert(model.player.size() == 6, "lower discard pickup should add all taken cards to hand")
	_assert(model.has_pickup_requirement(), "lower discard pickup should require using the selected card")
	_assert(model.required_pickup_card == _card("5", "S"), "selected discard should be the required card")
	_assert(model.last_drawn_cards.size() == 3, "all picked-up discard cards should be tracked as drawn")

	model.toggle_selected(_card("9", "H"))
	var blocked_discard := model.discard_selected()
	_assert(blocked_discard.find("Use 5S") >= 0, "discard should be blocked until the selected discard is used")
	_assert(model.discard.is_empty(), "blocked discard should not change discard pile")
	model.toggle_selected(_card("9", "H"))

	model.toggle_selected(_card("5", "S"))
	model.toggle_selected(_card("6", "S"))
	model.toggle_selected(_card("7", "S"))
	model.meld_selected()
	_assert(not model.has_pickup_requirement(), "melding the selected discard should clear the pickup requirement")
	_assert(model.player_melds.size() == 1, "forced pickup card should be melded")
	_assert(model.player_hand_points == 18, "5S-6S-7S should score 18")

	model.toggle_selected(_card("K", "D"))
	var discard_result := model.discard_selected()
	_assert(discard_result.find("Your turn") >= 0 or model.phase == "draw" or model.done, "discard should proceed after pickup requirement is satisfied")

func _verify_invalid_lower_discard_pickup_is_blocked() -> void:
	var model := Rummy500Model.new()
	model.deck = [_card("Q", "C")]
	model.discard = [_card("5", "S"), _card("K", "D")]
	model.player = [_card("9", "C"), _card("J", "H"), _card("2", "D")]
	model.bot = []
	model.selected = []
	model.player_melds = []
	model.bot_melds = []
	model.phase = "draw"
	model.done = false

	_assert(not model.can_take_discard_at(0), "lower discard without immediate use should be unavailable")
	model.draw_discard_at(0)
	_assert(model.phase == "draw", "invalid lower discard pickup should keep draw phase")
	_assert(model.discard.size() == 2, "invalid lower discard pickup should not remove cards")
	_assert(model.player.size() == 3, "invalid lower discard pickup should not add cards")
	_assert(model.last_message.find("cannot take 5S") >= 0, "invalid lower discard pickup should explain why")

func _verify_lower_discard_pickup_can_be_satisfied_by_layoff() -> void:
	var model := Rummy500Model.new()
	model.deck = [_card("Q", "C")]
	model.discard = [_card("7", "H"), _card("Q", "D")]
	model.player = [_card("2", "C"), _card("9", "S")]
	model.bot = []
	model.selected = []
	model.player_melds = [[_card("4", "H"), _card("5", "H"), _card("6", "H")]]
	model.bot_melds = []
	model.phase = "draw"
	model.done = false
	model.player_hand_points = 0

	_assert(model.can_take_discard_at(0), "lower discard should be available when it can lay off immediately")
	model.draw_discard_at(0)
	_assert(model.has_pickup_requirement(), "layoff pickup should still set the forced-use card")
	model.toggle_selected(_card("7", "H"))
	model.layoff_selected()
	_assert(not model.has_pickup_requirement(), "laying off the selected discard should clear the forced-use rule")
	_assert(model.player_hand_points == 7, "layoff should score the card value")
	_assert(model.player_melds[0].has(_card("7", "H")), "layoff card should be added to the table meld")

func _card(rank: String, suit: String) -> Dictionary:
	return {"rank": rank, "suit": suit}

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
