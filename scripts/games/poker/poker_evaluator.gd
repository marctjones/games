class_name PokerEvaluator
extends RefCounted

const CardTools := preload("res://scripts/core/card_tools.gd")

static func evaluate_five(hand: Array) -> Dictionary:
	var ranks := []
	var suits := {}
	var counts := {}
	for card in hand:
		var rank_value := CardTools.rank_value(card.rank)
		ranks.append(rank_value)
		suits[card.suit] = int(suits.get(card.suit, 0)) + 1
		counts[rank_value] = int(counts.get(rank_value, 0)) + 1
	ranks.sort()
	ranks.reverse()
	var unique := []
	for rank in ranks:
		if not unique.has(rank):
			unique.append(rank)
	var straight_high := straight_high(unique)
	var flush := false
	for suit in suits.keys():
		if int(suits[suit]) == 5:
			flush = true
	var groups := []
	for rank in counts.keys():
		groups.append({"rank": int(rank), "count": int(counts[rank])})
	groups.sort_custom(func(a, b):
		if a["count"] == b["count"]:
			return a["rank"] > b["rank"]
		return a["count"] > b["count"]
	)
	if flush and straight_high > 0:
		return {"category": 8, "tiebreak": [straight_high], "name": "straight flush"}
	if groups[0]["count"] == 4:
		return {"category": 7, "tiebreak": [groups[0]["rank"], groups[1]["rank"]], "name": "four of a kind"}
	if groups[0]["count"] == 3 and groups.size() > 1 and groups[1]["count"] == 2:
		return {"category": 6, "tiebreak": [groups[0]["rank"], groups[1]["rank"]], "name": "full house"}
	if flush:
		return {"category": 5, "tiebreak": ranks, "name": "flush"}
	if straight_high > 0:
		return {"category": 4, "tiebreak": [straight_high], "name": "straight"}
	if groups[0]["count"] == 3:
		return {"category": 3, "tiebreak": group_tiebreak(groups), "name": "three of a kind"}
	if groups[0]["count"] == 2 and groups.size() > 1 and groups[1]["count"] == 2:
		return {"category": 2, "tiebreak": group_tiebreak(groups), "name": "two pair"}
	if groups[0]["count"] == 2:
		return {"category": 1, "tiebreak": group_tiebreak(groups), "name": "one pair"}
	return {"category": 0, "tiebreak": ranks, "name": "high card"}

static func evaluate_best(cards: Array) -> Dictionary:
	if cards.size() < 5:
		return {"category": -1, "tiebreak": [], "name": "not enough cards", "cards": []}
	var best := {"category": -1, "tiebreak": [], "name": "not enough cards", "cards": []}
	for a in range(cards.size() - 4):
		for b in range(a + 1, cards.size() - 3):
			for c in range(b + 1, cards.size() - 2):
				for d in range(c + 1, cards.size() - 1):
					for e in range(d + 1, cards.size()):
						var hand := [cards[a], cards[b], cards[c], cards[d], cards[e]]
						var evaluation := evaluate_five(hand)
						if compare_evals(evaluation, best) > 0:
							best = evaluation
							best["cards"] = hand
	return best

static func compare_evals(a: Dictionary, b: Dictionary) -> int:
	if int(a["category"]) > int(b["category"]):
		return 1
	if int(a["category"]) < int(b["category"]):
		return -1
	var a_break: Array = a["tiebreak"]
	var b_break: Array = b["tiebreak"]
	for i in range(min(a_break.size(), b_break.size())):
		if int(a_break[i]) > int(b_break[i]):
			return 1
		if int(a_break[i]) < int(b_break[i]):
			return -1
	return 0

static func straight_high(unique_desc: Array) -> int:
	var values := unique_desc.duplicate()
	values.sort()
	values.reverse()
	if values == [14, 5, 4, 3, 2]:
		return 5
	for i in range(values.size() - 1):
		if int(values[i]) != int(values[i + 1]) + 1:
			return 0
	return values[0] if values.size() == 5 else 0

static func group_tiebreak(groups: Array) -> Array:
	var values := []
	for group in groups:
		for i in range(int(group["count"])):
			values.append(int(group["rank"]))
	return values
