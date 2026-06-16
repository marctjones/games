class_name CanastaModel
extends RefCounted

const CardTools := preload("res://scripts/core/card_tools.gd")
const StrategyText := preload("res://scripts/core/strategy_text.gd")

var deck: Array = []
var discard: Array = []
var player: Array = []
var bot: Array = []
var selected: Array = []
var player_melds: Array = []
var bot_melds: Array = []
var phase := "draw"
var done := false
var last_message := ""
var last_bot_action := ""
var player_score := 0
var computer_score := 0
var hands_played := 0
var player_red_threes := 0
var bot_red_threes := 0

func new_hand() -> void:
	deck = make_canasta_deck()
	deck.shuffle()
	discard = []
	player = []
	bot = []
	selected = []
	player_melds = []
	bot_melds = []
	player_red_threes = 0
	bot_red_threes = 0
	phase = "draw"
	done = false
	last_bot_action = "Computer has not moved yet."
	for i in range(11):
		player.append(draw_card())
		bot.append(draw_card())
	discard.append(draw_card())
	_handle_red_threes(player, true)
	_handle_red_threes(bot, false)
	_sort_hands()
	last_message = "Draw from stock or take the discard, meld same-rank sets with wild twos, then discard."

func make_canasta_deck() -> Array:
	var cards := []
	for copy in range(2):
		for suit in CardTools.SUITS:
			for rank in CardTools.RANKS:
				cards.append({"rank": rank, "suit": suit})
	return cards

func draw_card() -> Dictionary:
	if deck.is_empty() and discard.size() > 1:
		var top: Dictionary = discard.pop_back()
		while not discard.is_empty():
			deck.append(discard.pop_back())
		deck.shuffle()
		discard.append(top)
	if deck.is_empty():
		return {}
	return CardTools.draw_card(deck)

func draw_stock() -> void:
	if phase != "draw" or done:
		return
	var first := draw_card()
	if first.size() > 0:
		player.append(first)
	var second := draw_card()
	if second.size() > 0:
		player.append(second)
	_handle_red_threes(player, true)
	_sort_hands()
	phase = "act"
	last_message = "Drew two cards from stock. Meld if possible, then discard one card."

func draw_discard() -> void:
	if phase != "draw" or discard.is_empty() or done or not can_take_discard(player):
		return
	player.append(discard.pop_back())
	_handle_red_threes(player, true)
	_sort_hands()
	phase = "act"
	last_message = "Took the discard. Try to use it in a same-rank meld, then discard."

func toggle_selected(card: Dictionary) -> void:
	if phase != "act" or done:
		return
	if selected.has(card):
		selected.erase(card)
	else:
		selected.append(card)
	selected.sort_custom(CardTools.sort_cards)

func meld_selected() -> String:
	if phase != "act" or done:
		return "Draw first."
	if not is_valid_meld(selected):
		return "Select 3 or more cards of the same rank."
	var meld := selected.duplicate()
	for card in meld:
		player.erase(card)
	player_melds.append(meld)
	selected = []
	last_message = "Melded %s for %d points." % [CardTools.cards_text(meld), meld_points(meld)]
	if player.is_empty():
		finish_hand("You went out.")
	return last_message

func discard_selected() -> String:
	if phase != "act" or done:
		return "Draw first."
	if selected.size() != 1:
		return "Select exactly one card to discard."
	var card: Dictionary = selected[0]
	player.erase(card)
	discard.append(card)
	selected = []
	if player.is_empty():
		finish_hand("You went out by discarding your last card.")
		return last_message
	phase = "bot"
	bot_turn()
	return last_message

func bot_turn() -> void:
	if done:
		return
	var top: Dictionary = discard[-1] if not discard.is_empty() else {}
	if top.size() > 0 and can_take_discard(bot):
		bot.append(discard.pop_back())
	else:
		var first := draw_card()
		if first.size() > 0:
			bot.append(first)
		var second := draw_card()
		if second.size() > 0:
			bot.append(second)
	_handle_red_threes(bot, false)
	bot.sort_custom(CardTools.sort_cards)
	var meld_count := _bot_make_melds()
	if bot.is_empty():
		finish_hand("Computer went out.")
		return
	var discard_card := choose_discard(bot)
	bot.erase(discard_card)
	discard.append(discard_card)
	last_bot_action = "Computer made %d meld%s and discarded %s." % [
		meld_count,
		"" if meld_count == 1 else "s",
		CardTools.card_text(discard_card)
	]
	if bot.is_empty():
		finish_hand("Computer went out.")
		return
	phase = "draw"
	last_message = "Your turn. Build same-rank melds and watch for seven-card canastas."

