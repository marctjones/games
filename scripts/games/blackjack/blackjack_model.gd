class_name BlackjackModel
extends RefCounted

const CardTools := preload("res://scripts/core/card_tools.gd")
const StrategyText := preload("res://scripts/core/strategy_text.gd")

var deck: Array = []
var player: Array = []
var player_hands: Array = []
var active_hand_index := 0
var player_bets: Array = []
var player_hand_results: Array = []
var dealer: Array = []
var computer_hands: Array = []
var computer_results: Array = []
var computer_count := 0
var done := false
var player_result := ""
var player_wins := 0
var dealer_wins := 0
var pushes := 0
var computer_wins := 0
var computer_losses := 0
var computer_pushes := 0

func new_hand() -> void:
	deck = CardTools.make_deck()
	player = []
	dealer = []
	computer_hands = []
	computer_results = []
	player_result = ""
	done = false
	for i in range(computer_count):
		computer_hands.append([])
		computer_results.append("")
	for i in range(2):
		player.append(CardTools.draw_card(deck))
		for hand in computer_hands:
			hand.append(CardTools.draw_card(deck))
		dealer.append(CardTools.draw_card(deck))
	player_hands = [player]
	active_hand_index = 0
	player_bets = [1]
	player_hand_results = [""]

func set_computer_count(count: int) -> void:
	computer_count = clamp(count, 0, 5)
	new_hand()

func hit() -> String:
	if done:
		return "Hand is already over."
	player.append(CardTools.draw_card(deck))
	if hand_value(player) > 21:
		return _finish_or_next_active("Bust. Coach tip: standing is usually correct on stiff totals when dealer shows a weak up-card.")
	return "You drew a card. Re-evaluate your total against the dealer up-card."

func stand() -> String:
	if done:
		return "Hand is already over."
	if _advance_split_hand("Stood on hand %d." % (active_hand_index + 1)):
		return "Now play split hand %d." % (active_hand_index + 1)
	return finish_table("Coach tip: compare your total to the dealer up-card, not just to 21.")

func double_down() -> String:
	if done:
		return "Hand is already over."
	if player.size() != 2:
		return "Double-down is only available on the first two cards of a hand."
	player_bets[active_hand_index] = int(player_bets[active_hand_index]) * 2
	player.append(CardTools.draw_card(deck))
	if hand_value(player) > 21:
		return _finish_or_next_active("Double-down drew one card and busted.")
	if _advance_split_hand("Doubled hand %d." % (active_hand_index + 1)):
		return "Double-down complete. Now play split hand %d." % (active_hand_index + 1)
	return finish_table("Double-down complete. You drew one card and stood.")

func split_pair() -> String:
	if done:
		return "Hand is already over."
	if player_hands.size() > 1:
		return "This trainer allows one split only."
	if not can_split():
		return "Split is only available when the first two cards have the same blackjack value."
	var first := [player[0], CardTools.draw_card(deck)]
	var second := [player[1], CardTools.draw_card(deck)]
	player_hands = [first, second]
	player_bets = [1, 1]
	player_hand_results = ["", ""]
	active_hand_index = 0
	player = player_hands[0]
	return "Split into two hands. Play hand 1 first."

func can_split() -> bool:
	return player_hands.size() == 1 and player.size() == 2 and _blackjack_card_value(player[0]) == _blackjack_card_value(player[1])

func can_double() -> bool:
	return not done and player.size() == 2

func finish_table(coach_tip: String) -> String:
	if done:
		return "Hand is already over."
	for hand in computer_hands:
		play_computer_hand(hand)
	while hand_value(dealer) < 17:
		dealer.append(CardTools.draw_card(deck))
	done = true
	player_hand_results = []
	for i in range(player_hands.size()):
		var result := outcome_for_hand(player_hands[i])
		player_hand_results.append(result)
		if result == "win":
			player_wins += int(player_bets[i])
		elif result == "push":
			pushes += int(player_bets[i])
		else:
			dealer_wins += int(player_bets[i])
	player_result = human_outcome_text()
	for i in range(computer_hands.size()):
		var result := outcome_for_hand(computer_hands[i])
		computer_results[i] = result
		if result == "win":
			computer_wins += 1
		elif result == "push":
			computer_pushes += 1
		else:
			computer_losses += 1
	return "%s %s" % [human_outcome_text(), coach_tip]

