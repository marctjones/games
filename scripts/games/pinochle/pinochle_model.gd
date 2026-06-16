class_name PinochleModel
extends "res://scripts/games/trick_taking/trick_taking_model.gd"

const RANKS := ["9", "J", "Q", "K", "10", "A"]

var hand_points := [0, 0]
var team_meld_points := [0, 0]
var pinochle_bids := [20, 20]

func new_round(p_mode: String = "pinochle") -> void:
	mode = p_mode
	title = "Pinochle"
	hand_size = 12
	rules_summary = "Pinochle prototype: four players in partnerships, 48-card double deck from 9 through ace, random trump, and trick points for aces, tens, and kings. Bidding, meld scoring, and full Pinochle obligations are reserved for the next deeper rules pass."
	deck = make_deck()
	deck.shuffle()
	hands = [[], [], [], []]
	current_trick = []
	last_trick = []
	last_trick_winner = -1
	hand_points = [0, 0]
	team_meld_points = [0, 0]
	pinochle_bids = [20, 20]
	round_over = false
	trump_suit = str(CardTools.SUITS[randi() % CardTools.SUITS.size()])
	leader = 0
	turn = 0
	for i in range(48):
		hands[i % 4].append(deck[i])
	for hand in hands:
		hand.sort_custom(func(a, b): return pinochle_sort(a, b))
	team_meld_points = [meld_score_for_team(0), meld_score_for_team(1)]
	pinochle_bids = [max(20, team_meld_points[0] + 8), max(20, team_meld_points[1] + 8)]
	rules_summary = "Pinochle trainer: four players in partnerships, 48-card double deck, random trump, trick points for aces/tens/kings, and simplified meld/bid scoring. Meld includes marriages, trump marriage, arounds, and pinochle."
	last_message = "New Pinochle hand. Trump is %s. Meld/bid targets are active." % trump_suit

func make_deck() -> Array:
	var cards := []
	for copy in range(2):
		for suit in CardTools.SUITS:
			for rank in RANKS:
				cards.append({"rank": rank, "suit": suit})
	return cards

func pinochle_sort(a: Dictionary, b: Dictionary) -> bool:
	if a.suit == b.suit:
		return rank_power(a.rank) < rank_power(b.rank)
	return CardTools.SUITS.find(a.suit) < CardTools.SUITS.find(b.suit)

func rank_power(rank: String) -> int:
	match rank:
		"A":
			return 6
		"10":
			return 5
		"K":
			return 4
		"Q":
			return 3
		"J":
			return 2
	return 1

func card_points(card: Dictionary) -> int:
	if card.rank in ["A", "10", "K"]:
		return 1
	return 0

func legal_cards(player: int) -> Array:
	var hand: Array = hands[player]
	if current_trick.is_empty():
		return hand.duplicate()
	var lead_suit: String = current_trick[0]["card"].suit
	var matching := []
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

func advance_bots() -> void:
	while turn != 0 and not round_over:
		play_card(turn, suggest_card(turn, legal_cards(turn)))

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
	var best_power := card_power(current_trick[0]["card"], lead_suit)
	var points := 0
	for play in current_trick:
		var card: Dictionary = play["card"]
		points += card_points(card)
		var power := card_power(card, lead_suit)
		if power > best_power:
			best_power = power
			winner = play["player"]
	last_trick = current_trick.duplicate(true)
	last_trick_winner = winner
	hand_points[team_for(winner)] += points
	leader = winner
	turn = winner
	current_trick = []
	if hands[0].is_empty():
		finish_round()

func card_power(card: Dictionary, lead_suit: String) -> int:
	if card.suit == trump_suit:
		return 100 + rank_power(card.rank)
	if card.suit == lead_suit:
		return rank_power(card.rank)
	return 0

func finish_round() -> void:
	round_over = true
	rounds_played += 1
	for team in range(2):
		var total: int = int(hand_points[team]) + int(team_meld_points[team])
		if total >= int(pinochle_bids[team]):
			match_scores[team] += total
		else:
			match_scores[team] -= int(pinochle_bids[team])
	last_message = "Round complete. Your team scored %d trick plus %d meld; opponents scored %d trick plus %d meld." % [
		hand_points[0],
		team_meld_points[0],
		hand_points[1],
		team_meld_points[1]
	]

func suggest_player_card() -> Dictionary:
	return suggest_card(0, legal_cards(0))

func suggest_card(player: int, legal: Array) -> Dictionary:
	if legal.is_empty():
		return {}
	var sorted := legal.duplicate()
	if current_trick.is_empty():
		sorted.sort_custom(func(a, b): return lead_score(a) < lead_score(b))
		return sorted[0]
	var lead_suit: String = current_trick[0]["card"].suit
	var winning_power := current_winning_power(lead_suit)
	var winning_player := current_winning_player(lead_suit)
	if team_for(winning_player) == team_for(player):
		var non_overtaking := []
		for card in sorted:
			if card_power(card, lead_suit) <= winning_power:
				non_overtaking.append(card)
		if not non_overtaking.is_empty():
			non_overtaking.sort_custom(func(a, b): return discard_score(a) < discard_score(b))
			return non_overtaking[0]
	var winners := []
	for card in sorted:
		if card_power(card, lead_suit) > winning_power:
			winners.append(card)
	if not winners.is_empty():
		winners.sort_custom(func(a, b): return card_power(a, lead_suit) < card_power(b, lead_suit))
		return winners[0]
	sorted.sort_custom(func(a, b): return discard_score(a) < discard_score(b))
	return sorted[0]