func _bot_make_melds() -> int:
	var made := 0
	var by_rank := _cards_by_rank(bot)
	for rank in by_rank.keys():
		var group: Array = by_rank[rank]
		if is_valid_meld(group):
			if not _hand_contains_all(bot, group):
				continue
			for card in group:
				bot.erase(card)
			bot_melds.append(group)
			made += 1
	return made

func _hand_contains_all(hand: Array, cards: Array) -> bool:
	var remaining := hand.duplicate()
	for card in cards:
		if not remaining.has(card):
			return false
		remaining.erase(card)
	return true

func _would_make_meld(hand: Array, card: Dictionary) -> bool:
	if is_red_three(card):
		return false
	var count := 1
	for item in hand:
		if item.rank == card.rank or is_wild(item):
			count += 1
	return count >= 3

func choose_discard(hand: Array) -> Dictionary:
	var best: Dictionary = hand[0]
	var best_count := 99
	var counts := _rank_counts(hand)
	for card in hand:
		var count := int(counts[card.rank])
		if count < best_count or (count == best_count and card_points(card) > card_points(best)):
			best_count = count
			best = card
	return best

func finish_hand(reason: String) -> void:
	if done:
		return
	done = true
	phase = "done"
	var player_delta := table_points(player_melds) + player_red_threes * 100 - hand_points(player)
	var computer_delta := table_points(bot_melds) + bot_red_threes * 100 - hand_points(bot)
	player_score += player_delta
	computer_score += computer_delta
	hands_played += 1
	last_message = "%s Hand score: You %s, Computer %s." % [reason, signed_points(player_delta), signed_points(computer_delta)]

func is_valid_meld(cards: Array) -> bool:
	if cards.size() < 3:
		return false
	var rank := ""
	var natural_count := 0
	var wild_count := 0
	for card in cards:
		if is_red_three(card):
			return false
		if is_wild(card):
			wild_count += 1
			continue
		if rank == "":
			rank = str(card.rank)
		elif str(card.rank) != rank:
			return false
		natural_count += 1
	if natural_count < 2:
		return false
	if wild_count > natural_count:
		return false
	return true

func meld_points(cards: Array) -> int:
	var total := 0
	for card in cards:
		total += card_points(card)
	if cards.size() >= 7:
		total += 300
	return total

func table_points(melds: Array) -> int:
	var total := 0
	for meld in melds:
		total += meld_points(meld)
	return total

func hand_points(cards: Array) -> int:
	var total := 0
	for card in cards:
		total += card_points(card)
	return total

func card_points(card: Dictionary) -> int:
	if is_red_three(card):
		return 100
	if card.rank in ["A", "2"]:
		return 20
	if card.rank in ["K", "Q", "J", "10", "9", "8"]:
		return 10
	return 5

func _cards_by_rank(cards: Array) -> Dictionary:
	var by_rank := {}
	var wilds := []
	for card in cards:
		if is_wild(card):
			wilds.append(card)
			continue
		if is_red_three(card):
			continue
		if not by_rank.has(card.rank):
			by_rank[card.rank] = []
		by_rank[card.rank].append(card)
	for rank in by_rank.keys():
		var group: Array = by_rank[rank]
		for wild in wilds:
			if group.size() < 7:
				group.append(wild)
	return by_rank

func _rank_counts(cards: Array) -> Dictionary:
	var counts := {}
	for card in cards:
		counts[card.rank] = int(counts.get(card.rank, 0)) + 1
	return counts

func _sort_hands() -> void:
	player.sort_custom(CardTools.sort_cards)
	bot.sort_custom(CardTools.sort_cards)

func score_text() -> String:
	return "Score - You: %d  Computer: %d  Hands: %d" % [player_score, computer_score, hands_played]

func table_text() -> String:
	var top := "none" if discard.is_empty() else CardTools.card_text(discard[-1])
	var frozen := " frozen" if is_discard_frozen() else ""
	return "Stock: %d | Discard: %s%s | Your hand: %d | Computer: %d | Red threes: %d-%d" % [deck.size(), top, frozen, player.size(), bot.size(), player_red_threes, bot_red_threes]

