class_name CardTools
extends RefCounted

const SUITS := ["S", "H", "D", "C"]
const RANKS := ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]

static func make_deck() -> Array:
	var deck: Array = []
	for suit in SUITS:
		for rank in RANKS:
			deck.append({"rank": rank, "suit": suit})
	deck.shuffle()
	return deck

static func card_text(card: Dictionary) -> String:
	return "%s%s" % [card.rank, card.suit]

static func cards_text(cards: Array) -> String:
	var names := []
	for card in cards:
		names.append(card_text(card))
	return join_strings(names, " ")

static func rank_value(rank: String) -> int:
	if rank == "A":
		return 14
	if rank == "K":
		return 13
	if rank == "Q":
		return 12
	if rank == "J":
		return 11
	return int(rank)

static func rank_low_value(rank: String) -> int:
	if rank == "A":
		return 1
	if rank == "K":
		return 13
	if rank == "Q":
		return 12
	if rank == "J":
		return 11
	return int(rank)

static func pip_value(rank: String) -> int:
	if rank in ["K", "Q", "J"]:
		return 10
	if rank == "A":
		return 1
	return int(rank)

static func draw_card(deck: Array) -> Dictionary:
	return deck.pop_back()

static func join_strings(parts: Array, separator: String) -> String:
	var text_parts: Array = []
	for part in parts:
		text_parts.append(str(part))
	return separator.join(text_parts)

static func sort_cards(a: Dictionary, b: Dictionary) -> bool:
	if a.suit == b.suit:
		return rank_value(a.rank) < rank_value(b.rank)
	return SUITS.find(a.suit) < SUITS.find(b.suit)

static func is_red_suit(suit: String) -> bool:
	return suit == "H" or suit == "D"

