class_name TrickTakingModel
extends RefCounted

const CardTools := preload("res://scripts/core/card_tools.gd")
const OpponentPolicy := preload("res://scripts/core/opponent_policy.gd")
const StrategyText := preload("res://scripts/core/strategy_text.gd")

var mode := "spades"
var title := "Trick Taking"
var deck: Array = []
var hands: Array = []
var current_trick: Array = []
var last_trick: Array = []
var last_trick_winner := -1
var hand_tricks := [0, 0]
var match_scores := [0, 0]
var rounds_played := 0
var leader := 0
var turn := 0
var round_over := false
var trump_suit := ""
var hand_size := 13
var rules_summary := ""
var last_message := ""
var team_bids := [0, 0]
var team_bags := [0, 0]
var maker_team := 0
var alone_player := -1
var contract_team := 0
var contract_level := 1
var contract_suit := ""
var opponent_difficulty := OpponentPolicy.DEFAULT
var round_phase := "play"
var individual_bids := [0, 0, 0, 0]
var contract_options: Array = []
var selected_contract_option := 0

func set_difficulty(difficulty: String) -> void:
	opponent_difficulty = OpponentPolicy.normalize(difficulty)

func new_round(p_mode: String) -> void:
	mode = p_mode
	var config := _config_for(mode)
	title = config["title"]
	trump_suit = config["trump"]
	hand_size = config["hand_size"]
	rules_summary = config["rules"]
	deck = _make_mode_deck(config["ranks"])
	deck.shuffle()
	hands = [[], [], [], []]
	current_trick = []
	last_trick = []
	last_trick_winner = -1
	hand_tricks = [0, 0]
	round_over = false
	leader = 0
	turn = 0
	round_phase = "play"
	contract_options = []
	selected_contract_option = 0
	individual_bids = [0, 0, 0, 0]
	for i in range(hand_size * 4):
		hands[i % 4].append(deck[i])
	for hand in hands:
		hand.sort_custom(CardTools.sort_cards)
	_setup_contracts_after_deal()
	if is_waiting_for_player_contract():
		last_message = "New %s hand. Choose the contract before the opening lead." % title
	else:
		last_message = "New %s hand. You are South with North as partner." % title

func _make_mode_deck(ranks: Array) -> Array:
	var cards := []
	for suit in CardTools.SUITS:
		for rank in ranks:
			cards.append({"rank": rank, "suit": suit})
	return cards

func _config_for(p_mode: String) -> Dictionary:
	match p_mode:
		"euchre":
			var trump: String = str(CardTools.SUITS[randi() % CardTools.SUITS.size()])
			return {
				"title": "Euchre",
				"ranks": ["9", "10", "J", "Q", "K", "A"],
				"hand_size": 5,
				"trump": trump,
				"rules": "Euchre trainer: four players in two partnerships, 24-card deck, random trump, right and left bowers count as trump, follow suit when possible, and a simple maker team is estimated from trump strength. Going alone is automatic for very strong maker hands."
			}
		"bridge":
			return {
				"title": "Bridge Trainer",
				"ranks": CardTools.RANKS,
				"hand_size": 13,
				"trump": "",
				"rules": "Bridge trainer: four players in two partnerships with simplified contract suggestions from high-card points and suit fit. When You/North are favored, choose a contract before play begins. Follow suit and practice trick-reading, entries, and preserving high cards."
			}
		"whist":
			return {
				"title": "Whist",
				"ranks": CardTools.RANKS,
				"hand_size": 13,
				"trump": "",
				"rules": "Whist prototype: four players in two partnerships, full deck, no bidding, and follow suit when possible. This trainer focuses on trick reading, partner support, and preserving winners."
			}
		_:
			return {
				"title": "Spades",
				"ranks": CardTools.RANKS,
				"hand_size": 13,
				"trump": "S",
				"rules": "Spades trainer: four players in partnerships, spades are trump, follow suit when possible, and South chooses a visible bid after the other three seats estimate theirs. Overtricks count as bags; ten bags trigger a penalty."
			}

func legal_cards(player: int) -> Array:
	var hand: Array = hands[player]
	if current_trick.is_empty():
		return hand.duplicate()
	var lead_suit: String = effective_suit(current_trick[0]["card"])
	var matching: Array = []
	for card in hand:
		if effective_suit(card) == lead_suit:
			matching.append(card)
	return matching if not matching.is_empty() else hand.duplicate()

