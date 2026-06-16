class_name CribbageModel
extends RefCounted

const CardTools := preload("res://scripts/core/card_tools.gd")
const OpponentPolicy := preload("res://scripts/core/opponent_policy.gd")
const StrategyText := preload("res://scripts/core/strategy_text.gd")

var deck: Array = []
var player: Array = []
var bot: Array = []
var bots: Array = []
var crib: Array = []
var selected_discards: Array = []
var cut_card: Dictionary = {}
var result_text := ""
var player_count := 2
var player_score_total := 0
var computer_score_total := 0
var hands_played := 0
var opponent_difficulty := OpponentPolicy.DEFAULT

func set_difficulty(difficulty: String) -> void:
	opponent_difficulty = OpponentPolicy.normalize(difficulty)

func new_hand() -> void:
	deck = CardTools.make_deck()
	player = []
	bot = []
	bots = []
	crib = []
	selected_discards = []
	cut_card = {}
	result_text = ""
	for i in range(player_count - 1):
		bots.append([])
	if player_count == 3:
		crib.append(CardTools.draw_card(deck))
	var cards_per_player := 6 if player_count == 2 else 5
	for i in range(cards_per_player):
		player.append(CardTools.draw_card(deck))
		for computer in bots:
			computer.append(CardTools.draw_card(deck))
	player.sort_custom(CardTools.sort_cards)
	for computer in bots:
		computer.sort_custom(CardTools.sort_cards)
	bot = bots[0] if not bots.is_empty() else []

func set_player_count(count: int) -> void:
	player_count = clamp(count, 2, 4)
	new_hand()

func discard_goal() -> int:
	return 2 if player_count == 2 else 1

func toggle_discard(card: Dictionary) -> void:
	if cut_card.size() > 0:
		return
	if selected_discards.has(card):
		selected_discards.erase(card)
	elif selected_discards.size() < discard_goal():
		selected_discards.append(card)

func score_discards() -> String:
	if cut_card.size() > 0:
		return result_text
	if selected_discards.size() != discard_goal():
		return "Choose exactly %d discard%s." % [discard_goal(), "" if discard_goal() == 1 else "s"]
	for card in selected_discards:
		player.erase(card)
		crib.append(card)
	for computer in bots:
		var bot_discards := choose_opponent_discards_for(computer, discard_goal())
		for card in bot_discards:
			computer.erase(card)
			crib.append(card)
	cut_card = CardTools.draw_card(deck)
	var player_score := score_hand(player, cut_card)
	var bot_lines := []
	var best_computer_score := -1
	var combined_computer_score := 0
	for i in range(bots.size()):
		var bot_score := score_hand(bots[i], cut_card)
		combined_computer_score += bot_score
		best_computer_score = max(best_computer_score, bot_score)
		bot_lines.append("Computer %d kept hand: %s = %d" % [i + 1, CardTools.cards_text(bots[i]), bot_score])
	var crib_score := score_hand(crib, cut_card)
	var pegging := simulate_pegging(player, bots[0] if not bots.is_empty() else [])
	var result := "You win the hand." if player_score > best_computer_score else "Computer wins the hand."
	if player_score == best_computer_score:
		result = "The hand is tied."
	player_score_total += player_score + int(pegging["player"])
	computer_score_total += combined_computer_score + int(pegging["computer"])
	hands_played += 1
	result_text = "Cut: %s\nYour kept hand: %s = %d\n%s\nCrib: %s = %d\nPegging drill: you %d, computer %d. %s\n%s" % [
		CardTools.card_text(cut_card),
		CardTools.cards_text(player),
		player_score,
		CardTools.join_strings(bot_lines, "\n"),
		CardTools.cards_text(crib),
		crib_score,
		int(pegging["player"]),
		int(pegging["computer"]),
		str(pegging["log"]),
		result
	]
	return result_text

func reset_score() -> void:
	player_score_total = 0
	computer_score_total = 0
	hands_played = 0

func score_text() -> String:
	return "Score - You: %d  Computer: %d  Hands: %d" % [player_score_total, computer_score_total, hands_played]

func prompt_text() -> String:
	return "Your hand: %s\nSelected discards: %s\nChoose %d card%s for the crib." % [
		CardTools.cards_text(player),
		CardTools.cards_text(selected_discards),
		discard_goal(),
		"" if discard_goal() == 1 else "s"
	]

func choose_bot_discards() -> Array:
	return choose_bot_discards_for(bot, discard_goal())

