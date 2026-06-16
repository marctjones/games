class_name KlondikeModel
extends RefCounted

const CardTools := preload("res://scripts/core/card_tools.gd")
const StrategyText := preload("res://scripts/core/strategy_text.gd")

var stock: Array = []
var waste: Array = []
var foundations := {"S": [], "H": [], "D": [], "C": []}
var tableau: Array = []
var selected := {}
var moves := 0
var games_won := 0
var last_message := ""

func new_game() -> void:
	var deck := CardTools.make_deck()
	stock = []
	waste = []
	foundations = {"S": [], "H": [], "D": [], "C": []}
	tableau = []
	selected = {}
	moves = 0
	for col in range(7):
		tableau.append([])
		for row in range(col + 1):
			var card := CardTools.draw_card(deck)
			card["face_up"] = row == col
			tableau[col].append(card)
	while not deck.is_empty():
		var card := CardTools.draw_card(deck)
		card["face_up"] = false
		stock.append(card)
	last_message = "Draw from the stock or move face-up tableau cards. Build foundations from ace to king."

func draw_stock() -> void:
	selected = {}
	if stock.is_empty():
		if waste.is_empty():
			last_message = "Stock and waste are empty."
			return
		while not waste.is_empty():
			var recycled: Dictionary = waste.pop_back()
			recycled["face_up"] = false
			stock.append(recycled)
		moves += 1
		last_message = "Recycled the waste back into the stock."
		return
	var card: Dictionary = stock.pop_back()
	card["face_up"] = true
	waste.append(card)
	moves += 1
	last_message = "Drew %s to the waste." % CardTools.card_text(card)

func select_waste() -> void:
	if waste.is_empty():
		return
	selected = {"kind": "waste"}
	last_message = "Selected waste card %s." % CardTools.card_text(waste[-1])

func select_tableau(col: int, index: int) -> void:
	if col < 0 or col >= tableau.size() or index < 0 or index >= tableau[col].size():
		return
	var card: Dictionary = tableau[col][index]
	if not bool(card.get("face_up", false)):
		return
	selected = {"kind": "tableau", "col": col, "index": index}
	last_message = "Selected %s from column %d." % [CardTools.card_text(card), col + 1]

func move_selected_to_foundation(suit: String) -> bool:
	var cards := selected_cards()
	if cards.size() != 1:
		last_message = "Only one card at a time can move to a foundation."
		return false
	var card: Dictionary = cards[0]
	if card.suit != suit or not can_move_to_foundation(card, suit):
		last_message = "%s cannot move to the %s foundation yet." % [CardTools.card_text(card), suit]
		return false
	_remove_selected_cards()
	foundations[suit].append(card)
	selected = {}
	moves += 1
	_reveal_tableau_tops()
	_check_win()
	last_message = "Moved %s to a foundation." % CardTools.card_text(card)
	return true

func move_selected_to_tableau(target_col: int) -> bool:
	if selected.is_empty() or target_col < 0 or target_col >= tableau.size():
		return false
	if selected.get("kind", "") == "tableau" and int(selected.get("col", -1)) == target_col:
		return false
	var cards := selected_cards()
	if cards.is_empty():
		return false
	if not can_move_to_tableau(cards[0], target_col):
		last_message = "%s cannot move to column %d." % [CardTools.card_text(cards[0]), target_col + 1]
		return false
	_remove_selected_cards()
	for card in cards:
		card["face_up"] = true
		tableau[target_col].append(card)
	selected = {}
	moves += 1
	_reveal_tableau_tops()
	last_message = "Moved %s to column %d." % [CardTools.cards_text(cards), target_col + 1]
	return true

func selected_cards() -> Array:
	if selected.is_empty():
		return []
	if selected.get("kind", "") == "waste":
		return [waste[-1]] if not waste.is_empty() else []
	if selected.get("kind", "") == "tableau":
		var col := int(selected["col"])
		var index := int(selected["index"])
		return tableau[col].slice(index)
	return []

func can_move_to_foundation(card: Dictionary, suit: String) -> bool:
	var pile: Array = foundations[suit]
	if pile.is_empty():
		return card.rank == "A"
	return CardTools.rank_low_value(card.rank) == CardTools.rank_low_value(pile[-1].rank) + 1

func can_move_to_tableau(card: Dictionary, target_col: int) -> bool:
	var pile: Array = tableau[target_col]
	if pile.is_empty():
		return card.rank == "K"
	var top: Dictionary = pile[-1]
	if not bool(top.get("face_up", false)):
		return false
	return CardTools.is_red_suit(card.suit) != CardTools.is_red_suit(top.suit) and CardTools.rank_low_value(card.rank) + 1 == CardTools.rank_low_value(top.rank)

