class_name RummyTools
extends RefCounted

const CardTools := preload("res://scripts/core/card_tools.gd")
const StrategyText := preload("res://scripts/core/strategy_text.gd")

static func card_points(card: Dictionary) -> int:
	return CardTools.pip_value(card.rank)

static func hand_points(cards: Array) -> int:
	var total := 0
	for card in cards:
		total += card_points(card)
	return total

static func meld_points(cards: Array) -> int:
	return hand_points(cards)

static func is_valid_meld(cards: Array) -> bool:
	if cards.size() < 3:
		return false
	return is_set(cards) or is_run(cards)

static func is_set(cards: Array) -> bool:
	if cards.size() < 3:
		return false
	var rank := str(cards[0].rank)
	for card in cards:
		if str(card.rank) != rank:
			return false
	return true

static func is_run(cards: Array) -> bool:
	if cards.size() < 3:
		return false
	var suit := str(cards[0].suit)
	var values := []
	for card in cards:
		if str(card.suit) != suit:
			return false
		var value := CardTools.rank_low_value(card.rank)
		if values.has(value):
			return false
		values.append(value)
	values.sort()
	for i in range(1, values.size()):
		if int(values[i]) != int(values[i - 1]) + 1:
			return false
	return true

static func meld_kind(cards: Array) -> String:
	if is_set(cards):
		return "set"
	if is_run(cards):
		return "run"
	return "invalid"

static func can_layoff(card: Dictionary, meld: Array) -> bool:
	var test := meld.duplicate()
	test.append(card)
	return is_valid_meld(test)

static func deadwood_score(hand: Array) -> int:
	var used := best_meld_mask(hand)
	var total := 0
	for i in range(hand.size()):
		if not used.has(i):
			total += card_points(hand[i])
	return total

static func deadwood_cards(hand: Array) -> Array:
	var used := best_meld_mask(hand)
	var cards := []
	for i in range(hand.size()):
		if not used.has(i):
			cards.append(hand[i])
	return cards

static func best_deadwood_after_layoff(defender_hand: Array, target_melds: Array) -> Dictionary:
	var melds := candidate_melds(defender_hand)
	return _defense_layout_search(defender_hand, melds, target_melds, 0, [], [], 0)

static func best_meld_groups(hand: Array) -> Array:
	var melds := candidate_melds(hand)
	var result := search_meld_groups(hand, melds, 0, [], [], 0)
	var groups := []
	for group_indices in result["groups"]:
		var cards := []
		for index in group_indices:
			cards.append(hand[index])
		groups.append(cards)
	return groups

static func best_meld_index_groups(hand: Array) -> Array:
	var melds := candidate_melds(hand)
	var result := search_meld_groups(hand, melds, 0, [], [], 0)
	return result["groups"]

static func best_meld_mask(hand: Array) -> Array:
	var melds := candidate_melds(hand)
	var result := search_meld_groups(hand, melds, 0, [], [], 0)
	return result["mask"]

static func candidate_melds(hand: Array) -> Array:
	var melds := []
	for rank in CardTools.RANKS:
		var indices := []
		for i in range(hand.size()):
			if hand[i].rank == rank:
				indices.append(i)
		if indices.size() >= 3:
			for size in range(3, indices.size() + 1):
				_add_set_melds(melds, indices, size, 0, [])
	for suit in CardTools.SUITS:
		var suited := []
		for i in range(hand.size()):
			if hand[i].suit == suit:
				suited.append(i)
		suited.sort_custom(func(a, b): return CardTools.rank_low_value(hand[a].rank) < CardTools.rank_low_value(hand[b].rank))
		for start in range(suited.size()):
			var run := [suited[start]]
			var prev := CardTools.rank_low_value(hand[suited[start]].rank)
			for pos in range(start + 1, suited.size()):
				var value := CardTools.rank_low_value(hand[suited[pos]].rank)
				if value == prev + 1:
					run.append(suited[pos])
					prev = value
					if run.size() >= 3:
						melds.append(run.duplicate())
				elif value > prev + 1:
					break
	return melds

static func _add_set_melds(melds: Array, indices: Array, target_size: int, start: int, current: Array) -> void:
	if current.size() == target_size:
		melds.append(current.duplicate())
		return
	for i in range(start, indices.size()):
		current.append(indices[i])
		_add_set_melds(melds, indices, target_size, i + 1, current)
		current.pop_back()

static func search_meld_groups(hand: Array, melds: Array, index: int, current_mask: Array, current_groups: Array, current_value: int) -> Dictionary:
	if index >= melds.size():
		return {"value": current_value, "mask": current_mask.duplicate(), "groups": current_groups.duplicate(true)}
	var best: Dictionary = search_meld_groups(hand, melds, index + 1, current_mask, current_groups, current_value)
	var meld: Array = melds[index]
	for item in meld:
		if current_mask.has(item):
			return best
	for item in meld:
		current_mask.append(item)
	current_groups.append(meld.duplicate())
	var value := 0
	for item in meld:
		value += card_points(hand[item])
	var with_meld: Dictionary = search_meld_groups(hand, melds, index + 1, current_mask, current_groups, current_value + value)
	current_groups.pop_back()
	for item in meld:
		current_mask.erase(item)
	if int(with_meld["value"]) > int(best["value"]):
		return with_meld
	return best

