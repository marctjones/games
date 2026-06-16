extends SceneTree

const CheckersModel := preload("res://scripts/games/checkers/checkers_model.gd")
const GinRummyModel := preload("res://scripts/games/gin_rummy/gin_rummy_model.gd")
const OpponentPolicy := preload("res://scripts/core/opponent_policy.gd")
const Rummy500Model := preload("res://scripts/games/rummy_500/rummy_500_model.gd")
const TicTacToeModel := preload("res://scripts/games/tic_tac_toe/tic_tac_toe_model.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_verify_policy_metadata()
	_verify_tic_tac_toe_difficulty()
	_verify_checkers_difficulty()
	_verify_gin_uses_visible_discard_without_stock_peek()
	_verify_rummy_500_uses_visible_discard_without_stock_peek()
	print("Opponent policy verification passed.")
	quit()

func _verify_policy_metadata() -> void:
	_assert(OpponentPolicy.option_ids().size() == 5, "Expected five difficulty levels")
	_assert(OpponentPolicy.fairness_note().contains("unknown deck"), "Fairness note must mention unknown deck cards")

func _verify_tic_tac_toe_difficulty() -> void:
	var model := TicTacToeModel.new()
	model.board = ["X", "X", "", "", "O", "", "", "", ""]
	model.set_difficulty(OpponentPolicy.EXPERT)
	_assert(model.best_ai_move() == 2, "Expert tic-tac-toe should block the immediate win")
	model.set_difficulty(OpponentPolicy.BEGINNER)
	var beginner_move := model.best_ai_move()
	_assert(beginner_move >= 0 and model.board[beginner_move] == "", "Beginner tic-tac-toe must still choose a legal move")

func _verify_checkers_difficulty() -> void:
	var model := CheckersModel.new()
	model.new_game()
	model.set_difficulty(OpponentPolicy.BEGINNER)
	var moves := model.legal_moves("b")
	var chosen := model._choose_ai_move(moves)
	_assert(not chosen.is_empty(), "Checkers difficulty chooser should return a legal move")
	_assert(model.is_legal_move(chosen, "b"), "Checkers difficulty chooser must not invent moves")

func _verify_gin_uses_visible_discard_without_stock_peek() -> void:
	var model := GinRummyModel.new()
	model.set_difficulty(OpponentPolicy.STANDARD)
	model.bot = [_card("5", "H"), _card("6", "H"), _card("8", "H"), _card("K", "S")]
	model.player = [_card("2", "C")]
	model.discard = [_card("7", "H")]
	model.deck = [_card("3", "C"), _card("9", "H")]
	model.phase = "bot"
	model.bot_turn()
	_assert(model.last_bot_action.contains("discard pile"), "Gin bot should take a visible meld-improving discard instead of peeking at stock")

func _verify_rummy_500_uses_visible_discard_without_stock_peek() -> void:
	var model := Rummy500Model.new()
	model.set_difficulty(OpponentPolicy.STANDARD)
	model.bot = [_card("5", "H"), _card("6", "H"), _card("8", "H"), _card("K", "S")]
	model.player = [_card("2", "C")]
	model.discard = [_card("7", "H")]
	model.deck = [_card("3", "C"), _card("9", "H")]
	model.phase = "bot"
	model.bot_turn()
	_assert(model.last_bot_action.contains("discard pile"), "Rummy 500 bot should take a visible meld-improving discard instead of peeking at stock")

func _card(rank: String, suit: String) -> Dictionary:
	return {"rank": rank, "suit": suit}

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
