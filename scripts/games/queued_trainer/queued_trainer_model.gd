class_name QueuedTrainerModel
extends RefCounted

const CardTools := preload("res://scripts/core/card_tools.gd")
const OpponentPolicy := preload("res://scripts/core/opponent_policy.gd")
const StrategyText := preload("res://scripts/core/strategy_text.gd")

var game_id := ""
var title := ""
var kind := "board"
var rules_summary := ""
var board_size := 8
var board: Array = []
var selected := Vector2i(-1, -1)
var turn := "player"
var over := false
var move_count := 0
var player_score := 0
var computer_score := 0
var last_message := ""

var deck: Array = []
var player_cards: Array = []
var bot_hands: Array = []
var current_trick: Array = []
var card_turn := 0
var card_player_count := 3
var tricks_won: Array = []
var opponent_difficulty := OpponentPolicy.DEFAULT

func set_difficulty(difficulty: String) -> void:
	opponent_difficulty = OpponentPolicy.normalize(difficulty)

func _init(p_game_id: String = "chess") -> void:
	game_id = p_game_id
	var config := config_for(game_id)
	title = config["name"]
	kind = config["kind"]
	rules_summary = config["rules"]
	board_size = int(config.get("size", 8))

func new_game() -> void:
	selected = Vector2i(-1, -1)
	turn = "player"
	over = false
	move_count = 0
	player_score = 0
	computer_score = 0
	last_message = "New %s trainer game." % title
	if kind == "card":
		_new_card_game()
	else:
		_new_board_game()

static func config_for(id: String) -> Dictionary:
	match id:
		"skat":
			return {"name": "Skat", "kind": "card", "rules": "Skat trainer: simplified three-player trick-taking with a 32-card deck. Follow suit when possible and try to win high-card tricks. Bidding, skat pickup, declarer contracts, and full point values are reserved for the deeper pass."}
		"piquet":
			return {"name": "Piquet", "kind": "card", "rules": "Piquet trainer: simplified two-player 32-card trick-taking. Follow suit, preserve entries, and compare high-card control. Declarations, repique/pique, and full scoring are reserved for the deeper pass."}
		"ombre_quadrille":
			return {"name": "Ombre / Quadrille", "kind": "card", "rules": "Ombre / Quadrille trainer: simplified historic trick-taking with three active hands. Follow suit and practice trump/entry awareness. Bidding roles, matadors, and payment scoring are reserved for the deeper pass."}
		"chess":
			return {"name": "Chess", "kind": "board", "size": 8, "rules": "Chess trainer: pieces use normal movement patterns, with a basic computer reply. This first pass omits check, checkmate, castling, en passant, and promotion details so you can practice piece mobility and captures."}
		"nine_mens_morris":
			return {"name": "Nine Men's Morris", "kind": "board", "size": 7, "rules": "Nine Men's Morris trainer: simplified placement/movement on a 7x7 board. Forming three in a row is the strategic goal; mill captures and flying are reserved for the deeper pass."}
		"reversi":
			return {"name": "Reversi", "kind": "board", "size": 8, "rules": "Reversi trainer: place discs to bracket and flip opponent discs. Corners and stable edges are strategically valuable."}
		"backgammon":
			return {"name": "Backgammon", "kind": "board", "size": 8, "rules": "Backgammon trainer: simplified race-board movement. Use the suggested move to practice advancing pieces while avoiding exposed singletons. Full dice, bars, bearing off, and doubling cube are reserved for the deeper pass."}
		"go_9x9":
			return {"name": "Go 9x9", "kind": "board", "size": 9, "rules": "Go 9x9 trainer: place stones on empty intersections. Surrounded groups are captured. This first pass omits ko, scoring territories, and life-and-death adjudication."}
		"fox_and_geese":
			return {"name": "Fox and Geese", "kind": "board", "size": 7, "rules": "Fox and Geese trainer: you play the fox. The fox moves diagonally and tries to slip through; geese move forward to trap it. Capture rules are simplified for movement practice."}
		"halma":
			return {"name": "Halma", "kind": "board", "size": 8, "rules": "Halma trainer: move or jump pieces toward the opposite corner. This first pass emphasizes route-finding and jump chains with a basic computer reply."}
		"ludo_pachisi":
			return {"name": "Ludo / Pachisi-style", "kind": "board", "size": 7, "rules": "Ludo / Pachisi-style trainer: simplified race movement around a track. Use the action button to advance a token and compare race tempo. Full safe squares, captures, and multiple players are reserved for the deeper pass."}
		"go_19x19":
			return {"name": "Go 19x19", "kind": "board", "size": 19, "rules": "Go 19x19 trainer: full-size placement practice with basic captures. This first pass is for reading shape and liberties, not full territory scoring or ko enforcement."}
	return {"name": id.capitalize(), "kind": "board", "size": 8, "rules": "Trainer module."}

