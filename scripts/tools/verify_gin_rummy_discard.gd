extends SceneTree

const CardTools := preload("res://scripts/core/card_tools.gd")
const GinRummyModel := preload("res://scripts/games/gin_rummy/gin_rummy_model.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if not _verify_useless_discard_is_not_returned():
		quit(1)
		return
	if not _verify_taken_discard_is_not_returned():
		quit(1)
		return
	if not _verify_player_draw_tracking_and_ace_low_runs():
		quit(1)
		return
	if not _verify_four_of_kind_can_split_for_run():
		quit(1)
		return
	if not _verify_gin_bonus_scoring():
		quit(1)
		return
	if not _verify_knock_layoff_undercut_scoring():
		quit(1)
		return
	if not _verify_player_knock_discards_and_finishes():
		quit(1)
		return
	print("Gin Rummy discard verification passed.")
	quit()

func _verify_useless_discard_is_not_returned() -> bool:
	var model := GinRummyModel.new()
	model.deck = [_card("Q", "S")]
	model.discard = [_card("K", "H")]
	model.bot = [
		_card("2", "H"), _card("3", "H"), _card("4", "H"),
		_card("6", "C"), _card("7", "C"), _card("8", "C"),
		_card("2", "S"), _card("3", "D"), _card("4", "C"), _card("5", "S"),
	]
	model.bot_turn()
	if model.last_bot_action.find("stock pile") < 0:
		push_error("Bot took a discard that did not improve its hand: %s" % model.last_bot_action)
		return false
	if CardTools.card_text(model.discard[-1]) == "KH":
		push_error("Useless player discard stayed as the top pickup after bot turn")
		return false
	return true

func _verify_taken_discard_is_not_returned() -> bool:
	var model := GinRummyModel.new()
	model.deck = [_card("K", "S")]
	model.discard = [_card("4", "S")]
	model.bot = [
		_card("4", "H"), _card("4", "D"), _card("J", "C"),
		_card("7", "C"), _card("8", "C"), _card("9", "C"),
		_card("2", "H"), _card("3", "D"), _card("9", "D"), _card("K", "C"),
	]
	model.bot_turn()
	if model.last_bot_action.find("discard pile") < 0:
		push_error("Bot did not take a useful discard in the controlled hand: %s" % model.last_bot_action)
		return false
	if CardTools.card_text(model.discard[-1]) == "4S":
		push_error("Bot returned the same discard it drew")
		return false
	return true

func _card(rank: String, suit: String) -> Dictionary:
	return {"rank": rank, "suit": suit}

func _verify_player_draw_tracking_and_ace_low_runs() -> bool:
	var model := GinRummyModel.new()
	model.deck = [_card("9", "S")]
	model.discard = [_card("4", "D")]
	model.player = []
	model.phase = "draw"
	model.draw_stock()
	if model.last_drawn_card != _card("9", "S") or model.last_draw_source != "stock":
		push_error("Stock draw was not tracked as the new card")
		return false
	model.player_discard(model.last_drawn_card)
	if model.last_drawn_card.size() != 0:
		push_error("Drawn card highlight state was not cleared after discard")
		return false

	var ace_low_run := [_card("A", "H"), _card("2", "H"), _card("3", "H")]
	var queen_king_ace := [_card("Q", "H"), _card("K", "H"), _card("A", "H")]
	if GinRummyModel.candidate_melds(ace_low_run).size() <= 0:
		push_error("A-2-3 should count as a Gin Rummy run")
		return false
	if GinRummyModel.candidate_melds(queen_king_ace).size() > 0:
		push_error("Q-K-A should not count as a Gin Rummy run")
		return false
	return true

func _verify_four_of_kind_can_split_for_run() -> bool:
	var hand := [
		_card("7", "S"), _card("7", "H"), _card("7", "D"), _card("7", "C"),
		_card("6", "H"), _card("8", "H"),
	]
	var groups := GinRummyModel.best_meld_groups(hand)
	if groups.size() != 2:
		push_error("Expected two meld groups from split set/run hand; got %d" % groups.size())
		return false
	var has_three_card_set := false
	var has_run := false
	for group in groups:
		var cards := []
		for index in group:
			cards.append(hand[index])
		if cards.size() == 3 and _same_rank(cards):
			has_three_card_set = true
		if _is_heart_run(cards):
			has_run = true
	if not has_three_card_set or not has_run:
		push_error("Expected a three-card set plus 6H-7H-8H run, not only a four-card set")
		return false
	if GinRummyModel.deadwood(hand) != 0:
		push_error("Split set/run hand should have zero deadwood")
		return false
	return true

func _verify_gin_bonus_scoring() -> bool:
	var model := GinRummyModel.new()
	model.player = [
		_card("2", "H"), _card("3", "H"), _card("4", "H"),
		_card("6", "C"), _card("7", "C"), _card("8", "C"),
		_card("9", "S"), _card("9", "H"), _card("9", "D"), _card("9", "C"),
	]
	model.bot = [_card("K", "S"), _card("Q", "D"), _card("J", "C"), _card("5", "H"), _card("2", "D")]
	model.finish_hand("You go gin.", "player")
	if model.player_score != 62:
		push_error("Gin should score defender deadwood plus 25; got %d" % model.player_score)
		return false
	if model.computer_score != 0 or model.hands_played != 1:
		push_error("Gin scoring updated the wrong counters")
		return false
	return true

func _verify_knock_layoff_undercut_scoring() -> bool:
	var model := GinRummyModel.new()
	model.player = [
		_card("4", "H"), _card("5", "H"), _card("6", "H"),
		_card("2", "C"), _card("3", "C"), _card("4", "C"),
		_card("9", "S"), _card("9", "H"), _card("9", "D"),
		_card("8", "S"),
	]
	model.bot = [
		_card("K", "S"), _card("K", "H"), _card("K", "D"),
		_card("7", "H"), _card("2", "D"),
	]
	model.finish_hand("You knock.", "player")
	if model.player_score != 0:
		push_error("Player should not score when undercut")
		return false
	if model.computer_score != 31:
		push_error("Undercut should score 8-2+25 = 31; got %d" % model.computer_score)
		return false
	if model.last_score_detail.find("7H") < 0:
		push_error("Scoring detail should show defender layoff card: %s" % model.last_score_detail)
		return false
	return true

func _verify_player_knock_discards_and_finishes() -> bool:
	var model := GinRummyModel.new()
	model.phase = "discard"
	model.discard = []
	model.player = [
		_card("2", "H"), _card("3", "H"), _card("4", "H"),
		_card("6", "C"), _card("7", "C"), _card("8", "C"),
		_card("9", "S"), _card("9", "H"), _card("9", "D"), _card("9", "C"),
		_card("K", "D"),
	]
	model.bot = [_card("Q", "S"), _card("J", "D"), _card("8", "C")]
	var result := model.knock()
	if model.phase != "done":
		push_error("Knock action should finish the hand; result was %s" % result)
		return false
	if model.discard.is_empty() or CardTools.card_text(model.discard[-1]) != "KD":
		push_error("Knock action should discard the selected high deadwood card")
		return false
	if model.player_score != 53:
		push_error("Knock action should score gin after discarding to zero deadwood; got %d" % model.player_score)
		return false
	return true

func _same_rank(cards: Array) -> bool:
	var rank := str(cards[0].rank)
	for card in cards:
		if str(card.rank) != rank:
			return false
	return true

func _is_heart_run(cards: Array) -> bool:
	if cards.size() != 3:
		return false
	var names := []
	for card in cards:
		names.append(CardTools.card_text(card))
	names.sort()
	return names == ["6H", "7H", "8H"]
