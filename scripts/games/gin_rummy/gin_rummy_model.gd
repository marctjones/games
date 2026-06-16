class_name GinRummyModel
extends RefCounted

const CardTools := preload("res://scripts/core/card_tools.gd")
const OpponentPolicy := preload("res://scripts/core/opponent_policy.gd")
const RummyTools := preload("res://scripts/games/rummy/rummy_tools.gd")
const StrategyText := preload("res://scripts/core/strategy_text.gd")

const KNOCK_LIMIT := 10
const GIN_BONUS := 25
const UNDERCUT_BONUS := 25
const GAME_TARGET_SCORE := 100

var deck: Array = []
var discard: Array = []
var player: Array = []
var bot: Array = []
var phase := "draw"
var last_message := ""
var last_bot_action := ""
var last_drawn_card: Dictionary = {}
var last_draw_source := ""
var player_score := 0
var computer_score := 0
var hands_played := 0
var opponent_difficulty := OpponentPolicy.DEFAULT
var last_score_detail := "No hands scored yet."

func set_difficulty(difficulty: String) -> void:
	opponent_difficulty = OpponentPolicy.normalize(difficulty)

func new_hand() -> void:
	deck = CardTools.make_deck()
	discard = []
	player = []
	bot = []
	phase = "draw"
	last_message = "Draw from the stock or discard pile, then discard. After drawing, use Knock/Gin when a discard leaves 10 or fewer deadwood."
	last_bot_action = "Computer has not moved yet."
	last_drawn_card = {}
	last_draw_source = ""
	for i in range(10):
		player.append(CardTools.draw_card(deck))
		bot.append(CardTools.draw_card(deck))
	discard.append(CardTools.draw_card(deck))
	player.sort_custom(CardTools.sort_cards)
	bot.sort_custom(CardTools.sort_cards)

func draw_stock() -> void:
	if phase != "draw" or deck.is_empty():
		return
	last_drawn_card = CardTools.draw_card(deck)
	last_draw_source = "stock"
	player.append(last_drawn_card)
	player.sort_custom(CardTools.sort_cards)
	phase = "discard"
	last_message = "You drew from the stock. The new card is highlighted; choose one card to discard."

func draw_discard() -> void:
	if phase != "draw" or discard.is_empty():
		return
	last_drawn_card = discard.pop_back()
	last_draw_source = "discard"
	player.append(last_drawn_card)
	player.sort_custom(CardTools.sort_cards)
	phase = "discard"
	last_message = "You took the visible discard. The new card is highlighted. Coach tip: taking the discard is strongest when it completes or extends a meld."

func player_discard(card: Dictionary) -> void:
	if phase != "discard":
		return
	player.erase(card)
	discard.append(card)
	last_drawn_card = {}
	last_draw_source = ""
	phase = "bot"

func bot_turn() -> void:
	if deck.is_empty():
		finish_hand("Stock is empty.")
		return
	var top_discard: Dictionary = discard[-1]
	var draw_source := "stock pile"
	var drawn_from_discard: Dictionary = {}
	if _bot_should_take_visible_discard(top_discard):
		drawn_from_discard = discard.pop_back()
		bot.append(drawn_from_discard)
		draw_source = "discard pile"
	else:
		bot.append(CardTools.draw_card(deck))
	var bot_discard := choose_discard_except(bot, drawn_from_discard)
	bot.erase(bot_discard)
	discard.append(bot_discard)
	bot.sort_custom(CardTools.sort_cards)
	last_bot_action = "Computer drew from the %s and discarded %s." % [draw_source, CardTools.card_text(bot_discard)]
	var bot_deadwood := deadwood(bot)
	if bot_deadwood <= KNOCK_LIMIT:
		finish_hand("Computer goes gin." if bot_deadwood == 0 else "Computer knocks.", "computer")
		return
	phase = "draw"
	last_message = "Your turn. Coach tip: lower deadwood matters, but do not break completed melds just to discard a high card."