func suggested_discards() -> Array:
	if cut_card.size() > 0:
		return []
	return choose_bot_discards_for(player, discard_goal())

func guidance_text() -> String:
	if cut_card.size() > 0:
		return StrategyText.advice(
			"Start a new hand.",
			"Compare the kept-hand score to what the discard heuristic expected before the cut.",
			"Cribbage discard skill is about average value over many possible cuts, not one lucky cut."
		)
	var suggestion := suggested_discards()
	var kept := _kept_after_discards(player, suggestion)
	return StrategyText.advice(
		"Discard %s." % CardTools.cards_text(suggestion),
		"That keeps an average expected hand value near %.1f before the cut." % _average_cut_score(kept, player),
		_discard_risk_text(suggestion),
		"Look for fifteens, pairs, and runs before worrying about single high cards."
	)

func simulate_pegging(player_cards: Array, computer_cards: Array) -> Dictionary:
	var player_remaining := player_cards.duplicate()
	var computer_remaining := computer_cards.duplicate()
	player_remaining.sort_custom(func(a, b): return CardTools.pip_value(a.rank) < CardTools.pip_value(b.rank))
	computer_remaining.sort_custom(func(a, b): return CardTools.pip_value(a.rank) < CardTools.pip_value(b.rank))
	var running_total := 0
	var sequence := []
	var player_points := 0
	var computer_points := 0
	var turn := 0
	var passes := 0
	var log_parts := []
	while not player_remaining.is_empty() or not computer_remaining.is_empty():
		var hand := player_remaining if turn == 0 else computer_remaining
		var card := _lowest_legal_pegging_card(hand, running_total)
		if card.is_empty():
			passes += 1
			if passes >= 2:
				running_total = 0
				sequence = []
				passes = 0
				log_parts.append("go/reset")
			turn = 1 - turn
			continue
		passes = 0
		hand.erase(card)
		running_total += CardTools.pip_value(card.rank)
		sequence.append(card)
		var gained := _pegging_points_for_play(sequence, running_total)
		if turn == 0:
			player_points += gained
		else:
			computer_points += gained
		if gained > 0:
			log_parts.append("%s for %d" % [CardTools.card_text(card), gained])
		if running_total == 31:
			running_total = 0
			sequence = []
		turn = 1 - turn
	if log_parts.is_empty():
		log_parts.append("No fifteens, thirty-ones, pairs, or short runs appeared.")
	return {"player": player_points, "computer": computer_points, "log": CardTools.join_strings(log_parts, "; ")}

func _lowest_legal_pegging_card(cards: Array, running_total: int) -> Dictionary:
	for card in cards:
		if running_total + CardTools.pip_value(card.rank) <= 31:
			return card
	return {}

func _pegging_points_for_play(sequence: Array, running_total: int) -> int:
	var points := 0
	if running_total == 15:
		points += 2
	elif running_total == 31:
		points += 2
	if sequence.size() >= 2:
		var last_rank: String = str(sequence[-1].rank)
		var pair_count := 1
		for i in range(sequence.size() - 2, -1, -1):
			if sequence[i].rank == last_rank:
				pair_count += 1
			else:
				break
		if pair_count == 2:
			points += 2
		elif pair_count == 3:
			points += 6
		elif pair_count >= 4:
			points += 12
	points += _pegging_run_points(sequence)
	return points

func _pegging_run_points(sequence: Array) -> int:
	for length in range(min(7, sequence.size()), 2, -1):
		var tail := sequence.slice(sequence.size() - length)
		var values := []
		var duplicate := false
		for card in tail:
			var value := CardTools.rank_low_value(card.rank)
			if values.has(value):
				duplicate = true
				break
			values.append(value)
		if duplicate:
			continue
		values.sort()
		var run := true
		for i in range(1, values.size()):
			if int(values[i]) != int(values[i - 1]) + 1:
				run = false
				break
		if run:
			return length
	return 0

func choose_bot_discards_for(hand: Array, count: int) -> Array:
	if count == 1:
		var best_single := [hand[0]]
		var best_single_score := -99999.0
		for i in range(hand.size()):
			var kept_single := []
			for k in range(hand.size()):
				if k != i:
					kept_single.append(hand[k])
			var discard := [hand[i]]
			var single_score := _average_cut_score(kept_single, hand) - _crib_risk(discard) * 0.25
			if single_score > best_single_score:
				best_single_score = single_score
				best_single = discard
		return best_single
	var best_discards := [hand[0], hand[1]]
	var best_score := -99999.0
	for i in range(hand.size()):
		for j in range(i + 1, hand.size()):
			var kept := []
			for k in range(hand.size()):
				if k != i and k != j:
					kept.append(hand[k])
			var discard_pair := [hand[i], hand[j]]
			var score := _average_cut_score(kept, hand) - _crib_risk(discard_pair) * 0.25
			if score > best_score:
				best_score = score
				best_discards = discard_pair
	return best_discards