func _new_board_game() -> void:
	board = []
	for y in range(board_size):
		var row := []
		for x in range(board_size):
			row.append("")
		board.append(row)
	match game_id:
		"chess":
			_setup_chess()
		"reversi":
			_setup_reversi()
		"go_9x9", "go_19x19":
			last_message = "Place a black stone. The computer answers with white."
		"fox_and_geese":
			_setup_fox_and_geese()
		"halma":
			_setup_corner_race("P", "C")
		"nine_mens_morris":
			_setup_morris()
		"ludo_pachisi", "backgammon":
			_setup_race()
		_:
			_setup_corner_race("P", "C")
	player_score = _count_side("player")
	computer_score = _count_side("computer")

func _setup_chess() -> void:
	var back := ["r", "n", "b", "q", "k", "b", "n", "r"]
	for x in range(8):
		board[0][x] = back[x]
		board[1][x] = "p"
		board[6][x] = "P"
		board[7][x] = back[x].to_upper()
	last_message = "You are uppercase. Select a piece, then a legal destination."

func _setup_reversi() -> void:
	board[3][3] = "C"
	board[3][4] = "P"
	board[4][3] = "P"
	board[4][4] = "C"
	last_message = "Place a disc where it brackets computer discs."

func _setup_fox_and_geese() -> void:
	board[6][3] = "F"
	for x in [0, 2, 4, 6]:
		board[0][x] = "G"
	for x in [1, 3, 5]:
		board[1][x] = "G"
	last_message = "You are the fox. Move diagonally to escape the geese."

func _setup_corner_race(player_piece: String, computer_piece: String) -> void:
	for y in range(2):
		for x in range(2):
			board[board_size - 1 - y][x] = player_piece
			board[y][board_size - 1 - x] = computer_piece
	last_message = "Move or jump toward the opposite corner."

func _setup_morris() -> void:
	for x in [0, 3, 6]:
		board[6][x] = "P"
		board[0][x] = "C"
	for y in [2, 4]:
		board[y][0] = "P"
		board[y][6] = "C"
	last_message = "Move pieces to form three in a row."

func _setup_race() -> void:
	board[6][0] = "P"
	board[6][1] = "P"
	board[0][6] = "C"
	board[0][5] = "C"
	last_message = "Use the action button or select a token to advance along the race path."

func press_cell(pos: Vector2i) -> void:
	if over or kind != "board":
		return
	if _is_placement_game():
		_place_player_stone(pos)
		return
	var piece: String = board[pos.y][pos.x]
	if selected.x < 0:
		if _is_player_piece(piece):
			selected = pos
		return
	var move := {"from": selected, "to": pos}
	if _move_in_list(move, legal_moves("player")):
		_apply_board_move(move)
		selected = Vector2i(-1, -1)
		move_count += 1
		_check_board_outcome()
		if not over:
			_ai_board_move()
	else:
		selected = Vector2i(-1, -1)

func take_action() -> void:
	if kind == "board" and game_id in ["ludo_pachisi", "backgammon"]:
		var moves := legal_moves("player")
		if not moves.is_empty():
			_apply_board_move(moves[0])
			move_count += 1
			_ai_board_move()

func _place_player_stone(pos: Vector2i) -> void:
	if not _in_bounds(pos) or board[pos.y][pos.x] != "":
		return
	if game_id == "reversi":
		var flips := _reversi_flips(pos, "P")
		if flips.is_empty():
			last_message = "Reversi move must flip at least one computer disc."
			return
		board[pos.y][pos.x] = "P"
		for flip in flips:
			board[flip.y][flip.x] = "P"
	else:
		board[pos.y][pos.x] = "P"
		_capture_go_neighbors(pos, "P")
	move_count += 1
	_ai_board_move()