func play_computer_hand(hand: Array) -> void:
	while hand_value(hand) < computer_stand_value(hand):
		hand.append(CardTools.draw_card(deck))

func computer_stand_value(hand: Array) -> int:
	var dealer_up_value := hand_value([dealer[0]])
	if dealer_up_value >= 7:
		return 17
	return 12

func outcome_for_hand(hand: Array) -> String:
	var hand_total := hand_value(hand)
	var dealer_total := hand_value(dealer)
	if hand_total > 21:
		return "loss"
	if dealer_total > 21 or hand_total > dealer_total:
		return "win"
	if hand_total == dealer_total:
		return "push"
	return "loss"

func human_outcome_text() -> String:
	if player_hand_results.size() > 1:
		var parts := []
		for i in range(player_hand_results.size()):
			parts.append("hand %d %s for %d unit%s" % [
				i + 1,
				player_hand_results[i],
				int(player_bets[i]),
				"" if int(player_bets[i]) == 1 else "s"
			])
		return "Split result: %s." % CardTools.join_strings(parts, ", ")
	var result: String = str(player_hand_results[0]) if not player_hand_results.is_empty() else player_result
	match result:
		"win":
			return "You win."
		"push":
			return "Push."
	return "Dealer wins."

func reset_score() -> void:
	player_wins = 0
	dealer_wins = 0
	pushes = 0
	computer_wins = 0
	computer_losses = 0
	computer_pushes = 0

func score_text() -> String:
	return "You W-L-P: %d-%d-%d  Computers W-L-P: %d-%d-%d" % [
		player_wins,
		dealer_wins,
		pushes,
		computer_wins,
		computer_losses,
		computer_pushes
	]

func hand_value(hand: Array) -> int:
	var total := 0
	var aces := 0
	for card in hand:
		if card.rank == "A":
			total += 11
			aces += 1
		elif card.rank in ["K", "Q", "J"]:
			total += 10
		else:
			total += int(card.rank)
	while total > 21 and aces > 0:
		total -= 10
		aces -= 1
	return total

func visible_dealer_cards() -> Array:
	var cards := []
	for i in range(dealer.size()):
		cards.append(CardTools.card_text(dealer[i]))
	return cards

func player_cards_text() -> Array:
	return player.map(func(card): return CardTools.card_text(card))

func player_table_text() -> String:
	var parts := []
	for i in range(player_hands.size()):
		var active := " active" if i == active_hand_index and not done else ""
		var result := ""
		if done and i < player_hand_results.size():
			result = " - %s" % player_hand_results[i]
		parts.append("Hand %d%s: %s (%d), bet %d%s" % [
			i + 1,
			active,
			CardTools.cards_text(player_hands[i]),
			hand_value(player_hands[i]),
			int(player_bets[i]),
			result
		])
	return CardTools.join_strings(parts, "\n")

func dealer_value_text() -> String:
	if done:
		return str(hand_value(dealer))
	return "trainer view %d" % hand_value(dealer)

