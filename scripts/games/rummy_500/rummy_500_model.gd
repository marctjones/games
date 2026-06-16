class_name Rummy500Model
extends RefCounted

const CardTools := preload("res://scripts/core/card_tools.gd")
const RummyTools := preload("res://scripts/games/rummy/rummy_tools.gd")
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
var last_drawn_card: Dictionary = {}
var last_draw_source := ""
var player_score := 0
var computer_score := 0
var hands_played := 0
var player_hand_points := 0
var computer_hand_points := 0

func new_hand() -> void:
	deck = CardTools.make_deck()
	discard = []
	player = []
	bot = []
	selected = []
	player_melds = []
	bot_melds = []
	phase = "draw"
	done = false
	last_message = "Draw from the stock or discard pile. Then meld, lay off, or discard one card to end your turn."
	last_bot_action = "Computer has not moved yet."
	last_drawn_card = {}
	last_draw_source = ""
	player_hand_points = 0
	computer_hand_points = 0
	for i in range(13):
		player.append(CardTools.draw_card(deck))
		bot.append(CardTools.draw_card(deck))
	discard.append(CardTools.draw_card(deck))
	player.sort_custom(CardTools.sort_cards)
	bot.sort_custom(CardTools.sort_cards)

func draw_stock() -> void:
	if phase != "draw" or deck.is_empty() or done:
		return
	last_drawn_card = CardTools.draw_card(deck)
	last_draw_source = "stock"
	player.append(last_drawn_card)
	player.sort_custom(CardTools.sort_cards)
	phase = "act"
	last_message = "You drew from the stock. The new card is highlighted. Select cards to meld or choose one discard."

func draw_discard() -> void:
	if phase != "draw" or discard.is_empty() or done:
		return
	last_drawn_card = discard.pop_back()
	last_draw_source = "discard"
	player.append(last_drawn_card)
	player.sort_custom(CardTools.sort_cards)
	phase = "act"
	last_message = "You took the visible discard. The new card is highlighted. Use it in a meld or discard one card."

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
	if not RummyTools.is_valid_meld(selected):
		return "Select 3 or more cards that form one set or one same-suit run."
	var meld := selected.duplicate()
	meld.sort_custom(CardTools.sort_cards)
	for card in meld:
		player.erase(card)
	player_melds.append(meld)
	player_hand_points += RummyTools.meld_points(meld)
	selected = []
	last_drawn_card = {} if not player.has(last_drawn_card) else last_drawn_card
	last_message = "Melded %s for %d points. You can still lay off or discard to end the turn." % [CardTools.cards_text(meld), RummyTools.meld_points(meld)]
	if player.is_empty():
		finish_hand("You went out after melding.")
	return last_message

func layoff_selected() -> String:
	if phase != "act" or done:
		return "Draw first."
	if selected.size() != 1:
		return "Select exactly one card to lay off onto an existing meld."
	var card: Dictionary = selected[0]
	for meld in player_melds:
		if RummyTools.can_layoff(card, meld):
			player.erase(card)
			meld.append(card)
			meld.sort_custom(CardTools.sort_cards)
			player_hand_points += RummyTools.card_points(card)
			selected = []
			last_message = "Laid off %s onto your meld for %d point%s." % [CardTools.card_text(card), RummyTools.card_points(card), "" if RummyTools.card_points(card) == 1 else "s"]
			if player.is_empty():
				finish_hand("You went out after laying off.")
			return last_message
	for meld in bot_melds:
		if RummyTools.can_layoff(card, meld):
			player.erase(card)
			meld.append(card)
			meld.sort_custom(CardTools.sort_cards)
			player_hand_points += RummyTools.card_points(card)
			selected = []
			last_message = "Laid off %s onto the computer meld for %d point%s." % [CardTools.card_text(card), RummyTools.card_points(card), "" if RummyTools.card_points(card) == 1 else "s"]
			if player.is_empty():
				finish_hand("You went out after laying off.")
			return last_message
	return "That card cannot be laid off on any current meld."

func discard_selected() -> String:
	if phase != "act" or done:
		return "Draw first."
	if selected.size() != 1:
		return "Select exactly one card to discard."
	var card: Dictionary = selected[0]
	player.erase(card)
	discard.append(card)
	selected = []
	last_drawn_card = {}
	last_draw_source = ""
	if player.is_empty():
		finish_hand("You went out by discarding your last card.")
		return last_message
	phase = "bot"
	bot_turn()
	return last_message