static func _defense_layout_search(hand: Array, melds: Array, target_melds: Array, index: int, current_mask: Array, current_groups: Array, current_value: int) -> Dictionary:
	if index >= melds.size():
		var deadwood := []
		for i in range(hand.size()):
			if not current_mask.has(i):
				deadwood.append(hand[i])
		var layoff := _best_layoff_result(deadwood, target_melds)
		return {
			"deadwood": int(layoff["deadwood"]),
			"laid_off": layoff["laid_off"],
			"remaining": layoff["remaining"],
			"groups": current_groups.duplicate(true),
			"meld_value": current_value,
		}
	var best: Dictionary = _defense_layout_search(hand, melds, target_melds, index + 1, current_mask, current_groups, current_value)
	var meld: Array = melds[index]
	for item in meld:
		if current_mask.has(item):
			return best
	for item in meld:
		current_mask.append(item)
	current_groups.append(meld.duplicate())
	var value := 0
	for item in meld:
		value += card_points(hand[item])
	var with_meld: Dictionary = _defense_layout_search(hand, melds, target_melds, index + 1, current_mask, current_groups, current_value + value)
	current_groups.pop_back()
	for item in meld:
		current_mask.erase(item)
	return _better_defense(with_meld, best)

static func _better_defense(candidate: Dictionary, current: Dictionary) -> Dictionary:
	if int(candidate["deadwood"]) < int(current["deadwood"]):
		return candidate
	if int(candidate["deadwood"]) == int(current["deadwood"]) and int(candidate["meld_value"]) > int(current["meld_value"]):
		return candidate
	return current

static func _best_layoff_result(deadwood: Array, target_melds: Array) -> Dictionary:
	return _layoff_search(deadwood, _duplicate_meld_groups(target_melds), 0, [], [])

static func _layoff_search(deadwood: Array, meld_groups: Array, index: int, laid_off: Array, remaining: Array) -> Dictionary:
	if index >= deadwood.size():
		return {
			"deadwood": hand_points(remaining),
			"laid_off": laid_off.duplicate(),
			"remaining": remaining.duplicate(),
		}
	var card: Dictionary = deadwood[index]
	var keep_remaining := remaining.duplicate()
	keep_remaining.append(card)
	var best: Dictionary = _layoff_search(deadwood, meld_groups, index + 1, laid_off, keep_remaining)
	for meld_index in range(meld_groups.size()):
		if can_layoff(card, meld_groups[meld_index]):
			var next_melds := _duplicate_meld_groups(meld_groups)
			next_melds[meld_index].append(card)
			var next_laid_off := laid_off.duplicate()
			next_laid_off.append(card)
			var candidate: Dictionary = _layoff_search(deadwood, next_melds, index + 1, next_laid_off, remaining)
			best = _better_layoff(candidate, best)
	return best

static func _better_layoff(candidate: Dictionary, current: Dictionary) -> Dictionary:
	if int(candidate["deadwood"]) < int(current["deadwood"]):
		return candidate
	if int(candidate["deadwood"]) == int(current["deadwood"]) and hand_points(candidate["laid_off"]) > hand_points(current["laid_off"]):
		return candidate
	return current

static func _duplicate_meld_groups(groups: Array) -> Array:
	var duplicated := []
	for group in groups:
		duplicated.append(group.duplicate())
	return duplicated

static func choose_discard(hand: Array) -> Dictionary:
	var best_card: Dictionary = hand[0]
	var best_deadwood := -1
	for card in hand:
		var test := hand.duplicate()
		test.erase(card)
		var score := deadwood_score(test)
		if best_deadwood < 0 or score < best_deadwood or (score == best_deadwood and card_points(card) > card_points(best_card)):
			best_deadwood = score
			best_card = card
	return best_card

static func draw_decision_text(hand: Array, discard_card: Dictionary) -> String:
	var current_deadwood := deadwood_score(hand)
	var with_discard := hand.duplicate()
	with_discard.append(discard_card)
	var discard_deadwood := deadwood_score(with_discard)
	var delta_text := StrategyText.score_delta_text(current_deadwood, discard_deadwood)
	var top_text := CardTools.card_text(discard_card)
	if discard_deadwood < current_deadwood:
		return StrategyText.advice(
			"Take %s from the discard pile." % top_text,
			"Your best non-overlapping meld layout %s, from %d deadwood to %d." % [delta_text, current_deadwood, discard_deadwood],
			"After taking a visible card, try not to discard it back unless your plan changed."
		)
	var support := card_support_text(discard_card, hand)
	if _card_support_score(discard_card, hand) >= 2:
		return StrategyText.advice(
			"Usually draw stock; take %s only if you are committing to %s." % [top_text, support],
			"It does not reduce deadwood immediately, but it has visible meld support.",
			"Visible pickups reveal your plan to the opponent."
		)
	return StrategyText.advice(
		"Draw from stock.",
		"%s %s against your current best meld layout." % [top_text, delta_text],
		"Use the discard pile when the card completes or clearly extends a set/run."
	)