func knock() -> String:
	if phase != "discard":
		return "Draw first. In Gin Rummy you knock by discarding the final card that leaves 10 or fewer deadwood."
	var knock_discard := best_player_knock_discard()
	if knock_discard.is_empty():
		return "No legal knock yet. Your best discard would leave %d deadwood; you need %d or fewer." % [best_deadwood_after_discard(player), KNOCK_LIMIT]
	player.erase(knock_discard)
	discard.append(knock_discard)
	last_drawn_card = {}
	last_draw_source = ""
	var remaining_deadwood := deadwood(player)
	var reason := "You go gin by discarding %s." % CardTools.card_text(knock_discard) if remaining_deadwood == 0 else "You knock by discarding %s." % CardTools.card_text(knock_discard)
	finish_hand(reason, "player")
	return last_message

func finish_hand(reason: String, knocker: String = "") -> void:
	phase = "done"
	hands_played += 1
	if knocker == "player" or knocker == "computer":
		_score_knock_finish(reason, knocker)
		return
	var player_deadwood := deadwood(player)
	var bot_deadwood := deadwood(bot)
	var outcome := "You win the hand." if player_deadwood < bot_deadwood else "Computer wins the hand."
	if player_deadwood == bot_deadwood:
		outcome = "The hand is tied."
	var point_delta: int = abs(player_deadwood - bot_deadwood)
	if player_deadwood < bot_deadwood:
		player_score += point_delta
	elif bot_deadwood < player_deadwood:
		computer_score += point_delta
	last_score_detail = "%s %s Deadwood: you %d, computer %d. Points: %d." % [reason, outcome, player_deadwood, bot_deadwood, point_delta]
	last_message = "%s Coach tip: build sets/runs, then discard isolated high cards.%s" % [last_score_detail, _match_suffix()]

func reset_score() -> void:
	player_score = 0
	computer_score = 0
	hands_played = 0
	last_score_detail = "No hands scored yet."

func score_text() -> String:
	var match_text := ""
	if player_score >= GAME_TARGET_SCORE or computer_score >= GAME_TARGET_SCORE:
		match_text = " | Match complete"
	return "Score to %d - You: %d  Computer: %d  Hands: %d%s" % [GAME_TARGET_SCORE, player_score, computer_score, hands_played, match_text]

func choose_discard(hand: Array) -> Dictionary:
	return choose_discard_except(hand, {})

func choose_discard_except(hand: Array, forbidden_card: Dictionary) -> Dictionary:
	var scored := []
	for card in hand:
		if forbidden_card.size() > 0 and card == forbidden_card:
			continue
		var test := hand.duplicate()
		test.erase(card)
		var score := -float(RummyTools.deadwood_score(test)) + float(CardTools.pip_value(card.rank)) * 0.01
		scored.append({"item": card, "score": score})
	if scored.is_empty():
		return hand[0]
	return OpponentPolicy.pick_scored(scored, opponent_difficulty)

func _bot_should_take_visible_discard(top_discard: Dictionary) -> bool:
	var current_deadwood := deadwood(bot)
	var with_discard := bot.duplicate()
	with_discard.append(top_discard)
	var discard_deadwood := deadwood(with_discard)
	var improvement := current_deadwood - discard_deadwood
	if improvement >= OpponentPolicy.rummy_visible_pickup_threshold(opponent_difficulty):
		return true
	return OpponentPolicy.allows_speculative_pickup(opponent_difficulty) and RummyTools.visible_pickup_score(top_discard, bot) >= 2

func table_text() -> String:
	var top_discard := "none" if discard.is_empty() else CardTools.card_text(discard[-1])
	return "Stock: %d cards\nDiscard: %s\nYour deadwood: %d\nComputer cards: %d\nLast result: %s" % [deck.size(), top_discard, deadwood(player), bot.size(), last_score_detail]

