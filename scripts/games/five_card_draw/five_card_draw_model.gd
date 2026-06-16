class_name FiveCardDrawModel
extends RefCounted

const CardTools := preload("res://scripts/core/card_tools.gd")
const PokerEvaluator := preload("res://scripts/games/poker/poker_evaluator.gd")
const StrategyText := preload("res://scripts/core/strategy_text.gd")

var deck: Array = []
var player: Array = []
var bot: Array = []
var bots: Array = []
var selected: Array = []
var done := false
var result_text := ""
var opponent_count := 1
var player_wins := 0
var computer_wins := 0
var ties := 0

func new_hand() -> void:
	deck = CardTools.make_deck()
	player = []
	bot = []
	bots = []
	selected = []
	done = false
	result_text = ""
	for i in range(opponent_count):
		bots.append([])
	for i in range(5):
		player.append(CardTools.draw_card(deck))
		for opponent in bots:
			opponent.append(CardTools.draw_card(deck))
	player.sort_custom(CardTools.sort_cards)
	for opponent in bots:
		opponent.sort_custom(CardTools.sort_cards)
	bot = bots[0] if not bots.is_empty() else []

func set_opponent_count(count: int) -> void:
	opponent_count = clamp(count, 1, 5)
	new_hand()

func reset_score() -> void:
	player_wins = 0
	computer_wins = 0
	ties = 0

func score_text() -> String:
	return "Score - You: %d  Computers: %d  Ties: %d" % [player_wins, computer_wins, ties]

func toggle_discard(card: Dictionary) -> String:
	if done:
		return ""
	if selected.has(card):
		selected.erase(card)
	elif selected.size() < 3:
		selected.append(card)
	else:
		return "House rule for this prototype: draw up to three cards."
	return ""

func showdown() -> String:
	if done:
		return result_text
	for card in selected:
		player.erase(card)
	while player.size() < 5:
		player.append(CardTools.draw_card(deck))
	for opponent in bots:
		var opponent_discards := bot_discards_for(opponent)
		for card in opponent_discards:
			opponent.erase(card)
		while opponent.size() < 5:
			opponent.append(CardTools.draw_card(deck))
	player.sort_custom(CardTools.sort_cards)
	for opponent in bots:
		opponent.sort_custom(CardTools.sort_cards)
	bot = bots[0] if not bots.is_empty() else []
	done = true

	var player_eval := PokerEvaluator.evaluate_five(player)
	var best_eval: Dictionary = player_eval
	var winner_names := ["You"]
	var opponent_lines := []
	for i in range(bots.size()):
		var opponent_eval := PokerEvaluator.evaluate_five(bots[i])
		opponent_lines.append("Computer %d: %s (%s)" % [i + 1, CardTools.cards_text(bots[i]), opponent_eval["name"]])
		var comparison := PokerEvaluator.compare_evals(opponent_eval, best_eval)
		if comparison > 0:
			best_eval = opponent_eval
			winner_names = ["Computer %d" % (i + 1)]
		elif comparison == 0:
			winner_names.append("Computer %d" % (i + 1))
	var result := ""
	if winner_names.size() == 1 and winner_names[0] == "You":
		result = "You win."
		player_wins += 1
	elif winner_names.has("You"):
		result = "Tie: %s." % CardTools.join_strings(winner_names, ", ")
		ties += 1
	else:
		result = "%s wins." % winner_names[0]
		computer_wins += 1
	result_text = "Your hand: %s (%s)\n%s\n%s" % [
		CardTools.cards_text(player),
		player_eval["name"],
		CardTools.join_strings(opponent_lines, "\n"),
		result
	]
	return result_text

func bot_discards() -> Array:
	return bot_discards_for(bot)

func suggested_discards() -> Array:
	if done:
		return []
	return bot_discards_for(player)

func guidance_text() -> String:
	if done:
		return StrategyText.advice(
			"Start a new hand.",
			"Five-card draw skill comes from comparing your original draw plan with the final showdown.",
			"Review whether the draw protected made value or chased a realistic improvement."
		)
	var plan := draw_plan_for(player)
	var suggestion: Array = plan["discards"]
	var current_eval := PokerEvaluator.evaluate_five(player)
	if suggestion.is_empty():
		return StrategyText.advice(
			"Stand pat with %s." % current_eval["name"],
			str(plan["reason"]),
			str(plan["watch"]),
			"Name the hand class before you press Showdown."
		)
	return StrategyText.advice(
		"Discard %s." % CardTools.cards_text(suggestion),
		str(plan["reason"]),
		str(plan["watch"]),
		"Before drawing, say what card types improve the hand."
	)

