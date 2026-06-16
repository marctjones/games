class_name GameCatalog
extends RefCounted

const GAMES := [
	{"id": "hearts", "name": "Hearts", "status": "playable", "icon": "res://assets/icons/hearts.svg"},
	{"id": "blackjack", "name": "Blackjack", "status": "playable", "icon": "res://assets/icons/blackjack.svg"},
	{"id": "cribbage", "name": "Cribbage", "status": "playable", "icon": "res://assets/icons/cribbage.svg"},
	{"id": "gin_rummy", "name": "Gin Rummy", "status": "playable", "icon": "res://assets/icons/gin_rummy.svg"},
	{"id": "rummy_500", "name": "Rummy 500", "status": "playable", "icon": "res://assets/icons/gin_rummy.svg"},
	{"id": "klondike", "name": "Klondike Solitaire", "status": "playable", "icon": "res://assets/icons/gin_rummy.svg"},
	{"id": "five_card_draw", "name": "Five-Card Draw Poker", "status": "playable", "icon": "res://assets/icons/five_card_draw.svg"},
	{"id": "texas_holdem", "name": "Texas Hold'em", "status": "playable", "icon": "res://assets/icons/five_card_draw.svg"},
	{"id": "rummy", "name": "Basic Rummy", "status": "playable", "icon": "res://assets/icons/gin_rummy.svg"},
	{"id": "euchre", "name": "Euchre", "status": "playable", "icon": "res://assets/icons/hearts.svg"},
	{"id": "spades", "name": "Spades", "status": "playable", "icon": "res://assets/icons/hearts.svg"},
	{"id": "bridge", "name": "Bridge Trainer", "status": "playable", "icon": "res://assets/icons/hearts.svg"},
	{"id": "pinochle", "name": "Pinochle", "status": "playable", "icon": "res://assets/icons/hearts.svg"},
	{"id": "whist", "name": "Whist", "status": "playable", "icon": "res://assets/icons/hearts.svg"},
	{"id": "canasta", "name": "Canasta", "status": "playable", "icon": "res://assets/icons/gin_rummy.svg"},
	{"id": "skat", "name": "Skat", "status": "playable", "icon": "res://assets/icons/hearts.svg"},
	{"id": "piquet", "name": "Piquet", "status": "playable", "icon": "res://assets/icons/hearts.svg"},
	{"id": "ombre_quadrille", "name": "Ombre / Quadrille", "status": "playable", "icon": "res://assets/icons/hearts.svg"},
	{"id": "tic_tac_toe", "name": "Tic-tac-toe", "status": "playable", "icon": "res://assets/icons/tic_tac_toe.svg"},
	{"id": "checkers", "name": "Checkers / Draughts", "status": "playable", "icon": "res://assets/icons/checkers.svg"},
	{"id": "chess", "name": "Chess", "status": "playable", "icon": "res://assets/icons/checkers.svg"},
	{"id": "nine_mens_morris", "name": "Nine Men's Morris", "status": "playable", "icon": "res://assets/icons/checkers.svg"},
	{"id": "reversi", "name": "Reversi", "status": "playable", "icon": "res://assets/icons/checkers.svg"},
	{"id": "backgammon", "name": "Backgammon", "status": "playable", "icon": "res://assets/icons/checkers.svg"},
	{"id": "go_9x9", "name": "Go 9x9", "status": "playable", "icon": "res://assets/icons/checkers.svg"},
	{"id": "fox_and_geese", "name": "Fox and Geese", "status": "playable", "icon": "res://assets/icons/checkers.svg"},
	{"id": "halma", "name": "Halma", "status": "playable", "icon": "res://assets/icons/checkers.svg"},
	{"id": "ludo_pachisi", "name": "Ludo / Pachisi-style", "status": "playable", "icon": "res://assets/icons/checkers.svg"},
	{"id": "go_19x19", "name": "Go 19x19", "status": "playable", "icon": "res://assets/icons/checkers.svg"}
]

static func all() -> Array:
	return GAMES

static func name_for(game_id: String) -> String:
	for game in GAMES:
		if game["id"] == game_id:
			return game["name"]
	return game_id

static func playable_names() -> Array:
	var names := []
	for game in GAMES:
		if game["status"] == "playable":
			names.append(game["name"])
	return names

static func home_status_text() -> String:
	return "Playable now: %s. These are multiplayer tabletop games configured for one human player against honest computer opponents. No catalog entries are placeholders; the next roadmap layer is fuller rules, stronger non-cheating AI, and deeper coaching." % human_join(playable_names())

static func human_join(items: Array) -> String:
	if items.is_empty():
		return ""
	if items.size() == 1:
		return items[0]
	if items.size() == 2:
		return "%s and %s" % [items[0], items[1]]
	var leading := items.slice(0, items.size() - 1)
	return "%s, and %s" % [", ".join(leading), items[-1]]