func play_player_card(card: Dictionary) -> String:
	if round_over or round_phase != "play" or turn != 0:
		return ""
	if not legal_cards(0).has(card):
		return "You must follow suit if you can."
	play_card(0, card)
	advance_bots()
	return ""

func advance_bots() -> void:
	if round_phase != "play":
		return
	while turn != 0 and not round_over:
		play_card(turn, pick_bot_card(turn))

func pick_bot_card(player: int) -> Dictionary:
	var legal := legal_cards(player)
	var scored := []
	for card in legal:
		scored.append({"item": card, "score": bot_choice_score(player, card)})
	return OpponentPolicy.pick_scored(scored, opponent_difficulty)

func bot_choice_score(player: int, card: Dictionary) -> float:
	if current_trick.is_empty():
		return -float(lead_score(card))
	var lead_suit: String = effective_suit(current_trick[0]["card"])
	var winning_power := current_winning_power(lead_suit)
	var winning_player := current_winning_player(lead_suit)
	var power := card_power(card, lead_suit)
	if team_for(winning_player) == team_for(player):
		if power <= winning_power:
			return -float(discard_score(card))
		return -100.0 - float(discard_score(card))
	if power > winning_power:
		return 1000.0 - float(power)
	return -float(discard_score(card))

func play_card(player: int, card: Dictionary) -> void:
	hands[player].erase(card)
	current_trick.append({"player": player, "card": card})
	if current_trick.size() == 4:
		score_trick()
	else:
		turn = (turn + 1) % 4

func score_trick() -> void:
	var lead_suit: String = effective_suit(current_trick[0]["card"])
	var winner: int = current_trick[0]["player"]
	var best_power := card_power(current_trick[0]["card"], lead_suit)
	for play in current_trick:
		var card: Dictionary = play["card"]
		var power := card_power(card, lead_suit)
		if power > best_power:
			best_power = power
			winner = play["player"]
	last_trick = current_trick.duplicate(true)
	last_trick_winner = winner
	hand_tricks[team_for(winner)] += 1
	leader = winner
	turn = winner
	current_trick = []
	if hands[0].is_empty():
		finish_round()

func card_power(card: Dictionary, lead_suit: String) -> int:
	if mode == "euchre" and _is_right_bower(card):
		return 200
	if mode == "euchre" and _is_left_bower(card):
		return 190
	if trump_suit != "" and effective_suit(card) == trump_suit:
		return 100 + CardTools.rank_value(card.rank)
	if effective_suit(card) == lead_suit:
		return CardTools.rank_value(card.rank)
	return 0

func finish_round() -> void:
	round_over = true
	rounds_played += 1
	match mode:
		"euchre":
			_score_euchre_round()
		"spades":
			_score_spades_round()
		"bridge":
			_score_bridge_round()
		_:
			match_scores[0] += hand_tricks[0]
			match_scores[1] += hand_tricks[1]
	last_message = "Round complete. Your team took %d trick%s; opponents took %d." % [
		hand_tricks[0],
		"" if hand_tricks[0] == 1 else "s",
		hand_tricks[1]
	]

func suggest_player_card() -> Dictionary:
	var legal := legal_cards(0)
	if legal.is_empty():
		return {}
	return suggest_card(0, legal)

func suggest_card(player: int, legal: Array) -> Dictionary:
	var sorted := legal.duplicate()
	if current_trick.is_empty():
		sorted.sort_custom(func(a, b): return lead_score(a) < lead_score(b))
		return sorted[0]
	var lead_suit: String = effective_suit(current_trick[0]["card"])
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
	var winning_cards := []
	for card in sorted:
		if card_power(card, lead_suit) > winning_power:
			winning_cards.append(card)
	if not winning_cards.is_empty():
		winning_cards.sort_custom(func(a, b): return card_power(a, lead_suit) < card_power(b, lead_suit))
		return winning_cards[0]
	sorted.sort_custom(func(a, b): return discard_score(a) < discard_score(b))
	return sorted[0]

func lead_score(card: Dictionary) -> int:
	var score := CardTools.rank_value(card.rank)
	if trump_suit != "" and effective_suit(card) == trump_suit:
		score += 20
	return score

