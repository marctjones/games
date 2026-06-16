class_name Rummy500Model
extends RefCounted

const CardTools := preload("res://scripts/core/card_tools.gd")
const OpponentPolicy := preload("res://scripts/core/opponent_policy.gd")
const RummyTools := preload("res://scripts/games/rummy/rummy_tools.gd")
const StrategyText := preload("res://scripts/core/strategy_text.gd")

const RUMMY_500_TARGET_SCORE := 500

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
var last_drawn_cards: Array = []
var last_draw_source := ""
var required_pickup_card: Dictionary = {}
var player_score := 0
var computer_score := 0
var hands_played := 0
var player_hand_points := 0
var computer_hand_points := 0
var opponent_difficulty := OpponentPolicy.DEFAULT
var allow_discard_pile_pickup := true

func set_difficulty(difficulty: String) -> void:
	opponent_difficulty = OpponentPolicy.normalize(difficulty)

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
	last_drawn_cards = []
	last_draw_source = ""
	required_pickup_card = {}
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
	last_drawn_cards = [last_drawn_card]
	last_draw_source = "stock"
	required_pickup_card = {}
	player.append(last_drawn_card)
	player.sort_custom(CardTools.sort_cards)
	phase = "act"
	last_message = "You drew from the stock. The new card is highlighted. Select cards to meld or choose one discard."

func draw_discard() -> void:
	draw_discard_at(discard.size() - 1)

func draw_discard_at(discard_index: int) -> void:
	if phase != "draw" or discard.is_empty() or done:
		return
	if discard_index < 0 or discard_index >= discard.size():
		return
	if not can_take_discard_at(discard_index):
		var card: Dictionary = discard[discard_index]
		last_message = "You cannot take %s from the discard pile because it cannot be used immediately in a meld or layoff." % CardTools.card_text(card)
		return
	var taken := _discard_cards_from(discard_index)
	for i in range(discard.size() - 1, discard_index - 1, -1):
		discard.pop_back()
	last_drawn_card = taken[0]
	last_drawn_cards = taken.duplicate()
	last_draw_source = "discard"
	for card in taken:
		player.append(card)
	player.sort_custom(CardTools.sort_cards)
	if taken.size() > 1:
		required_pickup_card = taken[0]
	else:
		required_pickup_card = {}
	phase = "act"
	if required_pickup_card.is_empty():
		last_message = "You took the top discard. The new card is highlighted. Use it in a meld or discard one card."
	else:
		last_message = "You took %s from the discard pile, plus %d newer discard%s. Use %s in a meld or layoff before discarding." % [
			CardTools.card_text(required_pickup_card),
			taken.size() - 1,
			"" if taken.size() == 2 else "s",
			CardTools.card_text(required_pickup_card),
		]

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
	if has_pickup_requirement() and not selected.has(required_pickup_card):
		return "Use %s in your first meld or layoff before discarding." % CardTools.card_text(required_pickup_card)
	var meld := selected.duplicate()
	meld.sort_custom(CardTools.sort_cards)
	for card in meld:
		player.erase(card)
	player_melds.append(meld)
	player_hand_points += RummyTools.meld_points(meld)
	if has_pickup_requirement() and meld.has(required_pickup_card):
		required_pickup_card = {}
	selected = []
	_refresh_drawn_card_tracking()
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
	if has_pickup_requirement() and card != required_pickup_card:
		return "Use %s in your first meld or layoff before discarding." % CardTools.card_text(required_pickup_card)
	for meld in player_melds:
		if RummyTools.can_layoff(card, meld):
			player.erase(card)
			meld.append(card)
			meld.sort_custom(CardTools.sort_cards)
			player_hand_points += RummyTools.card_points(card)
			if has_pickup_requirement() and card == required_pickup_card:
				required_pickup_card = {}
			selected = []
			_refresh_drawn_card_tracking()
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
			if has_pickup_requirement() and card == required_pickup_card:
				required_pickup_card = {}
			selected = []
			_refresh_drawn_card_tracking()
			last_message = "Laid off %s onto the computer meld for %d point%s." % [CardTools.card_text(card), RummyTools.card_points(card), "" if RummyTools.card_points(card) == 1 else "s"]
			if player.is_empty():
				finish_hand("You went out after laying off.")
			return last_message
	return "That card cannot be laid off on any current meld."

func discard_selected() -> String:
	if phase != "act" or done:
		return "Draw first."
	if has_pickup_requirement():
		return "Use %s in a meld or layoff before discarding." % CardTools.card_text(required_pickup_card)
	if selected.size() != 1:
		return "Select exactly one card to discard."
	var card: Dictionary = selected[0]
	player.erase(card)
	discard.append(card)
	selected = []
	last_drawn_card = {}
	last_drawn_cards = []
	last_draw_source = ""
	required_pickup_card = {}
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
	var draw_source := "stock pile"
	if _bot_should_take_visible_discard(top_discard):
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
	var bot_discard := _bot_choose_discard()
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