func bot_turn() -> void:
	if done:
		return
	if deck.is_empty():
		finish_hand("Stock is empty.")
		return
	var top_discard: Dictionary = discard[-1]
	var with_discard := bot.duplicate()
	with_discard.append(top_discard)
	var with_stock := bot.duplicate()
	with_stock.append(deck[-1])
	var draw_source := "stock pile"
	if RummyTools.deadwood_score(with_discard) <= RummyTools.deadwood_score(with_stock):
		bot.append(discard.pop_back())
		draw_source = "discard pile"
	else:
		bot.append(CardTools.draw_card(deck))
	bot.sort_custom(CardTools.sort_cards)
	var meld_count := _bot_make_melds()
	_bot_layoff_cards()
	if bot.is_empty():
		finish_hand("Computer went out.")
		return
	var bot_discard := RummyTools.choose_discard(bot)
	bot.erase(bot_discard)
	discard.append(bot_discard)
	last_bot_action = "Computer drew from the %s, made %d meld%s, and discarded %s." % [
		draw_source,
		meld_count,
		"" if meld_count == 1 else "s",
		CardTools.card_text(bot_discard)
	]
	if bot.is_empty():
		finish_hand("Computer went out.")
		return
	phase = "draw"
	last_message = "Your turn. Coach tip: make scoring melds before discarding, but avoid breaking a near-run just for short-term points."

func _bot_make_melds() -> int:
	var groups := RummyTools.best_meld_groups(bot)
	var made := 0
	for group in groups:
		if not _hand_contains_all(bot, group):
			continue
		for card in group:
			bot.erase(card)
		bot_melds.append(group)
		computer_hand_points += RummyTools.meld_points(group)
		made += 1
	return made

func _bot_layoff_cards() -> void:
	var changed := true
	while changed:
		changed = false
		for card in bot.duplicate():
			for meld in bot_melds:
				if RummyTools.can_layoff(card, meld):
					bot.erase(card)
					meld.append(card)
					meld.sort_custom(CardTools.sort_cards)
					computer_hand_points += RummyTools.card_points(card)
					changed = true
					break
			if changed:
				break

func _hand_contains_all(hand: Array, cards: Array) -> bool:
	for card in cards:
		if not hand.has(card):
			return false
	return true

func finish_hand(reason: String) -> void:
	if done:
		return
	done = true
	phase = "done"
	var player_delta: int = player_hand_points - RummyTools.hand_points(player)
	var computer_delta: int = computer_hand_points - RummyTools.hand_points(bot)
	player_score += player_delta
	computer_score += computer_delta
	hands_played += 1
	last_message = "%s Hand scored. You: %s, Computer: %s. Start a new hand to continue toward 500." % [reason, signed_points(player_delta), signed_points(computer_delta)]

func reset_score() -> void:
	player_score = 0
	computer_score = 0
	hands_played = 0

func score_text() -> String:
	return "Score - You: %d  Computer: %d  Hands: %d" % [player_score, computer_score, hands_played]

func hand_score_text() -> String:
	return "This hand - You melded: %d, deadwood: %d | Computer melded: %d, deadwood: %d" % [
		player_hand_points,
		RummyTools.hand_points(player),
		computer_hand_points,
		RummyTools.hand_points(bot),
	]

func table_text() -> String:
	var top_discard := "none" if discard.is_empty() else CardTools.card_text(discard[-1])
	return "Stock: %d cards | Discard: %s | Your hand: %d cards | Computer: %d cards" % [deck.size(), top_discard, player.size(), bot.size()]

func guidance_text() -> String:
	if done:
		return StrategyText.advice(
			"Start a new hand.",
			"Review whether you scored melds early enough while avoiding too much deadwood.",
			"Rummy 500 rewards cards melded now, but leftover hand points still count against you."
		)
	if phase == "draw":
		if discard.is_empty():
			return StrategyText.advice("Draw stock.", "There is no visible discard to evaluate.", "Use this draw to preserve pairs and two-card runs.")
		return RummyTools.draw_decision_text(player, discard[-1])
	if phase == "act":
		return RummyTools.action_phase_text(player, selected, player_melds, bot_melds)
	return StrategyText.advice("Watch the computer turn.", "It will draw, score available melds, lay off, then discard.", "Use the exposed discard to infer what ranks and suits it may not need.")

func _can_layoff_any(card: Dictionary) -> bool:
	for meld in player_melds:
		if RummyTools.can_layoff(card, meld):
			return true
	for meld in bot_melds:
		if RummyTools.can_layoff(card, meld):
			return true
	return false

static func signed_points(value: int) -> String:
	if value >= 0:
		return "+%d" % value
	return "%d" % value