func guidance_text() -> String:
	if phase == "done":
		return StrategyText.advice(
			"Start a new hand.",
			last_score_detail,
			"Good review habit: ask whether a smaller set plus a run would have beaten one larger meld."
		)
	if phase == "draw":
		if discard.is_empty():
			return StrategyText.advice("Draw stock.", "No discard card is available.", "Keep tracking which ranks and suits would lower deadwood.")
		return RummyTools.draw_decision_text(player, discard[-1])
	if phase == "discard":
		var knock_discard := best_player_knock_discard()
		if not knock_discard.is_empty():
			var test_knock := player.duplicate()
			test_knock.erase(knock_discard)
			var knock_deadwood := deadwood(test_knock)
			return StrategyText.advice(
				"Use %s with %s." % ["Gin" if knock_deadwood == 0 else "Knock", CardTools.card_text(knock_discard)],
				"Discarding it leaves %d deadwood, so the hand can end now with real gin/knock scoring." % knock_deadwood,
				"Clicking a card instead makes a normal discard and gives the computer another turn."
			)
		var discard_card := choose_discard(player)
		var test := player.duplicate()
		test.erase(discard_card)
		var new_note := " It is the newly drawn card." if discard_card == last_drawn_card else ""
		return StrategyText.advice(
			"Discard %s." % CardTools.card_text(discard_card),
			"The best non-overlapping meld layout would leave %d deadwood.%s" % [deadwood(test), new_note],
			"Do not break a completed meld unless it creates a lower-deadwood split."
		)
	return StrategyText.advice("Watch the computer turn.", "The bot is using deadwood reduction and avoids returning a useful pickup.", "Note which discard it exposes for your next draw.")

func best_player_knock_discard() -> Dictionary:
	if phase != "discard":
		return {}
	return _best_knock_discard(player)

func best_deadwood_after_discard(hand: Array) -> int:
	if hand.is_empty():
		return 0
	var best := 999
	for card in hand:
		var test := hand.duplicate()
		test.erase(card)
		best = min(best, deadwood(test))
	return best

static func _best_knock_discard(hand: Array) -> Dictionary:
	var best_card: Dictionary = {}
	var best_deadwood := 999
	for card in hand:
		var test := hand.duplicate()
		test.erase(card)
		var score := deadwood(test)
		if score <= KNOCK_LIMIT and (best_card.is_empty() or score < best_deadwood or (score == best_deadwood and CardTools.pip_value(card.rank) > CardTools.pip_value(best_card.rank))):
			best_card = card
			best_deadwood = score
	return best_card

func _score_knock_finish(reason: String, knocker: String) -> void:
	var knocker_hand := player if knocker == "player" else bot
	var defender_hand := bot if knocker == "player" else player
	var knocker_name := "You" if knocker == "player" else "Computer"
	var defender_name := "computer" if knocker == "player" else "you"
	var defender_label := "Computer" if knocker == "player" else "You"
	var knocker_deadwood := deadwood(knocker_hand)
	var knocker_melds := RummyTools.best_meld_groups(knocker_hand)
	var is_gin := knocker_deadwood == 0
	var defense := {
		"deadwood": deadwood(defender_hand),
		"laid_off": [],
		"remaining": RummyTools.deadwood_cards(defender_hand),
	}
	if not is_gin:
		defense = RummyTools.best_deadwood_after_layoff(defender_hand, knocker_melds)
	var defender_deadwood := int(defense["deadwood"])
	var laid_off: Array = defense["laid_off"]
	var points := 0
	var scoring_note := ""
	if is_gin:
		points = defender_deadwood + GIN_BONUS
		_award_points(knocker, points)
		scoring_note = "%s scores %d: %d defender deadwood plus %d gin bonus." % [knocker_name, points, defender_deadwood, GIN_BONUS]
	elif defender_deadwood <= knocker_deadwood:
		points = knocker_deadwood - defender_deadwood + UNDERCUT_BONUS
		_award_points(_other_side(knocker), points)
		scoring_note = "%s undercuts for %d: %d deadwood difference plus %d undercut bonus." % [defender_label, points, knocker_deadwood - defender_deadwood, UNDERCUT_BONUS]
	else:
		points = defender_deadwood - knocker_deadwood
		_award_points(knocker, points)
		scoring_note = "%s scores %d from the deadwood difference after layoffs." % [knocker_name, points]
	var layoff_note := ""
	if not is_gin and not laid_off.is_empty():
		layoff_note = " %s laid off %s." % [defender_label, CardTools.cards_text(laid_off)]
	elif not is_gin:
		layoff_note = " %s had no useful layoffs." % defender_label
	last_score_detail = "%s %s Knocker deadwood: %d; %s deadwood after layoffs: %d.%s" % [reason, scoring_note, knocker_deadwood, defender_name, defender_deadwood, layoff_note]
	last_message = "%s%s" % [last_score_detail, _match_suffix()]