func legal_moves(side: String) -> Array:
	if kind != "board":
		return []
	if _is_placement_game():
		return _placement_moves(side)
	var moves := []
	for y in range(board_size):
		for x in range(board_size):
			var piece: String = board[y][x]
			if side == "player" and not _is_player_piece(piece):
				continue
			if side == "computer" and not _is_computer_piece(piece):
				continue
			for to in _piece_destinations(Vector2i(x, y), piece, side):
				moves.append({"from": Vector2i(x, y), "to": to})
	return moves

func _piece_destinations(from: Vector2i, piece: String, side: String) -> Array:
	match game_id:
		"chess":
			return _chess_destinations(from, piece, side)
		"fox_and_geese":
			return _fox_geese_destinations(from, piece)
		"halma":
			return _step_jump_destinations(from, side, true)
		"ludo_pachisi", "backgammon":
			return _race_destinations(from, side)
		"nine_mens_morris":
			return _orthogonal_destinations(from, side)
	return _step_jump_destinations(from, side, false)

func _chess_destinations(from: Vector2i, piece: String, side: String) -> Array:
	var lower := piece.to_lower()
	var dirs := []
	var moves := []
	if lower == "p":
		var dy := -1 if side == "player" else 1
		var forward := Vector2i(from.x, from.y + dy)
		if _in_bounds(forward) and board[forward.y][forward.x] == "":
			moves.append(forward)
		for dx in [-1, 1]:
			var capture := Vector2i(from.x + dx, from.y + dy)
			if _in_bounds(capture) and _is_enemy_at(capture, side):
				moves.append(capture)
		return moves
	if lower == "n":
		for offset in [Vector2i(1, 2), Vector2i(2, 1), Vector2i(-1, 2), Vector2i(-2, 1), Vector2i(1, -2), Vector2i(2, -1), Vector2i(-1, -2), Vector2i(-2, -1)]:
			var to: Vector2i = from + offset
			if _in_bounds(to) and not _is_own_at(to, side):
				moves.append(to)
		return moves
	if lower in ["b", "q"]:
		dirs.append_array([Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)])
	if lower in ["r", "q"]:
		dirs.append_array([Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)])
	if lower == "k":
		for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]:
			var to: Vector2i = from + offset
			if _in_bounds(to) and not _is_own_at(to, side):
				moves.append(to)
		return moves
	for dir in dirs:
		var to: Vector2i = from + dir
		while _in_bounds(to):
			if _is_own_at(to, side):
				break
			moves.append(to)
			if _is_enemy_at(to, side):
				break
			to += dir
	return moves

func _fox_geese_destinations(from: Vector2i, piece: String) -> Array:
	var moves := []
	var dirs := [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)] if piece == "F" else [Vector2i(1, 1), Vector2i(-1, 1)]
	for dir in dirs:
		var to: Vector2i = from + dir
		if _in_bounds(to) and board[to.y][to.x] == "":
			moves.append(to)
	return moves

func _step_jump_destinations(from: Vector2i, side: String, allow_jump: bool) -> Array:
	var moves := []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var step := from + Vector2i(dx, dy)
			if _in_bounds(step) and board[step.y][step.x] == "":
				moves.append(step)
			if allow_jump:
				var jump := from + Vector2i(dx * 2, dy * 2)
				if _in_bounds(jump) and _in_bounds(step) and board[step.y][step.x] != "" and board[jump.y][jump.x] == "":
					moves.append(jump)
	return moves

func _orthogonal_destinations(from: Vector2i, side: String) -> Array:
	var moves := []
	for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var to: Vector2i = from + dir
		if _in_bounds(to) and board[to.y][to.x] == "":
			moves.append(to)
	return moves

func _race_destinations(from: Vector2i, side: String) -> Array:
	var dir := Vector2i(1, -1) if side == "player" else Vector2i(-1, 1)
	var to: Vector2i = Vector2i(clamp(from.x + dir.x, 0, board_size - 1), clamp(from.y + dir.y, 0, board_size - 1))
	return [to] if board[to.y][to.x] == "" else []

func _placement_moves(side: String) -> Array:
	var moves := []
	for y in range(board_size):
		for x in range(board_size):
			var pos := Vector2i(x, y)
			if board[y][x] != "":
				continue
			if game_id == "reversi":
				if not _reversi_flips(pos, "P" if side == "player" else "C").is_empty():
					moves.append({"to": pos})
			else:
				moves.append({"to": pos})
	return moves