func guidance_text() -> String:
	if done:
		return StrategyText.advice(
			"Start a new hand.",
			"Compare table points to cards stranded in hand.",
			"Seven-card melds earn the canasta bonus, so track which ranks are close to seven."
		)
	if phase == "draw":
		if is_discard_frozen():
			return StrategyText.advice(
				"Draw from stock unless you can unlock the frozen pile.",
				"The discard pile is frozen by a wild card or red three; you need a natural pair of the top rank to take it.",
				"Red threes score bonus points automatically in this trainer."
			)
		if not discard.is_empty() and can_take_discard(player):
			var top: Dictionary = discard[-1]
			return StrategyText.advice(
				"Take %s from discard." % CardTools.card_text(top),
				"It completes a legal same-rank meld with natural cards and wild twos.",
				"After taking it, prefer melding the rank before discarding."
			)
		if not discard.is_empty():
			var top_card: Dictionary = discard[-1]
			return StrategyText.advice(
				"Draw from stock.",
				"%s does not complete a same-rank meld yet." % CardTools.card_text(top_card),
				"Take the discard only when it turns a natural pair into a meld or advances a rank toward canasta."
			)
		return StrategyText.advice("Draw from stock.", "The discard pile is empty.", "Watch for pairs that can become three-card melds.")
	if phase == "act":
		if is_valid_meld(selected):
			return StrategyText.advice(
				"Meld the selected rank.",
				"It is worth %d points now%s." % [meld_points(selected), " including a canasta bonus" if selected.size() >= 7 else ""],
				"Keep extending the same rank toward seven cards when possible."
			)
		if selected.size() == 1:
			var card: Dictionary = selected[0]
			var count := _rank_count(player, card.rank)
			return StrategyText.advice(
				"Use %s as a discard only if it is isolated." % CardTools.card_text(card),
				"You currently have %d card%s of that rank." % [count, "" if count == 1 else "s"],
				"Do not discard from a pair unless another discard is clearly worse."
			)
		return StrategyText.advice(
			"Build a same-rank meld.",
			_rank_plan_text(player),
			"Canasta melds need 2+ natural cards and may include wild twos; seven cards earns the bonus in this trainer."
		)
	return StrategyText.advice("Watch the computer turn.", "It draws toward same-rank melds and discards isolated cards.", "The discard it leaves can signal which rank it is not collecting.")

func can_take_discard(hand: Array) -> bool:
	if discard.is_empty():
		return false
	var top: Dictionary = discard[-1]
	if is_red_three(top) or is_wild(top):
		return false
	var natural_matches := 0
	for card in hand:
		if not is_wild(card) and not is_red_three(card) and card.rank == top.rank:
			natural_matches += 1
	if is_discard_frozen():
		return natural_matches >= 2
	return _would_make_meld(hand, top)

func is_discard_frozen() -> bool:
	if discard.is_empty():
		return false
	var top: Dictionary = discard[-1]
	return is_wild(top) or is_red_three(top)

func is_wild(card: Dictionary) -> bool:
	return card.rank == "2"

func is_red_three(card: Dictionary) -> bool:
	return card.rank == "3" and (card.suit == "H" or card.suit == "D")

func _handle_red_threes(hand: Array, is_player: bool) -> void:
	var found := []
	for card in hand:
		if is_red_three(card):
			found.append(card)
	for card in found:
		hand.erase(card)
		if is_player:
			player_red_threes += 1
		else:
			bot_red_threes += 1
		var replacement := draw_card()
		if replacement.size() > 0:
			hand.append(replacement)

func _rank_count(cards: Array, rank: String) -> int:
	var count := 0
	for card in cards:
		if str(card.rank) == rank:
			count += 1
	return count

func _rank_plan_text(cards: Array) -> String:
	var counts := _rank_counts(cards)
	var best_rank := ""
	var best_count := 0
	for rank in counts.keys():
		var count := int(counts[rank])
		if count > best_count:
			best_rank = str(rank)
			best_count = count
	if best_count >= 3:
		return "Your strongest rank is %s with %d cards; meld it before discarding." % [best_rank, best_count]
	if best_count == 2:
		return "Your best near-meld is a pair of %ss; protect it and look for the third." % best_rank
	return "No rank has a pair yet; discard isolated high cards first."

static func signed_points(value: int) -> String:
	if value >= 0:
		return "+%d" % value
	return "%d" % value