func _award_points(side: String, points: int) -> void:
	if side == "player":
		player_score += points
	elif side == "computer":
		computer_score += points

func _other_side(side: String) -> String:
	return "computer" if side == "player" else "player"

func _match_suffix() -> String:
	if player_score >= GAME_TARGET_SCORE and player_score > computer_score:
		return " Match to %d complete: you win." % GAME_TARGET_SCORE
	if computer_score >= GAME_TARGET_SCORE and computer_score > player_score:
		return " Match to %d complete: computer wins." % GAME_TARGET_SCORE
	if player_score >= GAME_TARGET_SCORE and computer_score >= GAME_TARGET_SCORE:
		return " Match to %d complete." % GAME_TARGET_SCORE
	return ""

static func deadwood(hand: Array) -> int:
	return RummyTools.deadwood_score(hand)

static func best_meld_mask(hand: Array) -> Array:
	return RummyTools.best_meld_mask(hand)

static func best_meld_groups(hand: Array) -> Array:
	return RummyTools.best_meld_index_groups(hand)

static func search_melds(hand: Array, melds: Array, index: int, current: Array, current_value: int) -> Dictionary:
	if index >= melds.size():
		return {"value": current_value, "mask": current.duplicate()}
	var best: Dictionary = search_melds(hand, melds, index + 1, current, current_value)
	var meld: Array = melds[index]
	for item in meld:
		if current.has(item):
			return best
	for item in meld:
		current.append(item)
	var value := 0
	for item in meld:
		value += CardTools.pip_value(hand[item].rank)
	var with_meld: Dictionary = search_melds(hand, melds, index + 1, current, current_value + value)
	for item in meld:
		current.erase(item)
	if int(with_meld["value"]) > int(best["value"]):
		return with_meld
	return best

static func search_meld_groups(hand: Array, melds: Array, index: int, current_mask: Array, current_groups: Array, current_value: int) -> Dictionary:
	if index >= melds.size():
		return {"value": current_value, "mask": current_mask.duplicate(), "groups": current_groups.duplicate(true)}
	var best: Dictionary = search_meld_groups(hand, melds, index + 1, current_mask, current_groups, current_value)
	var meld: Array = melds[index]
	for item in meld:
		if current_mask.has(item):
			return best
	for item in meld:
		current_mask.append(item)
	current_groups.append(meld.duplicate())
	var value := 0
	for item in meld:
		value += CardTools.pip_value(hand[item].rank)
	var with_meld: Dictionary = search_meld_groups(hand, melds, index + 1, current_mask, current_groups, current_value + value)
	current_groups.pop_back()
	for item in meld:
		current_mask.erase(item)
	if int(with_meld["value"]) > int(best["value"]):
		return with_meld
	return best

static func candidate_melds(hand: Array) -> Array:
	var melds := []
	for rank in CardTools.RANKS:
		var indices := []
		for i in range(hand.size()):
			if hand[i].rank == rank:
				indices.append(i)
		if indices.size() >= 3:
			for size in range(3, indices.size() + 1):
				_add_set_melds(melds, indices, size, 0, [])
	for suit in CardTools.SUITS:
		var suited := []
		for i in range(hand.size()):
			if hand[i].suit == suit:
				suited.append(i)
		suited.sort_custom(func(a, b): return CardTools.rank_low_value(hand[a].rank) < CardTools.rank_low_value(hand[b].rank))
		for start in range(suited.size()):
			var run := [suited[start]]
			var prev := CardTools.rank_low_value(hand[suited[start]].rank)
			for pos in range(start + 1, suited.size()):
				var value := CardTools.rank_low_value(hand[suited[pos]].rank)
				if value == prev + 1:
					run.append(suited[pos])
					prev = value
					if run.size() >= 3:
						melds.append(run.duplicate())
				elif value > prev + 1:
					break
	return melds

static func _add_set_melds(melds: Array, indices: Array, target_size: int, start: int, current: Array) -> void:
	if current.size() == target_size:
		melds.append(current.duplicate())
		return
	for i in range(start, indices.size()):
		current.append(indices[i])
		_add_set_melds(melds, indices, target_size, i + 1, current)
		current.pop_back()