func _ai_board_move() -> void:
	var moves := legal_moves("computer")
	if moves.is_empty():
		_check_board_outcome()
		return
	var move: Dictionary = _choose_computer_board_move(moves)
	if _is_placement_game():
		var to: Vector2i = move["to"]
		if game_id == "reversi":
			board[to.y][to.x] = "C"
			for flip in _reversi_flips(to, "C"):
				board[flip.y][flip.x] = "C"
		else:
			board[to.y][to.x] = "C"
			_capture_go_neighbors(to, "C")
	else:
		_apply_board_move(move)
	move_count += 1
	_check_board_outcome()

func _choose_computer_board_move(moves: Array) -> Dictionary:
	var scored := []
	for move in moves:
		scored.append({"item": move, "score": _board_move_score(move, "computer")})
	return OpponentPolicy.pick_scored(scored, opponent_difficulty)

func _board_move_score(move: Dictionary, side: String) -> float:
	if move.has("to") and not move.has("from"):
		return _placement_score(move["to"], side)
	var score := 0.0
	var from: Vector2i = move["from"]
	var to: Vector2i = move["to"]
	if _is_enemy_at(to, side):
		score += 80.0
	score += float(abs(to.x - from.x) + abs(to.y - from.y))
	var target_corner := Vector2i(0, board_size - 1) if side == "computer" else Vector2i(board_size - 1, 0)
	var from_distance: int = abs(from.x - target_corner.x) + abs(from.y - target_corner.y)
	var to_distance: int = abs(to.x - target_corner.x) + abs(to.y - target_corner.y)
	score += float(from_distance - to_distance) * 3.0
	if game_id == "chess":
		score += _chess_piece_value(str(board[to.y][to.x]))
	return score

func _placement_score(pos: Vector2i, side: String) -> float:
	if game_id == "reversi":
		var piece := "C" if side == "computer" else "P"
		var score := float(_reversi_flips(pos, piece).size())
		if (pos.x == 0 or pos.x == board_size - 1) and (pos.y == 0 or pos.y == board_size - 1):
			score += 20.0
		return score
	if game_id in ["go_9x9", "go_19x19"]:
		var center := Vector2(board_size / 2.0, board_size / 2.0)
		var distance := Vector2(pos.x, pos.y).distance_to(center)
		return 20.0 - distance
	return 0.0

func _chess_piece_value(piece: String) -> float:
	match piece.to_lower():
		"p":
			return 1.0
		"n", "b":
			return 3.0
		"r":
			return 5.0
		"q":
			return 9.0
		"k":
			return 100.0
	return 0.0

func _apply_board_move(move: Dictionary) -> void:
	var from: Vector2i = move["from"]
	var to: Vector2i = move["to"]
	var piece: String = board[from.y][from.x]
	board[from.y][from.x] = ""
	board[to.y][to.x] = piece
	last_message = "Moved %s to %s." % [piece, square_name(to)]

func _check_board_outcome() -> void:
	player_score = _count_side("player")
	computer_score = _count_side("computer")
	if player_score == 0 or computer_score == 0:
		over = true
		last_message = "Game over by material."

func _reversi_flips(pos: Vector2i, piece: String) -> Array:
	var enemy := "C" if piece == "P" else "P"
	var flips := []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var line := []
			var at := pos + Vector2i(dx, dy)
			while _in_bounds(at) and board[at.y][at.x] == enemy:
				line.append(at)
				at += Vector2i(dx, dy)
			if _in_bounds(at) and board[at.y][at.x] == piece and not line.is_empty():
				flips.append_array(line)
	return flips

func _capture_go_neighbors(pos: Vector2i, piece: String) -> void:
	if not game_id in ["go_9x9", "go_19x19"]:
		return
	var enemy := "C" if piece == "P" else "P"
	for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var neighbor: Vector2i = pos + dir
		if _in_bounds(neighbor) and board[neighbor.y][neighbor.x] == enemy and _group_liberties(neighbor).is_empty():
			for stone in _group_stones(neighbor):
				board[stone.y][stone.x] = ""

