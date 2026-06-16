class_name CheckersModel
extends RefCounted

const StrategyText := preload("res://scripts/core/strategy_text.gd")
const OpponentPolicy := preload("res://scripts/core/opponent_policy.gd")

var board: Array = []
var selected := Vector2i(-1, -1)
var turn := "r"
var over := false
var last_message := ""
var last_player_move := ""
var last_computer_move := ""
var player_wins := 0
var computer_wins := 0
var opponent_difficulty := OpponentPolicy.DEFAULT

func set_difficulty(difficulty: String) -> void:
	opponent_difficulty = OpponentPolicy.normalize(difficulty)

func new_game() -> void:
	board = []
	selected = Vector2i(-1, -1)
	turn = "r"
	over = false
	last_player_move = ""
	last_computer_move = ""
	last_message = "Your move. Captures are forced. Coach tip: trades are often good when you are ahead in material."
	for y in range(8):
		var row := []
		for x in range(8):
			var piece := ""
			if (x + y) % 2 == 1:
				if y < 3:
					piece = "b"
				elif y > 4:
					piece = "r"
			row.append(piece)
		board.append(row)

func press_square(pos: Vector2i) -> bool:
	if over or turn != "r":
		return false
	var piece: String = board[pos.y][pos.x]
	if piece.begins_with("r"):
		selected = pos
		return false
	if selected.x >= 0:
		var move := {"from": selected, "to": pos}
		if is_legal_move(move, "r"):
			apply_move(move)
			last_player_move = move_text(move)
			selected = Vector2i(-1, -1)
			turn = "b"
			finish_if_needed()
			return true
	return false

func ai_move() -> void:
	if over:
		return
	var moves := legal_moves("b")
	if moves.is_empty():
		over = true
		player_wins += 1
		last_message = "You win. The computer has no legal moves."
		return
	var move := _choose_ai_move(moves)
	apply_move(move)
	last_computer_move = move_text(move)
	turn = "r"
	finish_if_needed()

func _choose_ai_move(moves: Array) -> Dictionary:
	var scored := []
	for move in moves:
		scored.append({"item": move, "score": move_score(move, "b")})
	return OpponentPolicy.pick_scored(scored, opponent_difficulty)

func move_score(move: Dictionary, side: String) -> int:
	var score := 0
	if move.has("capture"):
		score += 100
	var to: Vector2i = move["to"]
	var from: Vector2i = move["from"]
	var piece: String = board[from.y][from.x]
	if _move_promotes(move, side):
		score += 60
	if piece == side.to_upper():
		score += 15
	var center_distance: int = abs(to.x - 3) + abs(to.y - 3)
	score += max(0, 8 - center_distance)
	score += to.y if side == "b" else 7 - to.y
	if _landing_vulnerable(move, side):
		score -= 35
	if side == "r" and from.y == 7 and not move.has("capture"):
		score -= 8
	elif side == "b" and from.y == 0 and not move.has("capture"):
		score -= 8
	return score

func legal_moves(side: String) -> Array:
	var captures: Array = []
	var normals: Array = []
	for y in range(8):
		for x in range(8):
			var piece: String = board[y][x]
			if not piece.begins_with(side):
				continue
			for dir in dirs(piece):
				var mid := Vector2i(x + dir.x, y + dir.y)
				var to := Vector2i(x + dir.x * 2, y + dir.y * 2)
				if in_bounds(to) and in_bounds(mid):
					var mid_piece: String = board[mid.y][mid.x]
					if mid_piece != "" and not mid_piece.begins_with(side) and board[to.y][to.x] == "":
						captures.append({"from": Vector2i(x, y), "to": to, "capture": mid})
				var step := Vector2i(x + dir.x, y + dir.y)
				if in_bounds(step) and board[step.y][step.x] == "":
					normals.append({"from": Vector2i(x, y), "to": step})
	return captures if not captures.is_empty() else normals

func is_legal_move(move: Dictionary, side: String) -> bool:
	for legal in legal_moves(side):
		if legal["from"] == move["from"] and legal["to"] == move["to"]:
			if legal.has("capture"):
				move["capture"] = legal["capture"]
			return true
	return false

func apply_move(move: Dictionary) -> void:
	var from: Vector2i = move["from"]
	var to: Vector2i = move["to"]
	var piece: String = board[from.y][from.x]
	board[from.y][from.x] = ""
	if move.has("capture"):
		var capture: Vector2i = move["capture"]
		board[capture.y][capture.x] = ""
	if piece == "r" and to.y == 0:
		piece = "R"
	elif piece == "b" and to.y == 7:
		piece = "B"
	board[to.y][to.x] = piece

func dirs(piece: String) -> Array:
	if piece == "R" or piece == "B":
		return [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]
	if piece == "r":
		return [Vector2i(-1, -1), Vector2i(1, -1)]
	return [Vector2i(-1, 1), Vector2i(1, 1)]

func in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < 8 and pos.y >= 0 and pos.y < 8

