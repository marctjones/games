extends SceneTree

const CribbageModel := preload("res://scripts/games/cribbage/cribbage_model.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_verify_hand_scoring_details()
	_verify_round_scoring_with_player_crib()
	_verify_round_rotation()
	print("Cribbage verification passed.")
	quit()

func _verify_hand_scoring_details() -> void:
	var hand := [_card("5", "H"), _card("5", "D"), _card("6", "H"), _card("7", "H")]
	var cut := _card("8", "H")
	_assert(CribbageModel.score_hand(hand, cut, false) == 12, "Expected 12 points from pair, fifteen, and double run")

	var nobs_hand := [_card("J", "H"), _card("2", "H"), _card("4", "H"), _card("6", "H")]
	_assert(CribbageModel.score_hand(nobs_hand, _card("9", "H"), false) == 10, "Expected flush, nobs, and fifteens")
	_assert(CribbageModel.score_hand(nobs_hand, _card("9", "S"), false) == 8, "Non-crib four-card flush should still count alongside fifteens")
	_assert(CribbageModel.score_hand(nobs_hand, _card("9", "S"), true) == 4, "Crib flush should require the cut suit, but other points still count")

func _verify_round_scoring_with_player_crib() -> void:
	var model := CribbageModel.new()
	model.player_count = 2
	model.dealer_index = 0
	model.deck = [_card("J", "C")]
	model.player = [_card("5", "H"), _card("6", "H"), _card("7", "H"), _card("8", "H"), _card("K", "S"), _card("Q", "D")]
	model.bots = [[_card("5", "C"), _card("5", "S"), _card("10", "S"), _card("10", "D"), _card("4", "C"), _card("9", "D")]]
	model.bot = model.bots[0]
	model.crib = []
	model.selected_discards = [_card("K", "S"), _card("Q", "D")]
	model.player_score_total = 0
	model.computer_score_total = 0
	model.hands_played = 0
	model.opponent_difficulty = "Beginner"
	var result := model.score_discards()
	_assert(model.round_complete, "Scoring discards should complete the round")
	_assert(model.current_player_hand_score == CribbageModel.score_hand(model.player, model.cut_card, false), "Round scoring should use the same kept-hand evaluator")
	_assert(model.current_crib_score > 0, "Crib should score for the dealer")
	_assert(model.player_score_total >= model.current_player_hand_score + model.current_player_pegging_score + model.current_crib_score + 2, "Player dealer should receive crib and heels points")
	_assert(result.find("Dealer: You.") >= 0, "Round summary should name the dealer")
	_assert(result.find("His heels") >= 0, "Cut jack should award heels points")

func _verify_round_rotation() -> void:
	var model := CribbageModel.new()
	model.player_count = 2
	model.dealer_index = 0
	model.new_hand()
	model.round_complete = true
	model.advance_round()
	_assert(model.dealer_index == 1, "Dealer should rotate after each round")
	_assert(model.crib_owner == "Computer 1", "Crib owner should follow dealer rotation")

func _card(rank: String, suit: String) -> Dictionary:
	return {"rank": rank, "suit": suit}

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
