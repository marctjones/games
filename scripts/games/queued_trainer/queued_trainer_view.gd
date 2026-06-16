class_name QueuedTrainerView
extends VBoxContainer

const QueuedTrainerModel := preload("res://scripts/games/queued_trainer/queued_trainer_model.gd")
const CardTools := preload("res://scripts/core/card_tools.gd")
const UiFactory := preload("res://scripts/ui/ui_factory.gd")

var game_id := ""
var status_label: Label
var score_label: Label
var rules_label: Label
var model: QueuedTrainerModel
var facts_label: Label
var table_label: Label
var grid: GridContainer
var hand_box: HFlowContainer
var action_button: Button

func _init(p_game_id: String = "chess") -> void:
	game_id = p_game_id

func setup(p_status_label: Label, p_score_label: Label = null, p_rules_label: Label = null) -> void:
	status_label = p_status_label
	score_label = p_score_label
	rules_label = p_rules_label
	model = QueuedTrainerModel.new(game_id)
	model.new_game()
	if rules_label != null:
		rules_label.text = model.rules_summary
	var section := UiFactory.make_section()
	add_child(section)
	facts_label = UiFactory.make_fact_label()
	section.add_child(facts_label)
	table_label = UiFactory.make_info_label()
	section.add_child(table_label)
	if model.kind == "card":
		_build_card_surface(section)
	else:
		_build_board_surface(section)
	var row := UiFactory.make_button_row()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_button = UiFactory.make_action_button("Trainer Action", _trainer_action)
	row.add_child(action_button)
	row.add_child(UiFactory.make_secondary_button("New Game", _restart))
	section.add_child(row)
	_update()

func _build_card_surface(parent: VBoxContainer) -> void:
	hand_box = HFlowContainer.new()
	hand_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_box.add_theme_constant_override("h_separation", UiFactory.hand_card_gap())
	hand_box.add_theme_constant_override("v_separation", UiFactory.hand_card_gap())
	parent.add_child(_wrap_labeled("Your hand", hand_box, Color("#fffaf0")))

func _build_board_surface(parent: VBoxContainer) -> void:
	grid = GridContainer.new()
	grid.columns = model.board_size
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 1)
	grid.add_theme_constant_override("v_separation", 1)
	parent.add_child(grid)
	for y in range(model.board_size):
		for x in range(model.board_size):
			var button := Button.new()
			button.pressed.connect(_cell_pressed.bind(x, y))
			grid.add_child(button)

func _restart() -> void:
	model.new_game()
	_update()

func refresh_layout() -> void:
	_update()

func _trainer_action() -> void:
	model.take_action()
	_update()

func _cell_pressed(x: int, y: int) -> void:
	model.press_cell(Vector2i(x, y))
	_update()

func _card_pressed(card: Dictionary) -> void:
	var message := model.play_card(card)
	if message != "":
		status_label.text = message
		return
	_update()

func _update() -> void:
	facts_label.text = "Trainer module | %s" % model.score_text()
	table_label.text = model.table_text()
	status_label.text = UiFactory.coach_message(model.last_message, model.guidance_text())
	if score_label != null:
		score_label.text = "%s\nMode: %s" % [model.score_text(), model.title]
	if model.kind == "card":
		_update_card_view()
	else:
		_update_board_view()
	action_button.visible = model.game_id in ["ludo_pachisi", "backgammon"]
	action_button.disabled = model.over

func _update_card_view() -> void:
	for child in hand_box.get_children():
		child.queue_free()
	var legal := model.legal_cards()
	var suggestion: Dictionary = legal[0] if not legal.is_empty() else {}
	for card in model.player_cards:
		var button := UiFactory.make_fit_card_button(card, _card_pressed.bind(card), false, 12)
		button.disabled = model.over or not legal.has(card)
		if suggestion.size() > 0 and card == suggestion:
			UiFactory.style_suggested_card_button(button)
			button.tooltip_text = "Coach suggestion: legal low card."
		hand_box.add_child(button)

func _update_board_view() -> void:
	var cell_size := _board_cell_size()
	grid.custom_minimum_size = Vector2(cell_size * model.board_size, cell_size * model.board_size)
	var suggested := model.best_player_move()
	for y in range(model.board_size):
		for x in range(model.board_size):
			var pos := Vector2i(x, y)
			var button: Button = grid.get_child(y * model.board_size + x)
			button.custom_minimum_size = Vector2(cell_size, cell_size)
			button.text = model.cell_text(pos)
			_style_board_cell(button, pos, suggested)

func _board_cell_size() -> int:
	var available: float = max(300.0, UiFactory.play_area_width - 96.0)
	var available_height: float = max(320.0, get_viewport_rect().size.y - 300.0)
	var raw: int = int(floor(min(available, available_height) / float(model.board_size)))
	return clamp(raw, 24, UiFactory.checkers_cell_size())

func _style_board_cell(button: Button, pos: Vector2i, suggested: Dictionary) -> void:
	var dark := (pos.x + pos.y) % 2 == 1
	var bg := Color("#b78352") if dark else Color("#efd8b5")
	if model.game_id in ["go_9x9", "go_19x19"]:
		bg = Color("#d6a95f")
	elif model.game_id == "reversi":
		bg = Color("#49785a")
	if model.selected == pos:
		bg = Color("#e5bf48")
	if not suggested.is_empty() and (suggested.get("from", Vector2i(-1, -1)) == pos or suggested.get("to", Vector2i(-1, -1)) == pos):
		bg = Color("#d6c473")
	var style := UiFactory.panel_style(bg, 2, Color("#5c4531"), 1)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", UiFactory.panel_style(Color("#fff2cf"), 2, Color("#8b7337"), 1))
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_font_size_override("font_size", int(round(_board_cell_size() * 0.42)))
	button.add_theme_color_override("font_color", Color("#17212b"))
	button.tooltip_text = model.square_name(pos)

func _wrap_labeled(title: String, content: Control, color: Color) -> PanelContainer:
	var panel := UiFactory.make_panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", UiFactory.panel_style(color, 7, Color("#c8bfae"), 1))
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("#17212b"))
	box.add_child(label)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(content)
	return panel