func finish_if_needed() -> bool:
	var red := 0
	var black := 0
	for row in board:
		for piece in row:
			if String(piece).begins_with("r"):
				red += 1
			elif String(piece).begins_with("b"):
				black += 1
	if red == 0 or legal_moves("r").is_empty():
		over = true
		computer_wins += 1
		last_message = "Computer wins."
	elif black == 0 or legal_moves("b").is_empty():
		over = true
		player_wins += 1
		last_message = "You win."
	else:
		last_message = "Your move. Captures are forced. Coach tip: trades are often good when you are ahead in material."
		return false
	return true

func reset_score() -> void:
	player_wins = 0
	computer_wins = 0

func score_text() -> String:
	return "Score - You: %d  Computer: %d" % [player_wins, computer_wins]

func guidance_text() -> String:
	if over:
		return StrategyText.advice(
			"Start a new game.",
			"Review whether captures, promotion races, or exposed landings decided the game.",
			"Checkers rewards forcing sequences more than isolated one-square moves."
		)
	if turn != "r":
		return StrategyText.advice(
			"Watch the computer move.",
			"Look for whether it captures, advances toward kinging, or leaves a piece vulnerable.",
			"The next useful question is whether you have a forced capture."
		)
	var moves := legal_moves("r")
	if moves.is_empty():
		return StrategyText.advice("No legal moves available.")
	var captures := []
	for move in moves:
		if move.has("capture"):
			captures.append(move)
	var best := best_move_for("r")
	var capture_note := "Captures are forced, so choose the capture with the best follow-up." if not captures.is_empty() else "No capture is forced, so improve position without giving back material."
	return StrategyText.advice(
		"Move %s." % move_text(best),
		move_reason(best, "r"),
		capture_note,
		"After choosing, scan whether the landing square can be captured."
	)

func best_move_for(side: String) -> Dictionary:
	var moves := legal_moves(side)
	if moves.is_empty():
		return {}
	moves.sort_custom(func(a, b): return move_score(a, side) > move_score(b, side))
	return moves[0]

func move_summary_text() -> String:
	var player_text := "none" if last_player_move == "" else last_player_move
	var computer_text := "none" if last_computer_move == "" else last_computer_move
	return "Last moves - You: %s  Computer: %s" % [player_text, computer_text]

func move_text(move: Dictionary) -> String:
	var from: Vector2i = move["from"]
	var to: Vector2i = move["to"]
	var capture_text := " capture" if move.has("capture") else ""
	return "%s to %s%s" % [square_name(from), square_name(to), capture_text]

func move_reason(move: Dictionary, side: String) -> String:
	var parts := []
	if move.has("capture"):
		parts.append("it wins material")
	if _move_promotes(move, side):
		parts.append("it promotes to a king")
	var to: Vector2i = move["to"]
	if to.x >= 2 and to.x <= 5 and to.y >= 2 and to.y <= 5:
		parts.append("it moves toward the center")
	if _landing_vulnerable(move, side):
		parts.append("but the landing square may be vulnerable")
	if parts.is_empty():
		parts.append("it advances while keeping future captures in view")
	return "This move %s." % ", ".join(parts)

func _move_promotes(move: Dictionary, side: String) -> bool:
	var from: Vector2i = move["from"]
	var to: Vector2i = move["to"]
	var piece: String = board[from.y][from.x]
	return piece == side and ((side == "r" and to.y == 0) or (side == "b" and to.y == 7))

func _landing_vulnerable(move: Dictionary, side: String) -> bool:
	var to: Vector2i = move["to"]
	var from: Vector2i = move["from"]
	var enemy_side := "b" if side == "r" else "r"
	for dir in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
		var enemy_pos: Vector2i = to - dir
		var landing: Vector2i = to + dir
		if not in_bounds(enemy_pos) or not in_bounds(landing):
			continue
		var enemy_piece := _piece_after_move(enemy_pos, move)
		if enemy_piece == "" or not enemy_piece.begins_with(enemy_side):
			continue
		if not dirs(enemy_piece).has(dir):
			continue
		if _piece_after_move(landing, move) == "":
			return true
	return false

func _piece_after_move(pos: Vector2i, move: Dictionary) -> String:
	var from: Vector2i = move["from"]
	var to: Vector2i = move["to"]
	if pos == from:
		return ""
	if move.has("capture"):
		var capture: Vector2i = move["capture"]
		if pos == capture:
			return ""
	if pos == to:
		var piece: String = board[from.y][from.x]
		if piece == "r" and to.y == 0:
			return "R"
		if piece == "b" and to.y == 7:
			return "B"
		return piece
	return board[pos.y][pos.x]

func square_name(pos: Vector2i) -> String:
	var files := ["A", "B", "C", "D", "E", "F", "G", "H"]
	return "%s%d" % [files[pos.x], 8 - pos.y]

func piece_text(piece: String) -> String:
	match piece:
		"r":
			return "r"
		"R":
			return "R"
		"b":
			return "b"
		"B":
			return "B"
	return ""