func _group_stones(start: Vector2i) -> Array:
	var piece: String = board[start.y][start.x]
	var seen := []
	var stack := [start]
	while not stack.is_empty():
		var pos: Vector2i = stack.pop_back()
		if seen.has(pos):
			continue
		seen.append(pos)
		for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next: Vector2i = pos + dir
			if _in_bounds(next) and board[next.y][next.x] == piece and not seen.has(next):
				stack.append(next)
	return seen

func _group_liberties(start: Vector2i) -> Array:
	var liberties := []
	for stone in _group_stones(start):
		for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next: Vector2i = stone + dir
			if _in_bounds(next) and board[next.y][next.x] == "" and not liberties.has(next):
				liberties.append(next)
	return liberties

func _new_card_game() -> void:
	card_player_count = 2 if game_id == "piquet" else 3
	deck = _make_trainer_deck(game_id)
	deck.shuffle()
	player_cards = []
	bot_hands = []
	current_trick = []
	card_turn = 0
	tricks_won = []
	for i in range(card_player_count):
		tricks_won.append(0)
	for i in range(card_player_count - 1):
		bot_hands.append([])
	var hand_size := 10 if game_id == "skat" else 12
	for i in range(hand_size):
		player_cards.append(CardTools.draw_card(deck))
		for bot in bot_hands:
			bot.append(CardTools.draw_card(deck))
	player_cards.sort_custom(CardTools.sort_cards)
	for bot in bot_hands:
		bot.sort_custom(CardTools.sort_cards)
	last_message = "Play a legal card. Follow suit when possible."

func _make_trainer_deck(id: String) -> Array:
	var ranks := ["7", "8", "9", "10", "J", "Q", "K", "A"]
	if id == "ombre_quadrille":
		ranks = ["6", "7", "8", "9", "10", "J", "Q", "K", "A"]
	var cards := []
	for suit in CardTools.SUITS:
		for rank in ranks:
			cards.append({"rank": rank, "suit": suit})
	return cards

func legal_cards() -> Array:
	if current_trick.is_empty():
		return player_cards.duplicate()
	var lead_suit: String = current_trick[0]["card"].suit
	var matching := []
	for card in player_cards:
		if card.suit == lead_suit:
			matching.append(card)
	return matching if not matching.is_empty() else player_cards.duplicate()

func play_card(card: Dictionary) -> String:
	if kind != "card" or over:
		return ""
	if not legal_cards().has(card):
		return "You must follow suit if you can."
	player_cards.erase(card)
	current_trick.append({"player": 0, "card": card})
	while current_trick.size() < card_player_count:
		var bot_index := current_trick.size() - 1
		var bot_card := _pick_bot_card(bot_hands[bot_index])
		bot_hands[bot_index].erase(bot_card)
		current_trick.append({"player": bot_index + 1, "card": bot_card})
	_score_card_trick()
	if player_cards.is_empty():
		over = true
		last_message = "Hand complete."
	return ""

func _pick_bot_card(hand: Array) -> Dictionary:
	var legal := hand.duplicate()
	if not current_trick.is_empty():
		var lead_suit: String = current_trick[0]["card"].suit
		var matching := []
		for card in hand:
			if card.suit == lead_suit:
				matching.append(card)
		if not matching.is_empty():
			legal = matching
	var scored := []
	for card in legal:
		scored.append({"item": card, "score": _bot_card_choice_score(card)})
	return OpponentPolicy.pick_scored(scored, opponent_difficulty)

func _bot_card_choice_score(card: Dictionary) -> float:
	if current_trick.is_empty():
		return -float(CardTools.rank_value(card.rank))
	var lead_suit: String = current_trick[0]["card"].suit
	var best := 0
	for play in current_trick:
		var played: Dictionary = play["card"]
		if played.suit == lead_suit:
			best = max(best, CardTools.rank_value(played.rank))
	var power := CardTools.rank_value(card.rank) if card.suit == lead_suit else 0
	if power > best:
		return 1000.0 - float(power)
	return -float(CardTools.rank_value(card.rank))

func _score_card_trick() -> void:
	var lead_suit: String = current_trick[0]["card"].suit
	var winner := 0
	var best := 0
	for play in current_trick:
		var card: Dictionary = play["card"]
		var power := CardTools.rank_value(card.rank) if card.suit == lead_suit else 0
		if power > best:
			best = power
			winner = int(play["player"])
	tricks_won[winner] = int(tricks_won[winner]) + 1
	last_message = "Trick won by %s." % ("you" if winner == 0 else "computer %d" % winner)
	current_trick = []

