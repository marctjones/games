class_name HeartsModel
extends RefCounted

const CardTools := preload("res://scripts/core/card_tools.gd")
const StrategyText := preload("res://scripts/core/strategy_text.gd")

var deck: Array = []
var hands: Array = []
var current_trick: Array = []
var last_trick: Array = []
var last_trick_winner := -1
var last_trick_penalty := 0
var scores := [0, 0, 0, 0]
var match_scores := [0, 0, 0, 0]
var rounds_played := 0
var round_scored := false
var leader := 0
var turn := 0
var round_over := false
var pass_direction := "left"
var pass_summary := ""

func new_round() -> void:
	deck = CardTools.make_deck()
	hands = [[], [], [], []]
	scores = [0, 0, 0, 0]
	current_trick = []
	last_trick = []
	last_trick_winner = -1
	last_trick_penalty = 0
	round_over = false
	round_scored = false
	for i in range(52):
		hands[i % 4].append(deck[i])
	for hand in hands:
		hand.sort_custom(CardTools.sort_cards)
	_apply_passing()
	leader = find_two_clubs()
	turn = leader

func find_two_clubs() -> int:
	for player in range(4):
		for card in hands[player]:
			if card.rank == "2" and card.suit == "C":
				return player
	return 0

func advance_bots() -> void:
	while turn != 0 and not round_over:
		var card := pick_bot_card(turn)
		play_card(turn, card)

func pick_bot_card(player: int) -> Dictionary:
	var legal := legal_cards(player)
	legal.sort_custom(func(a, b): return bot_card_score(a) > bot_card_score(b))
	return legal[0]

func bot_card_score(card: Dictionary) -> int:
	var score := CardTools.rank_value(card.rank)
	if card.suit == "H":
		score += 30
	if card.suit == "S" and card.rank == "Q":
		score += 80
	if current_trick.is_empty():
		score = -score
	return score

func legal_cards(player: int) -> Array:
	var hand: Array = hands[player]
	if current_trick.is_empty():
		return hand.duplicate()
	var lead_suit: String = current_trick[0]["card"].suit
	var matching: Array = []
	for card in hand:
		if card.suit == lead_suit:
			matching.append(card)
	return matching if not matching.is_empty() else hand.duplicate()

func play_player_card(card: Dictionary) -> String:
	if round_over or turn != 0:
		return ""
	if not legal_cards(0).has(card):
		return "You must follow suit if you can."
	play_card(0, card)
	advance_bots()
	return ""

func play_card(player: int, card: Dictionary) -> void:
	hands[player].erase(card)
	current_trick.append({"player": player, "card": card})
	if current_trick.size() == 4:
		score_trick()
	else:
		turn = (turn + 1) % 4

func score_trick() -> void:
	var lead_suit: String = current_trick[0]["card"].suit
	var winner: int = current_trick[0]["player"]
	var winning_rank := CardTools.rank_value(current_trick[0]["card"].rank)
	var penalty := 0
	for play in current_trick:
		var card: Dictionary = play["card"]
		if card.suit == "H":
			penalty += 1
		elif card.suit == "S" and card.rank == "Q":
			penalty += 13
		if card.suit == lead_suit and CardTools.rank_value(card.rank) > winning_rank:
			winning_rank = CardTools.rank_value(card.rank)
			winner = play["player"]
	last_trick = current_trick.duplicate(true)
	last_trick_winner = winner
	last_trick_penalty = penalty
	scores[winner] += penalty
	leader = winner
	turn = winner
	current_trick = []
	if hands[0].is_empty():
		round_over = true
		finish_round()

func finish_round() -> void:
	if round_scored:
		return
	round_scored = true
	rounds_played += 1
	for i in range(4):
		match_scores[i] += scores[i]

func reset_score() -> void:
	match_scores = [0, 0, 0, 0]
	rounds_played = 0

func _apply_passing() -> void:
	var cycle := rounds_played % 4
	match cycle:
		0:
			pass_direction = "left"
		1:
			pass_direction = "right"
		2:
			pass_direction = "across"
		_:
			pass_direction = "hold"
	if pass_direction == "hold":
		pass_summary = "No pass this round."
		return
	var offsets := {"left": 1, "right": 3, "across": 2}
	var outgoing := [[], [], [], []]
	for player in range(4):
		outgoing[player] = _choose_pass_cards(hands[player])
		for card in outgoing[player]:
			hands[player].erase(card)
	for player in range(4):
		var target := (player + int(offsets[pass_direction])) % 4
		for card in outgoing[player]:
			hands[target].append(card)
	for hand in hands:
		hand.sort_custom(CardTools.sort_cards)
	pass_summary = "Passed 3 cards %s. Your pass: %s." % [pass_direction, CardTools.cards_text(outgoing[0])]

func _choose_pass_cards(hand: Array) -> Array:
	var sorted := hand.duplicate()
	sorted.sort_custom(func(a, b): return hearts_risk_score(a) > hearts_risk_score(b))
	return sorted.slice(0, min(3, sorted.size()))

func table_text() -> String:
	var trick_text := []
	for play in current_trick:
		trick_text.append("%s: %s" % [player_name(play["player"]), CardTools.card_text(play["card"])])
	var score_text := "Scores - You: %d, West: %d, North: %d, East: %d" % [scores[0], scores[1], scores[2], scores[3]]
	return "%s\nPassing: %s\nCurrent trick: %s\nLast trick: %s\nTurn: %s" % [score_text, pass_summary, CardTools.join_strings(trick_text, " | "), last_trick_text(), player_name(turn)]