func _remove_selected_cards() -> void:
	if selected.get("kind", "") == "waste":
		waste.pop_back()
	elif selected.get("kind", "") == "tableau":
		var col := int(selected["col"])
		var index := int(selected["index"])
		tableau[col] = tableau[col].slice(0, index)

func _reveal_tableau_tops() -> void:
	for column in tableau:
		if not column.is_empty():
			column[-1]["face_up"] = true

func _check_win() -> void:
	var total := 0
	for suit in foundations.keys():
		total += foundations[suit].size()
	if total == 52:
		games_won += 1
		last_message = "You completed all foundations."

func hint_text() -> String:
	var reveal_move := _find_reveal_move()
	if not reveal_move.is_empty():
		return StrategyText.advice(
			"Move %s from column %d to column %d." % [
				CardTools.cards_text(reveal_move["cards"]),
				int(reveal_move["from"]) + 1,
				int(reveal_move["to"]) + 1
			],
			"Revealing face-down tableau cards is usually the highest-value Klondike progress.",
			"Prefer moves that uncover hidden cards over moves that only rearrange visible cards."
		)
	var waste_card: Dictionary = waste[-1] if not waste.is_empty() else {}
	if waste_card.size() > 0:
		for suit in CardTools.SUITS:
			if can_move_to_foundation(waste_card, suit):
				return StrategyText.advice(
					"Move %s from waste to its foundation." % CardTools.card_text(waste_card),
					"Foundation moves with aces, twos, and safe low cards unlock later progress.",
					"Do not bury a playable waste card when it can immediately advance a foundation."
				)
		for col in range(7):
			if can_move_to_tableau(waste_card, col):
				return StrategyText.advice(
					"Move %s from waste to tableau column %d." % [CardTools.card_text(waste_card), col + 1],
					"Using the waste card opens access to the next stock cycle and may build a longer sequence.",
					"Check whether the move creates a useful alternating-color chain."
				)
	for col in range(7):
		if tableau[col].is_empty():
			continue
		var top: Dictionary = tableau[col][-1]
		if not bool(top.get("face_up", false)):
			continue
		for suit in CardTools.SUITS:
			if can_move_to_foundation(top, suit):
				return StrategyText.advice(
					"Move %s from column %d to a foundation." % [CardTools.card_text(top), col + 1],
					"A tableau foundation move clears a column top and may expose another move.",
					"Be careful with higher cards if they are still needed to hold opposite-color stacks."
				)
	var king_move := _find_useful_king_move()
	if not king_move.is_empty():
		return StrategyText.advice(
			"Move %s to empty column %d." % [CardTools.cards_text(king_move["cards"]), int(king_move["to"]) + 1],
			"Empty columns are most valuable when a king move reveals a hidden card or relocates a long sequence.",
			"Do not fill an empty column with a king unless it creates new access."
		)
	return StrategyText.advice(
		"Draw from the stock.",
		"No high-priority tableau, foundation, or waste move is visible.",
		"After each draw, re-check waste-to-foundation and waste-to-tableau before cycling again."
	)

func _find_reveal_move() -> Dictionary:
	for from_col in range(7):
		for index in range(tableau[from_col].size()):
			var card: Dictionary = tableau[from_col][index]
			if not bool(card.get("face_up", false)):
				continue
			if index == 0 or bool(tableau[from_col][index - 1].get("face_up", false)):
				continue
			for target_col in range(7):
				if target_col == from_col:
					continue
				if can_move_to_tableau(card, target_col):
					return {
						"from": from_col,
						"to": target_col,
						"cards": tableau[from_col].slice(index)
					}
	return {}

func _find_useful_king_move() -> Dictionary:
	for target_col in range(7):
		if not tableau[target_col].is_empty():
			continue
		for from_col in range(7):
			if from_col == target_col:
				continue
			for index in range(tableau[from_col].size()):
				var card: Dictionary = tableau[from_col][index]
				if card.rank != "K" or not bool(card.get("face_up", false)):
					continue
				if index > 0 and not bool(tableau[from_col][index - 1].get("face_up", false)):
					return {
						"from": from_col,
						"to": target_col,
						"cards": tableau[from_col].slice(index)
					}
	return {}

func score_text() -> String:
	var foundation_count := 0
	for suit in foundations.keys():
		foundation_count += foundations[suit].size()
	return "Foundations: %d/52  Moves: %d  Wins: %d" % [foundation_count, moves, games_won]

func table_text() -> String:
	return "Stock: %d | Waste: %d | %s" % [stock.size(), waste.size(), score_text()]
