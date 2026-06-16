class_name CribbageModel
extends RefCounted

const CardTools := preload("res://scripts/core/card_tools.gd")
const OpponentPolicy := preload("res://scripts/core/opponent_policy.gd")
const StrategyText := preload("res://scripts/core/strategy_text.gd")

const TARGET_SCORE := 121
const SKUNK_THRESHOLD := 90

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
var dealer_index := 0
var current_player_hand_score := 0
var current_computer_hand_score := 0
var current_crib_score := 0
var current_player_pegging_score := 0
var current_computer_pegging_score := 0
var crib_owner := ""
var round_complete := false
var match_complete := false
var last_round_summary := "No rounds scored yet."

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
	current_player_hand_score = 0
	current_computer_hand_score = 0
	current_crib_score = 0
	current_player_pegging_score = 0
	current_computer_pegging_score = 0
	round_complete = false
	match_complete = false
	crib_owner = player_name(dealer_index)
	last_round_summary = "Dealer: %s. Choose the crib discards for this round." % crib_owner
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
	dealer_index = 0
	reset_score()
	new_hand()

func discard_goal() -> int:
	return 2 if player_count == 2 else 1

func toggle_discard(card: Dictionary) -> void:
	if round_complete:
		return
	if selected_discards.has(card):
		selected_discards.erase(card)
	elif selected_discards.size() < discard_goal():
		selected_discards.append(card)

func score_discards() -> String:
	if round_complete:
		return result_text
	if selected_discards.size() != discard_goal():
		return "Choose exactly %d discard%s." % [discard_goal(), "" if discard_goal() == 1 else "s"]
	crib_owner = player_name(dealer_index)
	for card in selected_discards:
		player.erase(card)
		crib.append(card)
	for computer in bots:
		var bot_discards := choose_opponent_discards_for(computer, discard_goal())
		for card in bot_discards:
			computer.erase(card)
			crib.append(card)
	cut_card = CardTools.draw_card(deck)
	var heels_points := 0
	if str(cut_card.rank) == "J":
		heels_points = 2
		_award_points_to_player(dealer_index, heels_points)
	var pegging := _simulate_round_pegging()
	current_player_pegging_score = int(pegging["player"])
	current_computer_pegging_score = int(pegging["computer"])
	player_score_total += current_player_pegging_score
	computer_score_total += current_computer_pegging_score
	current_player_hand_score = score_hand(player, cut_card, false)
	player_score_total += current_player_hand_score
	current_computer_hand_score = 0
	var bot_lines := []
	for i in range(bots.size()):
		var bot_score := score_hand(bots[i], cut_card, false)
		current_computer_hand_score += bot_score
		computer_score_total += bot_score
		bot_lines.append("Computer %d kept hand: %s = %d" % [i + 1, CardTools.cards_text(bots[i]), bot_score])
	current_crib_score = score_hand(crib, cut_card, true)
	if dealer_index == 0:
		player_score_total += current_crib_score
	else:
		computer_score_total += current_crib_score
	round_complete = true
	hands_played += 1
	match_complete = player_score_total >= TARGET_SCORE or computer_score_total >= TARGET_SCORE
	last_round_summary = _round_summary_text(heels_points, pegging["log"], bot_lines)
	result_text = last_round_summary
	return result_text

func advance_round() -> void:
	if not round_complete:
		return
	dealer_index = (dealer_index + 1) % player_count
	new_hand()

func reset_score() -> void:
	player_score_total = 0
	computer_score_total = 0
	hands_played = 0
	current_player_hand_score = 0
	current_computer_hand_score = 0
	current_crib_score = 0
	current_player_pegging_score = 0
	current_computer_pegging_score = 0
	round_complete = false
	match_complete = false
	last_round_summary = "No rounds scored yet."

func score_text() -> String:
	var match_text := ""
	if match_complete:
		match_text = " | Match complete"
	return "Score to %d - You: %d  Computer: %d  Hands: %d%s" % [TARGET_SCORE, player_score_total, computer_score_total, hands_played, match_text]

func prompt_text() -> String:
	if round_complete:
		return last_round_summary
	return "Dealer: %s\nYour hand: %s\nSelected discards: %s\nChoose %d card%s for the crib." % [
		crib_owner,
		CardTools.cards_text(player),
		CardTools.cards_text(selected_discards),
		discard_goal(),
		"" if discard_goal() == 1 else "s"
	]

func choose_bot_discards() -> Array:
	return choose_bot_discards_for(bot, discard_goal())

func suggested_discards() -> Array:
	if round_complete:
		return []
	return choose_bot_discards_for(player, discard_goal())

func guidance_text() -> String:
	if round_complete:
		return StrategyText.advice(
			"Start the next round.",
			last_round_summary,
			"Cribbage decisions should be judged over the full round: pegging, hand score, crib ownership, and match position."
		)
	var suggestion := suggested_discards()
	var kept := _kept_after_discards(player, suggestion)
	var crib_note := "Protect the opponent crib." if dealer_index != 0 else "Feed your own crib only when the kept hand stays strong."
	return StrategyText.advice(
		"Discard %s." % CardTools.cards_text(suggestion),
		"That keeps an average expected hand value near %.1f before the cut. Dealer: %s." % [_average_cut_score(kept, player), crib_owner],
		"%s %s" % [crib_note, _discard_risk_text(suggestion)],
		"Look for fifteens, pairs, runs, flushes, and a jack for nobs."
	)

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
			var lowest := _lowest_discards(hand, count)
			if lowest.size() == count:
				return lowest
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
			total += float(score_hand(kept, cut, false))
			count += 1
	if count == 0:
		return float(score_hand(kept, {}, false))
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
		return "Those discards carry strong crib risk, especially 5s, pairs, or connected cards."
	if risk >= 2.0:
		return "Moderate crib risk: connected cards, pairs, fifteens, and 5s can feed a crib."
	return "Low crib risk: these cards are relatively disconnected."