func basic_strategy_hint() -> String:
	if done:
		return StrategyText.review(
			"Dealer hand is complete.",
			"Review whether your hit, stand, split, or double-down choice matched the dealer up-card.",
			"Use doubles when one-card improvement is valuable; split only pairs with a clear plan."
		)
	var total := hand_value(player)
	var dealer_up := hand_value([dealer[0]])
	var soft := is_soft_hand(player)
	if can_split():
		if player[0].rank in ["A", "8"]:
			return StrategyText.advice(
				"Split the pair.",
				"Aces and eights are classic split hands: aces create two strong starts, while 16 is weak as one hand.",
				"After splitting, play each hand against the same dealer up-card."
			)
		if player[0].rank in ["10", "J", "Q", "K"]:
			return StrategyText.advice(
				"Do not split tens.",
				"Twenty is already a strong made hand.",
				"Splitting breaks a premium total into two uncertain hands."
			)
	if can_double() and total in [10, 11] and dealer_up <= 9:
		return StrategyText.advice(
			"Double down.",
			"A strong two-card total against dealer %s is a good one-card improvement spot." % CardTools.card_text(dealer[0]),
			"You will draw exactly one card and stand."
		)
	if total >= 17:
		if soft and total == 17:
			return StrategyText.advice(
				"Hit soft 17.",
				"The ace protects you from busting, and soft 17 is not a strong made hand.",
				"Full basic strategy may double some soft hands; this trainer uses hit/stand only."
			)
		return StrategyText.advice(
			"Stand on %d." % total,
			"You already have a made total against dealer %s." % CardTools.card_text(dealer[0]),
			"Hitting strong totals creates unnecessary bust risk."
		)
	if total <= 11:
		return StrategyText.advice(
			"Hit on %d." % total,
			"You cannot bust with one more card.",
			"In a full rules table, some of these spots would be doubles."
		)
	if soft:
		if total <= 17:
			return StrategyText.advice(
				"Hit soft %d." % total,
				"The ace can convert from 11 to 1, so the draw is protected.",
				"Stop treating it like a hard total; soft hands can improve aggressively."
			)
		return StrategyText.advice(
			"Stand on soft %d." % total,
			"It is already a playable total in this hit/stand trainer.",
			"Watch the dealer up-card; strong dealer cards reduce your margin."
		)
	if total >= 12 and total <= 16:
		if dealer_up >= 2 and dealer_up <= 6:
			return StrategyText.advice(
				"Stand on hard %d." % total,
				"Dealer shows %s, a weak up-card where dealer busts are common." % CardTools.card_text(dealer[0]),
				"Your job is to avoid busting first."
			)
		return StrategyText.advice(
			"Hit hard %d." % total,
			"Dealer shows %s, so standing on a stiff total usually loses too often." % CardTools.card_text(dealer[0]),
			"You may bust, but you probably need improvement."
		)
	return StrategyText.advice(
		"Hit.",
		"Totals below 17 usually need improvement in this simplified trainer.",
		"Full basic strategy has exceptions for doubling and pair splits."
	)

func is_soft_hand(hand: Array) -> bool:
	var total := 0
	var aces := 0
	for card in hand:
		if card.rank == "A":
			total += 11
			aces += 1
		elif card.rank in ["K", "Q", "J"]:
			total += 10
		else:
			total += int(card.rank)
	while total > 21 and aces > 0:
		total -= 10
		aces -= 1
	return aces > 0

func _advance_split_hand(message: String) -> bool:
	if player_hands.size() <= 1:
		return false
	player_hands[active_hand_index] = player
	player_hand_results[active_hand_index] = message
	if active_hand_index + 1 < player_hands.size():
		active_hand_index += 1
		player = player_hands[active_hand_index]
		return true
	return false

func _finish_or_next_active(message: String) -> String:
	if _advance_split_hand(message):
		return "%s Now play split hand %d." % [message, active_hand_index + 1]
	return finish_table(message)

func _blackjack_card_value(card: Dictionary) -> int:
	if card.rank == "A":
		return 11
	if card.rank in ["K", "Q", "J"]:
		return 10
	return int(card.rank)

func computer_summary_text() -> String:
	if computer_hands.is_empty():
		return "No computer seats."
	var lines := []
	for i in range(computer_hands.size()):
		var result := ""
		if done:
			result = " - %s" % computer_results[i]
		lines.append("Computer %d: %s (%d)%s" % [
			i + 1,
			CardTools.cards_text(computer_hands[i]),
			hand_value(computer_hands[i]),
			result
		])
	return CardTools.join_strings(lines, "\n")
