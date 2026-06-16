class_name CheckersView
extends VBoxContainer

const CheckersModel := preload("res://scripts/games/checkers/checkers_model.gd")
const UiFactory := preload("res://scripts/ui/ui_factory.gd")

var status_label: Label
var score_label: Label
var rules_label: Label
var model: CheckersModel
var buttons: Array = []
var facts_label: Label
var grid: GridContainer

func setup(p_status_label: Label, p_score_label: Label = null, p_rules_label: Label = null) -> void:
	status_label = p_status_label
	score_label = p_score_label
	rules_label = p_rules_label
	status_label.text = "You are red. Move diagonally upward. The computer is black."
	if rules_label != null:
		rules_label.text = "Move red pieces diagonally toward the computer side. Captures are forced when available. A piece that reaches the far row becomes a king and can move both directions. Strategy: trade pieces when ahead, keep your back row intact early, and look for double-jump threats."
	model = CheckersModel.new()
	model.new_game()
	buttons = []
	var section := UiFactory.make_section()
	add_child(section)
	facts_label = UiFactory.make_fact_label()
	section.add_child(facts_label)
	grid = GridContainer.new()
	grid.columns = 8
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 0)
	grid.add_theme_constant_override("v_separation", 0)
	section.add_child(grid)
	for y in range(8):
		for x in range(8):
			var button := UiFactory.make_checkers_cell(_square_pressed.bind(x, y))
			buttons.append(button)
			grid.add_child(button)
	var row := UiFactory.make_button_row()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(UiFactory.make_secondary_button("New Game", _restart))
	section.add_child(row)
	_update()

func _restart() -> void:
	model.new_game()
	_update()

func refresh_layout() -> void:
	_update()

func _square_pressed(x: int, y: int) -> void:
	var should_ai_move := model.press_square(Vector2i(x, y))
	_update()
	if should_ai_move and not model.over:
		await get_tree().create_timer(0.35).timeout
		model.ai_move()
		_update()

func _update() -> void:
	var cell_size := UiFactory.checkers_cell_size()
	grid.custom_minimum_size = Vector2(cell_size * 8, cell_size * 8)
	facts_label.text = "Valid players: 2 | Computer opponents: 1 | %s | %s" % [model.score_text(), model.move_summary_text()]
	if score_label != null:
		score_label.text = "%s\n%s\nTurn: %s" % [
			model.score_text(),
			model.move_summary_text(),
			"You" if model.turn == "r" else "Computer"
		]
	var suggested := model.best_move_for("r") if not model.over and model.turn == "r" else {}
	for y in range(8):
		for x in range(8):
			var button: Button = buttons[y * 8 + x]
			button.custom_minimum_size = Vector2(cell_size, cell_size)
			var piece: String = model.board[y][x]
			button.text = model.piece_text(piece)
			var dark := (x + y) % 2 == 1
			var selected := model.selected == Vector2i(x, y)
			UiFactory.style_checkers_cell(button, dark, selected, _is_legal_target(Vector2i(x, y)), piece)
			if suggested.has("from") and (suggested["from"] == Vector2i(x, y) or suggested["to"] == Vector2i(x, y)):
				button.tooltip_text = "Coach suggestion: %s" % model.move_text(suggested)
			else:
				button.tooltip_text = ""
	status_label.text = UiFactory.coach_message(model.last_message, model.guidance_text())

func _is_legal_target(pos: Vector2i) -> bool:
	if model.selected.x < 0:
		return false
	for move in model.legal_moves("r"):
		if move["from"] == model.selected and move["to"] == pos:
			return true
	return false