func _simulate_round_pegging() -> Dictionary:
	if player_count != 2:
		return _simulate_simple_pegging(player, _combined_bot_cards())
	var start_player := 0 if dealer_index != 0 else 1
	return simulate_pegging(player, bot, start_player)

func _combined_bot_cards() -> Array:
	var cards := []
	for computer in bots:
		for card in computer:
			cards.append(card)
	return cards

func simulate_pegging(player_cards: Array, computer_cards: Array, start_turn: int = 0) -> Dictionary:
	var player_remaining := player_cards.duplicate()
	var computer_remaining := computer_cards.duplicate()
	player_remaining.sort_custom(func(a, b): return CardTools.pip_value(a.rank) < CardTools.pip_value(b.rank))
	computer_remaining.sort_custom(func(a, b): return CardTools.pip_value(a.rank) < CardTools.pip_value(b.rank))
	var running_total := 0
	var sequence := []
	var player_points := 0
	var computer_points := 0
	var turn := start_turn
	var last_player_to_play := -1
	var said_go := [false, false]
	var log_parts := []
	while not player_remaining.is_empty() or not computer_remaining.is_empty():
		var hand := player_remaining if turn == 0 else computer_remaining
		var card := _lowest_legal_pegging_card(hand, running_total)
		if card.is_empty():
			if said_go[turn]:
				if last_player_to_play >= 0 and running_total > 0 and running_total != 31:
					if last_player_to_play == 0:
						player_points += 1
					else:
						computer_points += 1
					log_parts.append("go for 1")
				running_total = 0
				sequence = []
				said_go = [false, false]
			else:
				said_go[turn] = true
			turn = 1 - turn
			continue
		said_go = [false, false]
		hand.erase(card)
		running_total += CardTools.pip_value(card.rank)
		sequence.append(card)
		last_player_to_play = turn
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
			said_go = [false, false]
			last_player_to_play = -1
		turn = 1 - turn
	if last_player_to_play >= 0 and running_total > 0:
		if last_player_to_play == 0:
			player_points += 1
		else:
			computer_points += 1
		log_parts.append("last card for 1")
	if log_parts.is_empty():
		log_parts.append("No fifteens, thirty-ones, pairs, or runs appeared.")
	return {"player": player_points, "computer": computer_points, "log": CardTools.join_strings(log_parts, "; ")}

func _simulate_simple_pegging(player_cards: Array, computer_cards: Array) -> Dictionary:
	return simulate_pegging(player_cards, computer_cards, 0 if dealer_index != 0 else 1)

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

func _award_points_to_player(position: int, points: int) -> void:
	if position == 0:
		player_score_total += points
	else:
		computer_score_total += points

func _round_summary_text(heels_points: int, pegging_log: String, bot_lines: Array) -> String:
	var crib_line := "Crib owner: %s. Crib %s = %d." % [crib_owner, CardTools.cards_text(crib), current_crib_score]
	var heels_line := ""
	if heels_points > 0:
		heels_line = " His heels: %s scores %d for cutting %s." % [crib_owner, heels_points, CardTools.card_text(cut_card)]
	var match_line := ""
	if match_complete:
		match_line = " %s" % _match_result_text()
	return "Dealer: %s.%s\nCut: %s\nPegging: you %d, computer %d. %s\nYour kept hand: %s = %d\n%s\n%s\nRound totals - You: %d, Computer: %d.%s" % [
		crib_owner,
		heels_line,
		CardTools.card_text(cut_card),
		current_player_pegging_score,
		current_computer_pegging_score,
		pegging_log,
		CardTools.cards_text(player),
		current_player_hand_score,
		CardTools.join_strings(bot_lines, "\n"),
		crib_line,
		player_score_total,
		computer_score_total,
		match_line
	]

func _match_result_text() -> String:
	var winner: String = "You" if player_score_total >= TARGET_SCORE and player_score_total >= computer_score_total else "Computer"
	var loser_score: int = min(player_score_total, computer_score_total)
	var margin_text: String = " Skunk." if loser_score < SKUNK_THRESHOLD else ""
	return "%s reaches %d first.%s" % [winner, TARGET_SCORE, margin_text]

func player_name(position: int) -> String:
	if position == 0:
		return "You"
	return "Computer %d" % position

static func score_hand(hand: Array, cut_card: Dictionary, is_crib: bool = false) -> int:
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
	score += flush_points(hand, cut_card, is_crib)
	score += nobs_points(hand, cut_card)
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

static func flush_points(hand: Array, cut_card: Dictionary, is_crib: bool) -> int:
	if hand.is_empty():
		return 0
	var suit := str(hand[0].suit)
	for card in hand:
		if str(card.suit) != suit:
			return 0
	if cut_card.is_empty():
		return 4
	if str(cut_card.suit) == suit:
		return 5
	if is_crib:
		return 0
	return 4

static func nobs_points(hand: Array, cut_card: Dictionary) -> int:
	if cut_card.is_empty():
		return 0
	for card in hand:
		if str(card.rank) == "J" and str(card.suit) == str(cut_card.suit):
			return 1
	return 0
