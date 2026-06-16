class_name TicTacToeView
extends VBoxContainer

const TicTacToeModel := preload("res://scripts/games/tic_tac_toe/tic_tac_toe_model.gd")
const UiFactory := preload("res://scripts/ui/ui_factory.gd")

var status_label: Label
var score_label: Label
var rules_label: Label
var model: TicTacToeModel
var buttons: Array = []
var facts_label: Label
var grid: GridContainer

func setup(p_status_label: Label, p_score_label: Label = null, p_rules_label: Label = null) -> void:
	status_label = p_status_label
	score_label = p_score_label
	rules_label = p_rules_label
	if rules_label != null:
		rules_label.text = "Place Xs to make three in a row before the computer makes three Os. Strategy: center first, corners next, block immediate threats, and create forks where you threaten two winning lines at once."
	model = TicTacToeModel.new()
	model.new_game()
	buttons = []
	var section := UiFactory.make_section()
	add_child(section)
	facts_label = UiFactory.make_fact_label()
	section.add_child(facts_label)
	grid = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	section.add_child(grid)
	for i in range(9):
		var button := UiFactory.make_ttt_cell(_player_move.bind(i))
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

func _player_move(index: int) -> void:
	model.play_player_move(index)
	_update()

func _update() -> void:
	var cell_size := UiFactory.ttt_cell_size()
	grid.custom_minimum_size = Vector2(cell_size * 3 + 8, cell_size * 3 + 8)
	facts_label.text = "Valid players: 2 | Computer opponents: 1 | %s | %s" % [model.score_text(), model.move_text()]
	if score_label != null:
		score_label.text = "%s\n%s" % [model.score_text(), model.move_text()]
	var suggested := model.suggested_player_move()
	for i in range(9):
		buttons[i].text = model.board[i]
		buttons[i].custom_minimum_size = Vector2(cell_size, cell_size)
		UiFactory.style_ttt_cell(buttons[i])
		buttons[i].disabled = model.over or model.board[i] != ""
		if i == suggested and model.board[i] == "":
			UiFactory.style_suggested_card_button(buttons[i])
			buttons[i].tooltip_text = "Coach suggestion: %s" % model.square_name(i)
		else:
			buttons[i].tooltip_text = ""
	status_label.text = UiFactory.coach_message(model.last_message, model.guidance_text())