func discard_score(card: Dictionary) -> int:
	var score := CardTools.rank_value(card.rank)
	if trump_suit != "" and effective_suit(card) == trump_suit:
		score += 40
	return score

func current_winning_power(lead_suit: String) -> int:
	var best := 0
	for play in current_trick:
		best = max(best, card_power(play["card"], lead_suit))
	return best

func current_winning_player(lead_suit: String) -> int:
	if current_trick.is_empty():
		return -1
	var winner: int = current_trick[0]["player"]
	var best := card_power(current_trick[0]["card"], lead_suit)
	for play in current_trick:
		var power := card_power(play["card"], lead_suit)
		if power > best:
			best = power
			winner = int(play["player"])
	return winner

func guidance_text() -> String:
	if is_waiting_for_player_contract():
		match mode:
			"spades":
				return StrategyText.advice(
					"Choose South's bid.",
					"North, West, and East already estimated their bids. Set a realistic team target that matches your spade length and outside winners.",
					"Bidding too high creates set risk; bidding too low turns winners into bags."
				)
			"bridge":
				return StrategyText.advice(
					"Choose a contract for You/North.",
					"The options are derived from combined high-card points and long-suit fit. Pick the smallest contract you expect to make consistently.",
					"A safer partscore teaches suit establishment; a higher contract tests whether the hand has enough entries and control."
				)
	if round_over:
		return StrategyText.advice(
			"Start another hand.",
			"Trick-taking improvement comes from reviewing which team won each suit and who became void.",
			"Compare team trick totals before resetting."
		)
	if turn != 0:
		return StrategyText.advice(
			"Watch the current trick resolve.",
			"Every play reveals who can follow suit and who may be void.",
			"Void players can trump or discard strategically on future tricks."
		)
	var suggestion := suggest_player_card()
	if suggestion.is_empty():
		return StrategyText.advice("No legal card available.")
	if current_trick.is_empty():
		return StrategyText.advice(
			"Lead %s." % CardTools.card_text(suggestion),
			"A low non-trump lead preserves winners while you learn the suit layout.",
			"Notice whether opponents can follow the led suit.",
			"Before leading, name one card you are trying to protect."
		)
	var lead_suit: String = effective_suit(current_trick[0]["card"])
	var winning_player := current_winning_player(lead_suit)
	if team_for(winning_player) == team_for(0):
		return StrategyText.advice(
			"Play %s." % CardTools.card_text(suggestion),
			"Your team is already winning the trick, so avoid wasting a higher winner.",
			"Only overtake partner when it wins important tempo or protects against trump.",
			"Track who is currently winning before choosing a card."
		)
	if card_power(suggestion, lead_suit) > current_winning_power(lead_suit):
		return StrategyText.advice(
			"Play %s." % CardTools.card_text(suggestion),
			"This is the smallest legal card that can take the trick.",
			"Winning cheaply keeps stronger cards for later.",
			"Compare card power, not just rank, because trump changes the order."
		)
	return StrategyText.advice(
		"Play %s." % CardTools.card_text(suggestion),
		"You cannot win cheaply, so discard low and avoid spending trump without a reason.",
		"Save trump and high cards for tricks with points or control value.",
		"Mark this suit as dangerous if you are void."
	)

func status_text() -> String:
	if is_waiting_for_player_contract():
		match mode:
			"spades":
				return "Bid before play starts."
			"bridge":
				return "Choose the contract before the opening lead."
	if round_over:
		return last_message
	return "Your turn." if turn == 0 else "%s is playing." % player_name(turn)

func table_text() -> String:
	var trick_parts := []
	for play in current_trick:
		trick_parts.append("%s %s" % [player_name(play["player"]), CardTools.card_text(play["card"])])
	var trump_text := "No trump" if trump_suit == "" else "Trump: %s" % trump_suit
	return "%s | %s | %s\nCurrent trick: %s\nLast trick: %s" % [
		title,
		trump_text,
		_contract_text(),
		CardTools.join_strings(trick_parts, " | "),
		last_trick_text()
	]

