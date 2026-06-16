extends SceneTree

const CardTools := preload("res://scripts/core/card_tools.gd")
const GinRummyModel := preload("res://scripts/games/gin_rummy/gin_rummy_model.gd")
const RummyTools := preload("res://scripts/games/rummy/rummy_tools.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_verify_gin_split_avoids_double_use()
	_verify_rummy_split_avoids_double_use()
	_verify_gin_prefers_two_melds_over_longer_overlap()
	_verify_rummy_prefers_two_melds_over_longer_overlap()
	_verify_long_run_is_kept_when_it_is_best()
	print("Meld optimization verification passed.")
	quit()

func _verify_gin_split_avoids_double_use() -> void:
	var hand := [
		_card("7", "S"), _card("7", "H"), _card("7", "D"), _card("7", "C"),
		_card("6", "H"), _card("8", "H")
	]
	var groups := _gin_groups_to_cards(hand, GinRummyModel.best_meld_groups(hand))
	_assert_no_duplicate_cards(groups, "Gin split set/run")
	_assert(groups.size() == 2, "Gin should split four sevens into one set plus one run")
	_assert(_has_group(groups, ["6H", "7H", "8H"]), "Gin should include the 6H-7H-8H run")
	_assert(GinRummyModel.deadwood(hand) == 0, "Gin split set/run hand should have zero deadwood")

func _verify_rummy_split_avoids_double_use() -> void:
	var hand := [
		_card("7", "S"), _card("7", "H"), _card("7", "D"), _card("7", "C"),
		_card("6", "H"), _card("8", "H")
	]
	var groups := RummyTools.best_meld_groups(hand)
	_assert_no_duplicate_cards(groups, "Rummy split set/run")
	_assert(groups.size() == 2, "Rummy should split four sevens into one set plus one run")
	_assert(_has_group(groups, ["6H", "7H", "8H"]), "Rummy should include the 6H-7H-8H run")
	_assert(RummyTools.deadwood_score(hand) == 0, "Rummy split set/run hand should have zero deadwood")

func _verify_gin_prefers_two_melds_over_longer_overlap() -> void:
	var hand := [
		_card("4", "H"), _card("5", "H"), _card("6", "H"), _card("7", "H"),
		_card("7", "S"), _card("7", "D"), _card("9", "C")
	]
	var groups := _gin_groups_to_cards(hand, GinRummyModel.best_meld_groups(hand))
	_assert_no_duplicate_cards(groups, "Gin overlap tradeoff")
	_assert(_has_group(groups, ["4H", "5H", "6H"]), "Gin should keep the shorter 4H-5H-6H run")
	_assert(_has_group(groups, ["7H", "7S", "7D"]), "Gin should use 7H in the set when that reduces deadwood more")
	_assert(not _has_group(groups, ["4H", "5H", "6H", "7H"]), "Gin should not choose the longer overlapping run when the split is better")
	_assert(GinRummyModel.deadwood(hand) == 9, "Gin overlap tradeoff should leave only 9C deadwood")

func _verify_rummy_prefers_two_melds_over_longer_overlap() -> void:
	var hand := [
		_card("4", "H"), _card("5", "H"), _card("6", "H"), _card("7", "H"),
		_card("7", "S"), _card("7", "D"), _card("9", "C")
	]
	var groups := RummyTools.best_meld_groups(hand)
	_assert_no_duplicate_cards(groups, "Rummy overlap tradeoff")
	_assert(_has_group(groups, ["4H", "5H", "6H"]), "Rummy should keep the shorter 4H-5H-6H run")
	_assert(_has_group(groups, ["7H", "7S", "7D"]), "Rummy should use 7H in the set when that reduces deadwood more")
	_assert(not _has_group(groups, ["4H", "5H", "6H", "7H"]), "Rummy should not choose the longer overlapping run when the split is better")
	_assert(RummyTools.deadwood_score(hand) == 9, "Rummy overlap tradeoff should leave only 9C deadwood")

func _verify_long_run_is_kept_when_it_is_best() -> void:
	var hand := [
		_card("2", "H"), _card("3", "H"), _card("4", "H"), _card("5", "H"), _card("6", "H"),
		_card("K", "C")
	]
	var gin_groups := _gin_groups_to_cards(hand, GinRummyModel.best_meld_groups(hand))
	_assert_no_duplicate_cards(gin_groups, "Gin long run")
	_assert(_has_group(gin_groups, ["2H", "3H", "4H", "5H", "6H"]), "Gin should keep the full five-card run when no split is better")
	_assert(GinRummyModel.deadwood(hand) == 10, "Gin long run hand should leave only KC deadwood")

	var rummy_groups := RummyTools.best_meld_groups(hand)
	_assert_no_duplicate_cards(rummy_groups, "Rummy long run")
	_assert(_has_group(rummy_groups, ["2H", "3H", "4H", "5H", "6H"]), "Rummy should keep the full five-card run when no split is better")
	_assert(RummyTools.deadwood_score(hand) == 10, "Rummy long run hand should leave only KC deadwood")

func _gin_groups_to_cards(hand: Array, groups: Array) -> Array:
	var card_groups := []
	for group in groups:
		var cards := []
		for index in group:
			cards.append(hand[index])
		card_groups.append(cards)
	return card_groups

func _assert_no_duplicate_cards(groups: Array, context: String) -> void:
	var seen := []
	for group in groups:
		for card in group:
			var name := CardTools.card_text(card)
			_assert(not seen.has(name), "%s reused %s across multiple melds" % [context, name])
			seen.append(name)

func _has_group(groups: Array, expected_names: Array) -> bool:
	var expected := expected_names.duplicate()
	expected.sort()
	for group in groups:
		var names := []
		for card in group:
			names.append(CardTools.card_text(card))
		names.sort()
		if names == expected:
			return true
	return false

func _card(rank: String, suit: String) -> Dictionary:
	return {"rank": rank, "suit": suit}

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