func lead_score(card: Dictionary) -> int:
	var score := rank_power(card.rank)
	if card.suit == trump_suit:
		score += 20
	if card_points(card) > 0:
		score += 6
	return score

func discard_score(card: Dictionary) -> int:
	var score := rank_power(card.rank)
	if card.suit == trump_suit:
		score += 30
	if card_points(card) > 0:
		score += 10
	return score

func current_winning_power(lead_suit: String) -> int:
	var best := 0
	for play in current_trick:
		best = max(best, card_power(play["card"], lead_suit))
	return best

func guidance_text() -> String:
	if round_over:
		return StrategyText.advice(
			"Start the next hand after review.",
			"Pinochle score now combines meld, trick points, and whether the team met its bid.",
			"Compare bid target against meld plus captured aces, tens, and kings."
		)
	if turn != 0:
		return StrategyText.advice(
			"Watch the trick resolve.",
			"Track trump and point cards: aces, tens, and kings.",
			"Notice whether a player spends trump to capture points."
		)
	var suggestion := suggest_player_card()
	if suggestion.is_empty():
		return StrategyText.advice("No legal cards available.")
	if current_trick.is_empty():
		return StrategyText.advice(
			"Lead %s." % CardTools.card_text(suggestion),
			"Save trump and point cards unless you can control the trick; your team bid is %d." % pinochle_bids[0],
			"Low non-point leads reveal suit strength without giving away aces, tens, or kings.",
			"Before leading, count your trump."
		)
	var lead_suit: String = current_trick[0]["card"].suit
	var winning_player := current_winning_player(lead_suit)
	var point_text := "%d point card%s currently in the trick" % [_current_trick_points(), "" if _current_trick_points() == 1 else "s"]
	if team_for(winning_player) == team_for(0):
		return StrategyText.advice(
			"Play %s." % CardTools.card_text(suggestion),
			"Your team is already winning, so avoid overtaking partner.",
			"Protect trump and point cards unless they secure more points.",
			point_text
		)
	if card_power(suggestion, lead_suit) > current_winning_power(lead_suit):
		return StrategyText.advice(
			"Play %s." % CardTools.card_text(suggestion),
			"It is the cheapest card that can take the trick.",
			"Winning matters more when %s." % point_text,
			"Compare trump power before comparing rank."
		)
	return StrategyText.advice(
		"Play %s." % CardTools.card_text(suggestion),
		"You cannot win cheaply, so discard low and preserve trump.",
		"Do not donate aces, tens, or kings unless the trick is already lost.",
		point_text
	)

func _current_trick_points() -> int:
	var points := 0
	for play in current_trick:
		points += card_points(play["card"])
	return points

func status_text() -> String:
	if round_over:
		return last_message
	return "Your turn." if turn == 0 else "%s is playing." % player_name(turn)

func table_text() -> String:
	var trick_parts := []
	for play in current_trick:
		trick_parts.append("%s %s" % [player_name(play["player"]), CardTools.card_text(play["card"])])
	return "Pinochle | Trump: %s | Bid You/North %d, West/East %d | Meld %d-%d\nCurrent trick: %s\nLast trick: %s" % [
		trump_suit,
		pinochle_bids[0],
		pinochle_bids[1],
		team_meld_points[0],
		team_meld_points[1],
		CardTools.join_strings(trick_parts, " | "),
		last_trick_text()
	]

func score_text() -> String:
	return "Team score - You/North: %d  West/East: %d\nBid - You/North: %d  West/East: %d\nThis hand trick/meld - You/North: %d/%d  West/East: %d/%d\nRounds: %d" % [
		match_scores[0],
		match_scores[1],
		pinochle_bids[0],
		pinochle_bids[1],
		hand_points[0],
		team_meld_points[0],
		hand_points[1],
		team_meld_points[1],
		rounds_played
	]

func meld_score_for_team(team: int) -> int:
	var total := 0
	for player in range(4):
		if team_for(player) == team:
			total += meld_score_for_hand(hands[player])
	return total

func meld_score_for_hand(hand: Array) -> int:
	var counts := {}
	for card in hand:
		var name := "%s%s" % [card.rank, card.suit]
		counts[name] = int(counts.get(name, 0)) + 1
	var score := 0
	for suit in CardTools.SUITS:
		var marriage_count: int = min(int(counts.get("K%s" % suit, 0)), int(counts.get("Q%s" % suit, 0)))
		if suit == trump_suit:
			score += marriage_count * 4
		else:
			score += marriage_count * 2
	for rank in ["A", "K", "Q", "J"]:
		var around_count := 99
		for suit in CardTools.SUITS:
			around_count = min(around_count, int(counts.get("%s%s" % [rank, suit], 0)))
		if around_count < 99:
			var around_value := 10 if rank == "A" else 8 if rank == "K" else 6 if rank == "Q" else 4
			score += around_count * around_value
	var pinochle_count: int = min(int(counts.get("QS", 0)), int(counts.get("JD", 0)))
	score += pinochle_count * 4
	return score

func last_trick_text() -> String:
	if last_trick.is_empty():
		return "none"
	var parts := []
	for play in last_trick:
		parts.append("%s %s" % [player_name(play["player"]), CardTools.card_text(play["card"])])
	return "%s won by %s" % [CardTools.join_strings(parts, " | "), player_name(last_trick_winner)]

func team_for(player: int) -> int:
	return 0 if player == 0 or player == 2 else 1

func reset_score() -> void:
	match_scores = [0, 0]
	rounds_played = 0

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