func can_take_discard_at(discard_index: int) -> bool:
	if phase != "draw" or done or discard_index < 0 or discard_index >= discard.size():
		return false
	if discard_index == discard.size() - 1:
		return true
	if not allow_discard_pile_pickup:
		return false
	var taken := _discard_cards_from(discard_index)
	var anchor: Dictionary = taken[0]
	var test_hand := player.duplicate()
	for card in taken:
		test_hand.append(card)
	return _card_has_immediate_use(anchor, test_hand)

func discard_pickup_count(discard_index: int) -> int:
	if discard_index < 0 or discard_index >= discard.size():
		return 0
	return discard.size() - discard_index

func has_pickup_requirement() -> bool:
	return required_pickup_card.size() > 0

func is_drawn_card(card: Dictionary) -> bool:
	return phase == "act" and last_drawn_cards.has(card)

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

func _bot_should_take_visible_discard(top_discard: Dictionary) -> bool:
	var current_deadwood := RummyTools.deadwood_score(bot)
	var with_discard := bot.duplicate()
	with_discard.append(top_discard)
	var discard_deadwood := RummyTools.deadwood_score(with_discard)
	var improvement := current_deadwood - discard_deadwood
	if improvement >= OpponentPolicy.rummy_visible_pickup_threshold(opponent_difficulty):
		return true
	return OpponentPolicy.allows_speculative_pickup(opponent_difficulty) and RummyTools.visible_pickup_score(top_discard, bot) >= 2

func _bot_choose_discard() -> Dictionary:
	var scored := []
	for card in bot:
		var test := bot.duplicate()
		test.erase(card)
		var score := -float(RummyTools.deadwood_score(test)) + float(RummyTools.card_points(card)) * 0.01
		scored.append({"item": card, "score": score})
	if scored.is_empty():
		return bot[0]
	return OpponentPolicy.pick_scored(scored, opponent_difficulty)

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
	required_pickup_card = {}
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
	var match_text := ""
	if player_score >= RUMMY_500_TARGET_SCORE or computer_score >= RUMMY_500_TARGET_SCORE:
		match_text = " | Match complete"
	return "Score to %d - You: %d  Computer: %d  Hands: %d%s" % [RUMMY_500_TARGET_SCORE, player_score, computer_score, hands_played, match_text]

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
		if allow_discard_pile_pickup:
			return discard_pickup_guidance_text()
		return RummyTools.draw_decision_text(player, discard[-1])
	if phase == "act":
		if has_pickup_requirement():
			return StrategyText.advice(
				"Use %s now." % CardTools.card_text(required_pickup_card),
				"You took a lower discard, so this card must be melded or laid off before you can discard.",
				"The other cards picked up from above it may stay in your hand."
			)
		return RummyTools.action_phase_text(player, selected, player_melds, bot_melds)
	return StrategyText.advice("Watch the computer turn.", "It will draw, score available melds, lay off, then discard.", "Use the exposed discard to infer what ranks and suits it may not need.")

func discard_pickup_guidance_text() -> String:
	var top_index := discard.size() - 1
	var top_card: Dictionary = discard[top_index]
	var best_index := top_index
	var best_score := -999
	for i in range(discard.size()):
		if not can_take_discard_at(i):
			continue
		var card: Dictionary = discard[i]
		var score := RummyTools.visible_pickup_score(card, player) * 4 - discard_pickup_count(i)
		if i == top_index:
			score += 1
		if score > best_score:
			best_score = score
			best_index = i
	var best_card: Dictionary = discard[best_index]
	if best_index == top_index:
		return RummyTools.draw_decision_text(player, top_card)
	return StrategyText.advice(
		"Take %s from the discard spread." % CardTools.card_text(best_card),
		"You will also pick up %d newer discard%s, but %s can be used immediately." % [
			discard_pickup_count(best_index) - 1,
			"" if discard_pickup_count(best_index) == 2 else "s",
			CardTools.card_text(best_card),
		],
		"Do not take a deep discard unless the forced meld/layoff is worth the extra hand clutter."
	)

func _discard_cards_from(discard_index: int) -> Array:
	var cards := []
	for i in range(discard_index, discard.size()):
		cards.append(discard[i])
	return cards

func _card_has_immediate_use(card: Dictionary, hand_after_take: Array) -> bool:
	if _can_layoff_any(card):
		return true
	var card_indices := []
	for i in range(hand_after_take.size()):
		if hand_after_take[i] == card:
			card_indices.append(i)
	for meld in RummyTools.candidate_melds(hand_after_take):
		for index in card_indices:
			if meld.has(index):
				return true
	return false

func _refresh_drawn_card_tracking() -> void:
	var remaining := []
	for card in last_drawn_cards:
		if player.has(card):
			remaining.append(card)
	last_drawn_cards = remaining
	if last_drawn_card.size() > 0 and not player.has(last_drawn_card):
		last_drawn_card = {}

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