static func action_phase_text(hand: Array, selected: Array, player_melds: Array = [], bot_melds: Array = []) -> String:
	if is_valid_meld(selected):
		return StrategyText.advice(
			"Meld the selected %s." % meld_kind(selected),
			"It scores %d points now and removes those cards from hand risk." % meld_points(selected),
			"Check whether holding one card back creates a better non-overlapping layout before committing."
		)
	if selected.size() == 1:
		var card: Dictionary = selected[0]
		if _can_layoff_any(card, player_melds, bot_melds):
			return StrategyText.advice(
				"Lay off %s." % CardTools.card_text(card),
				"It scores immediately and lowers your end-of-hand penalty.",
				"Prefer layoff before discarding unless the card blocks an opponent's visible meld."
			)
		var test := hand.duplicate()
		test.erase(card)
		return StrategyText.advice(
			"Discard %s if you are ending the turn." % CardTools.card_text(card),
			"Discarding it leaves %d deadwood; %s." % [deadwood_score(test), card_support_text(card, hand)],
			"If it is newly drawn, compare whether it extends a future run before throwing it away."
		)
	if selected.is_empty() and not hand.is_empty():
		return discard_advice_text(hand)
	return StrategyText.advice(
		"Adjust the selection.",
		"Selected cards are not one legal meld yet. Sets share rank; runs are consecutive in one suit.",
		"Cards can only belong to one meld at a time, so split overlaps deliberately."
	)

static func discard_advice_text(hand: Array) -> String:
	var discard := choose_discard(hand)
	var test := hand.duplicate()
	test.erase(discard)
	return StrategyText.advice(
		"Discard %s if you are not melding or laying off." % CardTools.card_text(discard),
		"That leaves %d deadwood under the best non-overlapping meld layout." % deadwood_score(test),
		card_support_text(discard, hand)
	)

static func meld_plan_text(hand: Array) -> String:
	var groups := best_meld_groups(hand)
	if groups.is_empty():
		return StrategyText.advice(
			"Build toward your first meld.",
			"No complete set/run is available in the current best layout.",
			"Keep pairs, two-card suited sequences, and flexible middle cards."
		)
	var parts := []
	for group in groups:
		parts.append("%s %s (%d)" % [meld_kind(group), CardTools.cards_text(group), meld_points(group)])
	return StrategyText.advice(
		"Treat %s as your current meld plan." % CardTools.join_strings(parts, "; "),
		"The optimizer compares overlapping sets/runs and keeps the highest-value non-overlapping combination.",
		"Before melding in Rummy 500, consider whether a visible layoff or longer run is available this turn."
	)

static func card_support_text(card: Dictionary, hand: Array) -> String:
	var same_rank := 0
	var lower_neighbor := false
	var upper_neighbor := false
	var card_value := CardTools.rank_low_value(card.rank)
	for other in hand:
		if other == card:
			continue
		if other.rank == card.rank:
			same_rank += 1
		if other.suit == card.suit:
			var value := CardTools.rank_low_value(other.rank)
			if value == card_value - 1:
				lower_neighbor = true
			elif value == card_value + 1:
				upper_neighbor = true
	var pieces := []
	if same_rank > 0:
		pieces.append("%d matching rank%s" % [same_rank, "" if same_rank == 1 else "s"])
	if lower_neighbor or upper_neighbor:
		var side_text := "two-sided run support" if lower_neighbor and upper_neighbor else "one-sided run support"
		pieces.append(side_text)
	if pieces.is_empty():
		return "It is isolated from current set/run support."
	return "It has %s." % CardTools.join_strings(pieces, " and ")

static func visible_pickup_score(card: Dictionary, hand: Array) -> int:
	return _card_support_score(card, hand)

static func _card_support_score(card: Dictionary, hand: Array) -> int:
	var score := 0
	var card_value := CardTools.rank_low_value(card.rank)
	for other in hand:
		if other == card:
			continue
		if other.rank == card.rank:
			score += 2
		if other.suit == card.suit:
			var value := CardTools.rank_low_value(other.rank)
			if abs(value - card_value) == 1:
				score += 1
	return score

static func _can_layoff_any(card: Dictionary, player_melds: Array, bot_melds: Array) -> bool:
	for meld in player_melds:
		if can_layoff(card, meld):
			return true
	for meld in bot_melds:
		if can_layoff(card, meld):
			return true
	return false