func score_text() -> String:
	return "Team score - You/North: %d  West/East: %d\nThis hand - You/North: %d  West/East: %d\n%s\nRounds: %d" % [
		match_scores[0],
		match_scores[1],
		hand_tricks[0],
		hand_tricks[1],
		_contract_text(),
		rounds_played
	]

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
	team_bags = [0, 0]
	rounds_played = 0

func is_waiting_for_player_contract() -> bool:
	return round_phase == "contract"

func contract_option_labels() -> Array:
	var labels := []
	for option in contract_options:
		labels.append(str(option.get("label", "")))
	return labels

func select_contract_option(index: int) -> void:
	selected_contract_option = clamp(index, 0, max(0, contract_options.size() - 1))

func confirm_contract_selection() -> String:
	if not is_waiting_for_player_contract() or contract_options.is_empty():
		return ""
	var option: Dictionary = contract_options[selected_contract_option]
	match mode:
		"spades":
			individual_bids[0] = int(option["bid"])
			team_bids[0] = int(individual_bids[0]) + int(individual_bids[2])
			round_phase = "play"
			last_message = "South bids %d. Team target is now %d tricks." % [individual_bids[0], team_bids[0]]
		"bridge":
			contract_team = 0
			contract_level = int(option["level"])
			contract_suit = str(option["suit"])
			round_phase = "play"
			last_message = "You/North choose %d%s." % [contract_level, contract_suit]
		_:
			round_phase = "play"
	return last_message

func effective_suit(card: Dictionary) -> String:
	if mode == "euchre" and _is_left_bower(card):
		return trump_suit
	return str(card.suit)

func _setup_contracts_after_deal() -> void:
	team_bids = [0, 0]
	individual_bids = [0, 0, 0, 0]
	maker_team = 0
	alone_player = -1
	contract_team = 0
	contract_level = 1
	contract_suit = trump_suit
	match mode:
		"spades":
			for player in range(1, 4):
				individual_bids[player] = _estimate_spades_bid(player)
			team_bids[1] = int(individual_bids[1]) + int(individual_bids[3])
			contract_options = _spades_bid_options()
			selected_contract_option = _recommended_spades_option_index()
			round_phase = "contract"
		"euchre":
			var best_player := 0
			var best_strength := -1
			for player in range(4):
				var strength := _trump_strength(player)
				if strength > best_strength:
					best_strength = strength
					best_player = player
			maker_team = team_for(best_player)
			alone_player = best_player if best_strength >= 5 else -1
			round_phase = "play"
		"bridge":
			var team_hcp := [_high_card_points(0) + _high_card_points(2), _high_card_points(1) + _high_card_points(3)]
			contract_team = 0 if int(team_hcp[0]) >= int(team_hcp[1]) else 1
			contract_level = clamp(int(floor(float(team_hcp[contract_team]) / 3.5)) - 5, 1, 7)
			contract_suit = _longest_team_suit(contract_team)
			if contract_team == 0:
				contract_options = _bridge_contract_options(team_hcp[0])
				selected_contract_option = _recommended_bridge_option_index()
				round_phase = "contract"
			else:
				round_phase = "play"
		_:
			round_phase = "play"

func _score_spades_round() -> void:
	for team in range(2):
		var bid: int = max(1, int(team_bids[team]))
		var tricks: int = int(hand_tricks[team])
		if tricks >= bid:
			var bags: int = tricks - bid
			match_scores[team] += bid * 10 + bags
			team_bags[team] += bags
			if team_bags[team] >= 10:
				match_scores[team] -= 100
				team_bags[team] -= 10
		else:
			match_scores[team] -= bid * 10

func _score_bridge_round() -> void:
	var target := contract_level + 6
	var tricks := int(hand_tricks[contract_team])
	if tricks >= target:
		match_scores[contract_team] += 20 * contract_level + (tricks - target)
	else:
		match_scores[contract_team] -= 50 * (target - tricks)
	var defender := 1 - contract_team
	match_scores[defender] += int(hand_tricks[defender])

func _score_euchre_round() -> void:
	var maker_tricks := int(hand_tricks[maker_team])
	var defender := 1 - maker_team
	if maker_tricks >= 5:
		match_scores[maker_team] += 4 if alone_player >= 0 else 2
	elif maker_tricks >= 3:
		match_scores[maker_team] += 1
	else:
		match_scores[defender] += 2

