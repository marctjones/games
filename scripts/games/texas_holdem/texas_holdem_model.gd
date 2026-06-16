class_name TexasHoldemModel
extends RefCounted

const CardTools := preload("res://scripts/core/card_tools.gd")
const PokerEvaluator := preload("res://scripts/games/poker/poker_evaluator.gd")
const StrategyText := preload("res://scripts/core/strategy_text.gd")

const STAGES := ["preflop", "flop", "turn", "river", "showdown"]

var deck: Array = []
var player: Array = []
var bots: Array = []
var community: Array = []
var folded_bots: Array = []
var bot_results: Array = []
var opponent_count := 2
var stage := "preflop"
var done := false
var player_folded := false
var player_bankroll := 1000
var computer_bankrolls := []
var pot := 0
var current_bet := 10
var hands_played := 0
var last_message := ""
var result_text := ""

func new_hand() -> void:
	deck = CardTools.make_deck()
	player = []
	bots = []
	community = []
	folded_bots = []
	bot_results = []
	computer_bankrolls = _bankrolls_for_count(opponent_count)
	stage = "preflop"
	done = false
	player_folded = false
	pot = 0
	current_bet = 10
	result_text = ""
	for i in range(opponent_count):
		bots.append([])
		folded_bots.append(false)
		bot_results.append("")
		_pay_blind_for_computer(i, 10)
	_pay_from_player(10)
	for i in range(2):
		player.append(CardTools.draw_card(deck))
		for hand in bots:
			hand.append(CardTools.draw_card(deck))
	player.sort_custom(CardTools.sort_cards)
	for hand in bots:
		hand.sort_custom(CardTools.sort_cards)
	last_message = "Preflop. Review your two hole cards, then check/call to see the flop or fold."

func set_opponent_count(count: int) -> void:
	opponent_count = clamp(count, 1, 5)
	computer_bankrolls = _bankrolls_for_count(opponent_count)
	reset_score()
	new_hand()

func reset_score() -> void:
	player_bankroll = 1000
	computer_bankrolls = []
	for i in range(opponent_count):
		computer_bankrolls.append(1000)
	hands_played = 0

func check_call() -> String:
	if done:
		return "Hand is already over."
	_pay_from_player(current_bet)
	_bot_decisions()
	_advance_stage()
	return last_message

func fold() -> String:
	if done:
		return "Hand is already over."
	player_folded = true
	done = true
	stage = "showdown"
	hands_played += 1
	_award_pot_to_best_computer()
	last_message = "You folded. The remaining computer seats split the pot by best hand."
	result_text = last_message
	return last_message

func _advance_stage() -> void:
	match stage:
		"preflop":
			community.append(CardTools.draw_card(deck))
			community.append(CardTools.draw_card(deck))
			community.append(CardTools.draw_card(deck))
			stage = "flop"
			last_message = "Flop dealt. Re-evaluate draws using your two cards plus the three community cards."
		"flop":
			community.append(CardTools.draw_card(deck))
			stage = "turn"
			last_message = "Turn dealt. One card remains before showdown."
		"turn":
			community.append(CardTools.draw_card(deck))
			stage = "river"
			last_message = "River dealt. Check/call for showdown, or fold if you are using this as a risk drill."
		"river":
			_finish_showdown()

func _finish_showdown() -> void:
	done = true
	stage = "showdown"
	hands_played += 1
	var player_eval := player_evaluation()
	var best_eval: Dictionary = player_eval
	var winners := ["You"]
	var lines := ["You: %s (%s)" % [CardTools.cards_text(player), player_eval["name"]]]
	for i in range(bots.size()):
		if folded_bots[i]:
			lines.append("Computer %d folded." % (i + 1))
			continue
		var eval := bot_evaluation(i)
		lines.append("Computer %d: %s (%s)" % [i + 1, CardTools.cards_text(bots[i]), eval["name"]])
		var compare := PokerEvaluator.compare_evals(eval, best_eval)
		if compare > 0:
			best_eval = eval
			winners = ["Computer %d" % (i + 1)]
		elif compare == 0:
			winners.append("Computer %d" % (i + 1))
	var share := int(floor(float(pot) / float(winners.size())))
	for winner in winners:
		if winner == "You":
			player_bankroll += share
		else:
			var index := int(winner.replace("Computer ", "")) - 1
			computer_bankrolls[index] += share
	var outcome := "Pot split by %s." % CardTools.join_strings(winners, ", ") if winners.size() > 1 else "%s wins the $%d pot." % [winners[0], pot]
	result_text = "%s\nBoard: %s\n%s" % [outcome, CardTools.cards_text(community), CardTools.join_strings(lines, "\n")]
	last_message = outcome
	pot = 0