func choose_opponent_discards_for(hand: Array, count: int) -> Array:
	match OpponentPolicy.normalize(opponent_difficulty):
		OpponentPolicy.BEGINNER:
			return _lowest_discards(hand, count)
		OpponentPolicy.CASUAL:
			var best := choose_bot_discards_for(hand, count)
			if best.size() > 0:
				var alternatives := _lowest_discards(hand, count)
				if alternatives.size() == count:
					return alternatives
	return choose_bot_discards_for(hand, count)

func _lowest_discards(hand: Array, count: int) -> Array:
	var sorted := hand.duplicate()
	sorted.sort_custom(func(a, b): return CardTools.rank_value(a.rank) < CardTools.rank_value(b.rank))
	return sorted.slice(0, min(count, sorted.size()))

func _kept_after_discards(hand: Array, discards: Array) -> Array:
	var kept := []
	for card in hand:
		if not discards.has(card):
			kept.append(card)
	return kept

func _average_cut_score(kept: Array, unavailable: Array) -> float:
	var total := 0.0
	var count := 0
	for suit in CardTools.SUITS:
		for rank in CardTools.RANKS:
			var cut := {"rank": rank, "suit": suit}
			if unavailable.has(cut):
				continue
			total += float(score_hand(kept, cut))
			count += 1
	if count == 0:
		return float(score_hand(kept, {}))
	return total / float(count)

func _crib_risk(discards: Array) -> float:
	var risk := 0.0
	var values := []
	var ranks := {}
	for card in discards:
		values.append(CardTools.pip_value(card.rank))
		ranks[card.rank] = int(ranks.get(card.rank, 0)) + 1
		if card.rank == "5":
			risk += 5.0
	for rank in ranks.keys():
		if int(ranks[rank]) >= 2:
			risk += 2.0
		if values.size() >= 2:
			if int(values[0]) + int(values[1]) == 15:
				risk += 2.0
			var rank_gap: int = abs(CardTools.rank_low_value(discards[0].rank) - CardTools.rank_low_value(discards[1].rank))
			if rank_gap <= 2:
				risk += 1.5
	return risk

func _discard_risk_text(discards: Array) -> String:
	var risk := _crib_risk(discards)
	if risk >= 5.0:
		return "Those discards carry crib risk, so only give them up when the kept hand is clearly stronger."
	if risk >= 2.0:
		return "Moderate crib risk: connected cards, pairs, fifteens, and 5s can feed a crib."
	return "Low crib risk: these cards are relatively disconnected."

static func score_hand(hand: Array, cut_card: Dictionary) -> int:
	var cards := hand.duplicate()
	if cut_card.size() > 0:
		cards.append(cut_card)
	var score := 0
	var values := []
	var rank_counts := {}
	for card in cards:
		values.append(CardTools.pip_value(card.rank))
		rank_counts[card.rank] = int(rank_counts.get(card.rank, 0)) + 1
	score += count_fifteens(values, 0, 0)
	for rank in rank_counts.keys():
		var count: int = rank_counts[rank]
		if count == 2:
			score += 2
		elif count == 3:
			score += 6
		elif count == 4:
			score += 12
	score += run_points(cards)
	return score

static func count_fifteens(values: Array, index: int, total: int) -> int:
	if total == 15:
		return 2
	if total > 15 or index >= values.size():
		return 0
	return count_fifteens(values, index + 1, total + int(values[index])) + count_fifteens(values, index + 1, total)

static func run_points(cards: Array) -> int:
	var counts := {}
	for card in cards:
		var value := CardTools.rank_low_value(card.rank)
		counts[value] = int(counts.get(value, 0)) + 1
	var best := 0
	var multiplier := 1
	for start in range(1, 12):
		var length := 0
		var local_multiplier := 1
		for value in range(start, 14):
			if counts.has(value):
				length += 1
				local_multiplier *= int(counts[value])
			else:
				break
		if length >= 3 and length > best:
			best = length
			multiplier = local_multiplier
	return best * multiplier