func _estimate_spades_bid(player: int) -> int:
	var bid := 0
	for card in hands[player]:
		if card.suit == "S" and CardTools.rank_value(card.rank) >= 10:
			bid += 1
		elif CardTools.rank_value(card.rank) >= 13:
			bid += 1
	return max(1, bid)

func _trump_strength(player: int) -> int:
	var strength := 0
	for card in hands[player]:
		if effective_suit(card) == trump_suit:
			strength += 1
			if card.rank in ["A", "K", "Q", "J"]:
				strength += 1
	return strength

func _high_card_points(player: int) -> int:
	var points := 0
	for card in hands[player]:
		match card.rank:
			"A":
				points += 4
			"K":
				points += 3
			"Q":
				points += 2
			"J":
				points += 1
	return points

func _longest_team_suit(team: int) -> String:
	var counts := {"S": 0, "H": 0, "D": 0, "C": 0}
	for player in range(4):
		if team_for(player) != team:
			continue
		for card in hands[player]:
			counts[card.suit] = int(counts.get(card.suit, 0)) + 1
	var best_suit := "NT"
	var best_count := 0
	for suit in CardTools.SUITS:
		if int(counts[suit]) > best_count:
			best_count = int(counts[suit])
			best_suit = suit
	return best_suit

func _contract_text() -> String:
	match mode:
		"spades":
			if is_waiting_for_player_contract():
				return "Bids South ?, North %d, West %d, East %d" % [individual_bids[2], individual_bids[1], individual_bids[3]]
			return "Bids You/North %d, West/East %d | Bags %d-%d" % [team_bids[0], team_bids[1], team_bags[0], team_bags[1]]
		"euchre":
			var alone := " alone by %s" % player_name(alone_player) if alone_player >= 0 else ""
			return "Maker: %s%s" % ["You/North" if maker_team == 0 else "West/East", alone]
		"bridge":
			if is_waiting_for_player_contract():
				return "Auction favorite: You/North | choose a contract"
			return "Contract: %s %d%s" % ["You/North" if contract_team == 0 else "West/East", contract_level, contract_suit]
	return "Trick points"

func _spades_bid_options() -> Array:
	var recommended: int = _estimate_spades_bid(0)
	var min_bid: int = max(1, recommended - 1)
	var max_bid: int = min(7, recommended + 2)
	var options := []
	for bid in range(min_bid, max_bid + 1):
		options.append({
			"label": "Bid %d" % bid,
			"bid": bid,
		})
	return options

func _recommended_spades_option_index() -> int:
	var recommended := _estimate_spades_bid(0)
	for i in range(contract_options.size()):
		if int(contract_options[i]["bid"]) == recommended:
			return i
	return 0

func _bridge_contract_options(team_hcp: int) -> Array:
	var suit: String = _longest_team_suit(0)
	var base_level: int = clamp(int(floor(float(team_hcp) / 3.5)) - 5, 1, 7)
	var options := []
	var seen := {}
	for choice in [
		{"level": max(1, base_level - 1), "suit": suit},
		{"level": base_level, "suit": "NT" if team_hcp >= 25 else suit},
		{"level": min(7, base_level + 1), "suit": suit},
	]:
		var key := "%d%s" % [int(choice["level"]), str(choice["suit"])]
		if seen.has(key):
			continue
		seen[key] = true
		options.append({
			"label": "%d%s" % [int(choice["level"]), str(choice["suit"])],
			"level": int(choice["level"]),
			"suit": str(choice["suit"]),
		})
	return options

func _recommended_bridge_option_index() -> int:
	for i in range(contract_options.size()):
		if str(contract_options[i]["suit"]) == contract_suit and int(contract_options[i]["level"]) == contract_level:
			return i
	return 0

func _is_right_bower(card: Dictionary) -> bool:
	return mode == "euchre" and card.rank == "J" and card.suit == trump_suit

func _is_left_bower(card: Dictionary) -> bool:
	if mode != "euchre" or card.rank != "J" or card.suit == trump_suit:
		return false
	return _same_color_suit(card.suit) == trump_suit

func _same_color_suit(suit: String) -> String:
	match suit:
		"S":
			return "C"
		"C":
			return "S"
		"H":
			return "D"
		"D":
			return "H"
	return suit

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