func _bot_decisions() -> void:
	for i in range(bots.size()):
		if folded_bots[i]:
			continue
		var strength := bot_strength(i)
		var threshold := 1
		if stage == "preflop":
			threshold = 0
		if strength < threshold and current_bet > 10:
			folded_bots[i] = true
			bot_results[i] = "folded"
		else:
			_pay_blind_for_computer(i, current_bet)
			bot_results[i] = "called"

func bot_strength(index: int) -> int:
	var cards: Array = bots[index].duplicate()
	for card in community:
		cards.append(card)
	if cards.size() >= 5:
		var made_strength: int = int(PokerEvaluator.evaluate_best(cards)["category"])
		if made_strength > 0:
			return made_strength
		return 1 if _draw_profile(cards)["has_draw"] else 0
	var ranks := {}
	for card in bots[index]:
		ranks[card.rank] = int(ranks.get(card.rank, 0)) + 1
	for rank in ranks.keys():
		if int(ranks[rank]) == 2:
			return 1
	return 0

func player_evaluation() -> Dictionary:
	var cards: Array = player.duplicate()
	for card in community:
		cards.append(card)
	return PokerEvaluator.evaluate_best(cards)

func bot_evaluation(index: int) -> Dictionary:
	var cards: Array = bots[index].duplicate()
	for card in community:
		cards.append(card)
	return PokerEvaluator.evaluate_best(cards)

func _award_pot_to_best_computer() -> void:
	var active := []
	for i in range(bots.size()):
		if not folded_bots[i]:
			active.append(i)
	if active.is_empty():
		active.append(0)
	var best_index: int = active[0]
	var best_eval := bot_evaluation(best_index)
	for index in active:
		var eval := bot_evaluation(index)
		if PokerEvaluator.compare_evals(eval, best_eval) > 0:
			best_eval = eval
			best_index = index
	computer_bankrolls[best_index] += pot
	pot = 0

func _pay_from_player(amount: int) -> void:
	var paid: int = min(amount, player_bankroll)
	player_bankroll -= paid
	pot += paid

func _pay_blind_for_computer(index: int, amount: int) -> void:
	var paid: int = min(amount, int(computer_bankrolls[index]))
	computer_bankrolls[index] = int(computer_bankrolls[index]) - paid
	pot += paid

func _bankrolls_for_count(count: int) -> Array:
	var values := []
	for i in range(count):
		if i < computer_bankrolls.size():
			values.append(computer_bankrolls[i])
		else:
			values.append(1000)
	return values

func score_text() -> String:
	return "Dollars - You: $%d  Pot: $%d  Hands: %d" % [player_bankroll, pot, hands_played]

func table_text() -> String:
	return "Stage: %s | Board: %s | Opponents: %d | Pot: $%d" % [stage.capitalize(), CardTools.cards_text(community), opponent_count, pot]

func guidance_text() -> String:
	if done:
		return StrategyText.advice(
			"Start a new hand.",
			"The useful review is whether your preflop class and postflop draw read matched the final board.",
			"Track bankroll in dollars, not only whether one hand won."
		)
	if stage == "preflop":
		return _preflop_hint()
	var eval := player_evaluation()
	var cards: Array = player.duplicate()
	for card in community:
		cards.append(card)
	var profile := _draw_profile(cards)
	if int(eval["category"]) >= 1:
		return StrategyText.advice(
			"Continue with %s." % eval["name"],
			"A made hand has showdown value; stronger categories can call more comfortably.",
			"%s Board: %s." % [str(profile["watch"]), CardTools.cards_text(community)],
			"Name the best five-card hand before you act."
		)
	if bool(profile["has_draw"]):
		return StrategyText.advice(
			"Continue as a draw drill.",
			str(profile["reason"]),
			"%s Pot is $%d, so notice how much you are paying to chase." % [str(profile["watch"]), pot],
			"Say which outs improve you before the next card."
		)
	return StrategyText.advice(
		"Check/call only as a practice hand; folding is reasonable.",
		"You currently have high card with no strong four-card draw.",
		"High-card hands lose value fast on coordinated boards.",
		"Look for paired ranks, four-card flushes, and four-card straights first."
	)