func bot_discards_for(hand: Array) -> Array:
	var plan := draw_plan_for(hand)
	return plan["discards"]

func draw_plan_for(hand: Array) -> Dictionary:
	if hand.is_empty():
		return {"keep": [], "discards": [], "reason": "No cards are available.", "watch": "Start a new hand."}
	var current_eval := PokerEvaluator.evaluate_five(hand)
	var rank_counts := {}
	var suit_counts := {}
	for card in hand:
		rank_counts[card.rank] = int(rank_counts.get(card.rank, 0)) + 1
		suit_counts[card.suit] = int(suit_counts.get(card.suit, 0)) + 1
	var keep := []
	var reason := ""
	var watch := ""
	if int(current_eval["category"]) >= 4:
		keep = hand.duplicate()
		reason = "A %s is already a strong made hand, so the draw should not break it." % current_eval["name"]
		watch = "Standing pat is correct for straights, flushes, full houses, and better in this basic trainer."
		return _draw_plan_result(hand, keep, reason, watch)
	for card in hand:
		if int(rank_counts[card.rank]) >= 2:
			keep.append(card)
	if not keep.is_empty():
		var group_name := "pair"
		if int(current_eval["category"]) == 3:
			group_name = "three of a kind"
		elif int(current_eval["category"]) == 2:
			group_name = "two pair"
		reason = "Keep the %s and draw with the unpaired cards." % group_name
		watch = "Pairs usually draw three, two pair draws one, and trips draw two."
		return _draw_plan_result(hand, keep, reason, watch)
	var flush_suit := ""
	for suit in suit_counts.keys():
		if int(suit_counts[suit]) >= 4:
			flush_suit = suit
	if flush_suit != "":
		for card in hand:
			if card.suit == flush_suit:
				keep.append(card)
		reason = "Four cards share a suit, so one draw can complete a flush."
		watch = "A flush draw is stronger when the kept cards are high enough to still win unimproved."
		return _draw_plan_result(hand, keep, reason, watch)
	var straight_keep := _straight_draw_keep(hand)
	if straight_keep.size() >= 4:
		keep = straight_keep
		reason = "Four connected ranks give you a one-card straight draw."
		watch = "Open-ended draws are better than inside draws; do not chase weak gaps over a made pair."
		return _draw_plan_result(hand, keep, reason, watch)
	if keep.is_empty():
		var sorted := hand.duplicate()
		sorted.sort_custom(func(a, b): return CardTools.rank_value(a.rank) > CardTools.rank_value(b.rank))
		keep = [sorted[0], sorted[1]]
		reason = "With no pair or four-card draw, keep the two highest cards and replace the rest."
		watch = "High-card draws are weak; this is mainly a practice fallback."
	return _draw_plan_result(hand, keep, reason, watch)

func _draw_plan_result(hand: Array, keep: Array, reason: String, watch: String) -> Dictionary:
	var discards := []
	for card in hand:
		if not keep.has(card) and discards.size() < 3:
			discards.append(card)
	return {"keep": keep, "discards": discards, "reason": reason, "watch": watch}

func _straight_draw_keep(hand: Array) -> Array:
	var best_keep := []
	var best_high := 0
	for low in range(1, 11):
		var high := low + 4
		var window := []
		for value in range(low, high + 1):
			window.append(value)
		var seen_values := []
		var keep := []
		for card in hand:
			for value in _straight_values_for_card(card):
				if window.has(value) and not seen_values.has(value):
					seen_values.append(value)
					keep.append(card)
					break
		if seen_values.size() >= 4 and high > best_high:
			best_high = high
			best_keep = keep
	return best_keep

func _straight_values_for_card(card: Dictionary) -> Array:
	if card.rank == "A":
		return [1, 14]
	return [CardTools.rank_value(card.rank)]

func prompt_text() -> String:
	return "Your hand: %s\nSelected discards: %s\nComputer opponents: %d" % [CardTools.cards_text(player), CardTools.cards_text(selected), opponent_count]
