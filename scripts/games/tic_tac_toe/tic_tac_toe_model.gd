class_name TicTacToeModel
extends RefCounted

const StrategyText := preload("res://scripts/core/strategy_text.gd")

const WIN_LINES := [
	[0, 1, 2],
	[3, 4, 5],
	[6, 7, 8],
	[0, 3, 6],
	[1, 4, 7],
	[2, 5, 8],
	[0, 4, 8],
	[2, 4, 6]
]

var board: Array = []
var over := false
var last_message := ""
var last_player_move := ""
var last_computer_move := ""
var player_wins := 0
var computer_wins := 0
var draws := 0

func new_game() -> void:
	board = ["", "", "", "", "", "", "", "", ""]
	over = false
	last_player_move = ""
	last_computer_move = ""
	last_message = "Your move. Coach tip: take center, create forks, and block immediate wins."

func play_player_move(index: int) -> void:
	if over or board[index] != "":
		return
	board[index] = "X"
	last_player_move = square_name(index)
	if _finish_if_needed():
		return
	var ai_move := best_ai_move()
	if ai_move >= 0:
		board[ai_move] = "O"
		last_computer_move = square_name(ai_move)
	_finish_if_needed()

func winner() -> String:
	for line in WIN_LINES:
		var a: int = line[0]
		var b: int = line[1]
		var c: int = line[2]
		if board[a] != "" and board[a] == board[b] and board[b] == board[c]:
			return board[a]
	return ""

func best_ai_move() -> int:
	return _best_move_for("O", "X")

func _best_move_for(mark: String, opponent: String) -> int:
	for candidate_mark in [mark, opponent]:
		for i in range(9):
			if board[i] == "":
				board[i] = candidate_mark
				var found_winner := winner()
				board[i] = ""
				if found_winner == candidate_mark:
					return i
	var fork := _fork_move(mark)
	if fork >= 0:
		return fork
	var block_fork := _fork_move(opponent)
	if block_fork >= 0:
		return block_fork
	for i in [4, 0, 2, 6, 8, 1, 3, 5, 7]:
		if board[i] == "":
			return i
	return -1

func _finish_if_needed() -> bool:
	var found_winner := winner()
	if found_winner != "":
		over = true
		if found_winner == "X":
			player_wins += 1
			last_message = "You won."
		else:
			computer_wins += 1
			last_message = "Computer won. Review: watch for forks and forced blocks."
		return true
	if not board.has(""):
		over = true
		draws += 1
		last_message = "Draw. With perfect play, tic-tac-toe is a draw."
		return true
	last_message = "Your move. Coach tip: take center, create forks, and block immediate wins."
	return false

func reset_score() -> void:
	player_wins = 0
	computer_wins = 0
	draws = 0

func score_text() -> String:
	return "Score - You: %d  Computer: %d  Draws: %d" % [player_wins, computer_wins, draws]

func suggested_player_move() -> int:
	if over:
		return -1
	return _best_move_for("X", "O")

func guidance_text() -> String:
	if over:
		return StrategyText.advice(
			"Start a new game.",
			"With perfect play tic-tac-toe is a draw, so review whether a fork or forced block appeared.",
			"Try a different opening square next game."
		)
	var move := suggested_player_move()
	if move < 0:
		return StrategyText.advice("No legal moves remain.")
	var reason := suggested_move_reason(move)
	return StrategyText.advice(
		"Play %s." % square_name(move),
		reason,
		"Priority order: win, block, create/block forks, center, corners, then sides.",
		"After moving, count how many winning threats each player has."
	)

func suggested_move_reason(move: int) -> String:
	if _move_wins(move, "X"):
		return "This wins immediately."
	if _move_wins(move, "O"):
		return "This blocks the computer's immediate win."
	board[move] = "X"
	var player_threats := _winning_threat_count("X")
	board[move] = ""
	if player_threats >= 2:
		return "This creates a fork with multiple immediate threats."
	board[move] = "O"
	var opponent_threats := _winning_threat_count("O")
	board[move] = ""
	if opponent_threats >= 2:
		return "This blocks the computer's fork square."
	if move == 4:
		return "The center touches four winning lines and is the strongest neutral square."
	if move in [0, 2, 6, 8]:
		return "A corner supports diagonal forks and is stronger than an edge."
	return "A side is the fallback after urgent wins, blocks, forks, center, and corners."

func _move_wins(index: int, mark: String) -> bool:
	if board[index] != "":
		return false
	board[index] = mark
	var found_winner := winner()
	board[index] = ""
	return found_winner == mark

func _fork_move(mark: String) -> int:
	for i in range(9):
		if board[i] != "":
			continue
		board[i] = mark
		var threat_count := _winning_threat_count(mark)
		board[i] = ""
		if threat_count >= 2:
			return i
	return -1

func _winning_threat_count(mark: String) -> int:
	var count := 0
	for line in WIN_LINES:
		var marks := 0
		var blanks := 0
		for index in line:
			if board[index] == mark:
				marks += 1
			elif board[index] == "":
				blanks += 1
		if marks == 2 and blanks == 1:
			count += 1
	return count

func move_text() -> String:
	var player_text := "none" if last_player_move == "" else last_player_move
	var computer_text := "none" if last_computer_move == "" else last_computer_move
	return "Last moves - You: %s  Computer: %s" % [player_text, computer_text]

func square_name(index: int) -> String:
	var row := int(index / 3) + 1
	var col := index % 3 + 1
	return "row %d, column %d" % [row, col]
