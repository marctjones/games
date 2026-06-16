class_name BasicRummyModel
extends "res://scripts/games/rummy_500/rummy_500_model.gd"

const TARGET_SCORE := 100

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
	last_message = "Draw one card, make sets/runs when you can, then discard one card. First player out scores the opponent's cards."
	last_bot_action = "Computer has not moved yet."
	last_drawn_card = {}
	last_drawn_cards = []
	last_draw_source = ""
	required_pickup_card = {}
	allow_discard_pile_pickup = false
	player_hand_points = 0
	computer_hand_points = 0
	for i in range(10):
		player.append(CardTools.draw_card(deck))
		bot.append(CardTools.draw_card(deck))
	discard.append(CardTools.draw_card(deck))
	player.sort_custom(CardTools.sort_cards)
	bot.sort_custom(CardTools.sort_cards)

func finish_hand(reason: String) -> void:
	if done:
		return
	done = true
	phase = "done"
	var player_deadwood: int = RummyTools.hand_points(player)
	var computer_deadwood: int = RummyTools.hand_points(bot)
	var player_delta := 0
	var computer_delta := 0
	if player.is_empty():
		player_delta = computer_deadwood
	elif bot.is_empty():
		computer_delta = player_deadwood
	elif player_deadwood < computer_deadwood:
		player_delta = computer_deadwood - player_deadwood
	elif computer_deadwood < player_deadwood:
		computer_delta = player_deadwood - computer_deadwood
	player_score += player_delta
	computer_score += computer_delta
	hands_played += 1
	last_message = "%s Hand scored. You: +%d, Computer: +%d. First to %d wins the match." % [reason, player_delta, computer_delta, TARGET_SCORE]

func score_text() -> String:
	return "Score to %d - You: %d  Computer: %d  Hands: %d" % [TARGET_SCORE, player_score, computer_score, hands_played]

func guidance_text() -> String:
	if done:
		return StrategyText.advice(
			"Start a new hand.",
			"Basic Rummy rewards going out while leaving the opponent with points.",
			"Review whether you held too many cards for a future meld instead of reducing hand value."
		)
	if phase == "draw":
		if discard.is_empty():
			return StrategyText.advice("Draw stock.", "No discard is visible.", "After drawing, prefer lowering deadwood over chasing distant melds.")
		return RummyTools.draw_decision_text(player, discard[-1])
	if phase == "act":
		return RummyTools.action_phase_text(player, selected, player_melds, bot_melds)
	return StrategyText.advice("Watch the computer turn.", "It is trying to reduce remaining hand points.", "The discard it leaves is often a clue about what ranks or suits are not helping it.")