func match_score_text() -> String:
	return "Match - You: %d  West: %d  North: %d  East: %d  Rounds: %d" % [match_scores[0], match_scores[1], match_scores[2], match_scores[3], rounds_played]

func last_trick_text() -> String:
	if last_trick.is_empty():
		return "none"
	var parts := []
	for play in last_trick:
		parts.append("%s %s" % [player_name(play["player"]), CardTools.card_text(play["card"])])
	return "%s won by %s for %d point%s" % [
		CardTools.join_strings(parts, " | "),
		player_name(last_trick_winner),
		last_trick_penalty,
		"" if last_trick_penalty == 1 else "s"
	]

func status_text() -> String:
	if round_over:
		return "Round over. Lowest score wins this round: %s. Coach tip: avoid taking hearts and especially the queen of spades." % player_name(round_winner())
	return "Play a legal card. Coach tip: when void in a suit, discard dangerous penalty cards."

func player_guidance_text() -> String:
	if round_over:
		return StrategyText.advice(
			"Start the next round after review.",
			"Lowest score wins, so the key review is which tricks collected hearts or the queen of spades.",
			"Compare match score and this round's penalty spread."
		)
	if turn != 0:
		return StrategyText.advice(
			"Watch the trick resolve.",
			"Hearts is about avoiding the trick that contains penalty cards, not just avoiding high cards.",
			"Players who cannot follow suit can dump hearts or the queen of spades."
		)
	var legal := legal_cards(0)
	if legal.is_empty():
		return StrategyText.advice("No legal cards available.")
	var suggested := suggest_player_card(legal)
	var penalty := _current_penalty_points()
	if current_trick.is_empty():
		return StrategyText.advice(
			"Lead %s." % CardTools.card_text(suggested),
			"Leading a lower non-penalty card usually limits the chance that you take points.",
			"%s High spades can become dangerous while the queen of spades is still out." % pass_summary,
			"Before leading, identify your safest low suit."
		)
	if _has_led_suit(0):
		var lead_suit: String = current_trick[0]["card"].suit
		var winning_rank := _current_winning_rank(lead_suit)
		return StrategyText.advice(
			"Play %s." % CardTools.card_text(suggested),
			"Following suit below the current winner avoids taking %d penalty point%s." % [penalty, "" if penalty == 1 else "s"],
			"Current winning rank in %s is %d; if you cannot duck, spend the lowest legal card." % [lead_suit, winning_rank],
			"Try to name whether the suggested card ducks or sacrifices."
		)
	return StrategyText.advice(
		"Play %s." % CardTools.card_text(suggested),
		"You are void in the led suit, so this is a chance to unload penalty risk.",
		"Hearts are 1 point each; QS is 13 points and should be dumped when safe.",
		"Track which suit you became void in."
	)

func suggest_player_card(legal: Array) -> Dictionary:
	var sorted := legal.duplicate()
	if current_trick.is_empty():
		sorted.sort_custom(func(a, b): return hearts_risk_score(a) < hearts_risk_score(b))
		return sorted[0]
	var lead_suit: String = current_trick[0]["card"].suit
	if _has_led_suit(0):
		var winning_rank := _current_winning_rank(lead_suit)
		var safe_cards := []
		for card in sorted:
			if CardTools.rank_value(card.rank) < winning_rank:
				safe_cards.append(card)
		if not safe_cards.is_empty():
			safe_cards.sort_custom(func(a, b): return CardTools.rank_value(a.rank) > CardTools.rank_value(b.rank))
			return safe_cards[0]
		sorted.sort_custom(func(a, b): return CardTools.rank_value(a.rank) < CardTools.rank_value(b.rank))
		return sorted[0]
	sorted.sort_custom(func(a, b): return hearts_risk_score(a) > hearts_risk_score(b))
	return sorted[0]

func hearts_risk_score(card: Dictionary) -> int:
	var score := CardTools.rank_value(card.rank)
	if card.suit == "H":
		score += 30
	if card.suit == "S" and card.rank == "Q":
		score += 90
	return score

func _has_led_suit(player: int) -> bool:
	if current_trick.is_empty():
		return false
	var lead_suit: String = current_trick[0]["card"].suit
	for card in hands[player]:
		if card.suit == lead_suit:
			return true
	return false

func _current_winning_rank(lead_suit: String) -> int:
	var rank := 0
	for play in current_trick:
		var card: Dictionary = play["card"]
		if card.suit == lead_suit:
			rank = max(rank, CardTools.rank_value(card.rank))
	return rank

func _current_penalty_points() -> int:
	var penalty := 0
	for play in current_trick:
		var card: Dictionary = play["card"]
		if card.suit == "H":
			penalty += 1
		elif card.suit == "S" and card.rank == "Q":
			penalty += 13
	return penalty

func round_winner() -> int:
	var winner := 0
	var best: int = scores[0]
	for i in range(4):
		if scores[i] < best:
			best = scores[i]
			winner = i
	return winner

static func player_name(player: int) -> String:
	match player:
		0:
			return "You"
		1:
			return "West"
		2:
			return "North"
		3:
			return "East"
	return "Player %d" % player