func _preflop_hint() -> String:
	var plan := _preflop_plan(player)
	return StrategyText.advice(
		str(plan["action"]),
		str(plan["reason"]),
		str(plan["watch"]),
		str(plan["drill"])
	)

func _preflop_plan(hand: Array) -> Dictionary:
	var first: Dictionary = hand[0]
	var second: Dictionary = hand[1]
	if first.rank == second.rank:
		return {
			"action": "Check/call with the pocket pair.",
			"reason": "A pair starts ahead of most unpaired hands and can improve to a set.",
			"watch": "Small pairs want cheap flops; big pairs can continue on more boards.",
			"drill": "After the flop, ask whether an overcard changed the hand."
		}
	var first_value: int = CardTools.rank_value(first.rank)
	var second_value: int = CardTools.rank_value(second.rank)
	var gap: int = abs(first_value - second_value)
	if first.suit == second.suit and gap <= 4:
		return {
			"action": "Check/call as a suited-connector drill.",
			"reason": "Suited connected cards can make flushes, straights, and disguised two-pair hands.",
			"watch": "Small suited hands need draw texture; do not treat them like made hands.",
			"drill": "On the flop, count flush and straight outs."
		}
	if first_value >= 11 and second_value >= 10:
		return {
			"action": "Check/call with two high cards.",
			"reason": "Broadway cards often win by pairing top pair with a strong kicker.",
			"watch": "Unpaired high cards are still only high card if the flop misses.",
			"drill": "Name your kicker and the top board card."
		}
	if max(first_value, second_value) == 14 and min(first_value, second_value) >= 9:
		return {
			"action": "Continue cautiously with ace-high.",
			"reason": "A strong ace can make top pair, but it still needs board help.",
			"watch": "Weak kickers create dominated top-pair spots.",
			"drill": "Compare your second card to the board when an ace appears."
		}
	return {
		"action": "Fold, or call only as a postflop-reading drill.",
		"reason": "This is a marginal starting hand without pair, high-card, suited, or connected strength.",
		"watch": "Do not let curiosity turn every weak hand into a paid lesson.",
		"drill": "If you call, identify exactly which flop textures help."
	}

func _draw_profile(cards: Array) -> Dictionary:
	var suit_counts := {}
	for card in cards:
		suit_counts[card.suit] = int(suit_counts.get(card.suit, 0)) + 1
	for suit in suit_counts.keys():
		if int(suit_counts[suit]) >= 4:
			return {
				"has_draw": true,
				"reason": "You have at least four cards to a flush.",
				"watch": "Flush draws improve when paired with overcards or straight possibilities."
			}
	var straight_kind := _straight_draw_kind(cards)
	if straight_kind != "":
		return {
			"has_draw": true,
			"reason": "You have a %s straight draw." % straight_kind,
			"watch": "Open-ended draws are stronger than inside draws."
		}
	return {
		"has_draw": false,
		"reason": "No major draw is visible.",
		"watch": "Dry high-card hands need caution."
	}

func _straight_draw_kind(cards: Array) -> String:
	for low in range(1, 11):
		var high := low + 4
		var window := []
		for value in range(low, high + 1):
			window.append(value)
		var seen := []
		for card in cards:
			for value in _straight_values_for_card(card):
				if window.has(value) and not seen.has(value):
					seen.append(value)
		if seen.size() >= 4:
			var missing_low := not seen.has(low)
			var missing_high := not seen.has(high)
			if (missing_low or missing_high) and low > 1 and high < 14:
				return "open-ended"
			return "inside"
	return ""

func _straight_values_for_card(card: Dictionary) -> Array:
	if card.rank == "A":
		return [1, 14]
	return [CardTools.rank_value(card.rank)]