func score_text() -> String:
	if kind == "card":
		var parts := ["You: %d" % int(tricks_won[0])]
		for i in range(1, tricks_won.size()):
			parts.append("Computer %d: %d" % [i, int(tricks_won[i])])
		return "Tricks - %s" % CardTools.join_strings(parts, "  ")
	return "Material - You: %d  Computer: %d  Moves: %d" % [player_score, computer_score, move_count]

func table_text() -> String:
	if kind == "card":
		return "%s\nCurrent trick: %s\nCards left: you %d" % [score_text(), _trick_text(), player_cards.size()]
	return "%s\n%s" % [score_text(), last_message]

func guidance_text() -> String:
	if over:
		return StrategyText.review("Trainer round complete.", "Compare your suggested moves with the final material or trick count.", "Replay and focus on one opening principle.")
	if kind == "card":
		var legal := legal_cards()
		var suggestion: Dictionary = legal[0] if not legal.is_empty() else {}
		return StrategyText.advice(
			"Play %s." % CardTools.card_text(suggestion) if suggestion.size() > 0 else "No legal card.",
			"Follow suit first; then preserve high cards unless they win a useful trick.",
			"Historic trick games become easier when you track the led suit and entries."
		)
	if game_id in ["go_9x9", "go_19x19"]:
		return StrategyText.advice("Place a stone with liberties.", "Corners and sides are easier to stabilize than the center.", "Do not fill your own last liberty unless it captures.")
	if game_id == "reversi":
		return StrategyText.advice("Play a legal flipping move.", "Corners and stable edges matter more than early disc count.", "Avoid giving the computer an easy corner.")
	var best := best_player_move()
	return StrategyText.advice(
		"Move %s." % move_text(best) if not best.is_empty() else "No legal move.",
		"Prefer moves that advance, capture, or increase mobility.",
		"Use the highlighted suggestion as a tactical prompt, not a perfect engine."
	)

func best_player_move() -> Dictionary:
	var moves := legal_moves("player")
	return moves[0] if not moves.is_empty() else {}

func move_text(move: Dictionary) -> String:
	if move.is_empty():
		return "none"
	return "%s to %s" % [square_name(move["from"]), square_name(move["to"])]

func cell_text(pos: Vector2i) -> String:
	return str(board[pos.y][pos.x])

func square_name(pos: Vector2i) -> String:
	var files := ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S"]
	return "%s%d" % [files[pos.x], board_size - pos.y]

func _trick_text() -> String:
	var parts := []
	for play in current_trick:
		parts.append("%s %s" % ["You" if int(play["player"]) == 0 else "Computer %d" % int(play["player"]), CardTools.card_text(play["card"])])
	return CardTools.join_strings(parts, " | ")

func _is_placement_game() -> bool:
	return game_id in ["go_9x9", "go_19x19", "reversi"]

func _is_player_piece(piece: String) -> bool:
	return piece != "" and (piece == "P" or piece == "F" or piece == piece.to_upper() and game_id == "chess")

func _is_computer_piece(piece: String) -> bool:
	return piece != "" and (piece == "C" or piece == "G" or piece == piece.to_lower() and game_id == "chess")

func _is_own_at(pos: Vector2i, side: String) -> bool:
	var piece: String = board[pos.y][pos.x]
	return _is_player_piece(piece) if side == "player" else _is_computer_piece(piece)

func _is_enemy_at(pos: Vector2i, side: String) -> bool:
	var piece: String = board[pos.y][pos.x]
	return _is_computer_piece(piece) if side == "player" else _is_player_piece(piece)

func _move_in_list(move: Dictionary, moves: Array) -> bool:
	for candidate in moves:
		if candidate.has("from") and candidate["from"] == move["from"] and candidate["to"] == move["to"]:
			return true
	return false

func _count_side(side: String) -> int:
	var count := 0
	for row in board:
		for piece in row:
			if side == "player" and _is_player_piece(str(piece)):
				count += 1
			elif side == "computer" and _is_computer_piece(str(piece)):
				count += 1
	return count

func _in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < board_size and pos.y >= 0 and pos.y < board_size
