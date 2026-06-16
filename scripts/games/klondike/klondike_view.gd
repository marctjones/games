class_name KlondikeView
extends VBoxContainer

const KlondikeModel := preload("res://scripts/games/klondike/klondike_model.gd")
const CardTools := preload("res://scripts/core/card_tools.gd")
const UiFactory := preload("res://scripts/ui/ui_factory.gd")

var status_label: Label
var score_label: Label
var rules_label: Label
var model: KlondikeModel
var facts_label: Label
var stock_waste_box: HBoxContainer
var foundation_box: HBoxContainer
var tableau_box: HBoxContainer

func setup(p_status_label: Label, p_score_label: Label = null, p_rules_label: Label = null) -> void:
	status_label = p_status_label
	score_label = p_score_label
	rules_label = p_rules_label
	model = KlondikeModel.new()
	model.new_game()
	if rules_label != null:
		rules_label.text = "Klondike Solitaire builds four foundations from ace to king by suit. Tableau cards build downward in alternating colors; only kings may move into empty tableau columns. This trainer allows stock draws, waste moves, tableau moves, and foundation moves."
	status_label.text = UiFactory.coach_message(model.last_message, model.hint_text())
	var section := UiFactory.make_section()
	add_child(section)
	facts_label = UiFactory.make_fact_label()
	section.add_child(facts_label)
	var top_row := HBoxContainer.new()
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_theme_constant_override("separation", 18)
	section.add_child(top_row)
	stock_waste_box = HBoxContainer.new()
	stock_waste_box.alignment = BoxContainer.ALIGNMENT_CENTER
	stock_waste_box.add_theme_constant_override("separation", 8)
	top_row.add_child(_wrap_labeled("Stock / waste", stock_waste_box, Color("#fffdf7")))
	foundation_box = HBoxContainer.new()
	foundation_box.alignment = BoxContainer.ALIGNMENT_CENTER
	foundation_box.add_theme_constant_override("separation", 8)
	top_row.add_child(_wrap_labeled("Foundations", foundation_box, Color("#f4f7f8")))
	tableau_box = HBoxContainer.new()
	tableau_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tableau_box.add_theme_constant_override("separation", 8)
	section.add_child(_wrap_labeled("Tableau", tableau_box, Color("#fffaf0")))
	var controls := UiFactory.make_button_row()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_child(UiFactory.make_secondary_button("New Game", _restart))
	section.add_child(controls)
	_update()

func _restart() -> void:
	model.new_game()
	status_label.text = UiFactory.coach_message(model.last_message, model.hint_text())
	_update()

func refresh_layout() -> void:
	_update()

func _draw_stock() -> void:
	model.draw_stock()
	status_label.text = UiFactory.coach_message(model.last_message, model.hint_text())
	_update()

func _select_waste() -> void:
	model.select_waste()
	status_label.text = UiFactory.coach_message(model.last_message, model.hint_text())
	_update()

func _select_tableau(col: int, index: int) -> void:
	if model.selected.is_empty():
		model.select_tableau(col, index)
	else:
		model.move_selected_to_tableau(col)
	status_label.text = UiFactory.coach_message(model.last_message, model.hint_text())
	_update()

func _foundation_pressed(suit: String) -> void:
	if model.selected.is_empty():
		status_label.text = UiFactory.coach_message("Select a movable card first.", model.hint_text())
	else:
		model.move_selected_to_foundation(suit)
		status_label.text = UiFactory.coach_message(model.last_message, model.hint_text())
	_update()

func _empty_tableau_pressed(col: int) -> void:
	if model.selected.is_empty():
		status_label.text = UiFactory.coach_message("Select a king or king-led sequence to move into an empty column.", model.hint_text())
	else:
		model.move_selected_to_tableau(col)
		status_label.text = UiFactory.coach_message(model.last_message, model.hint_text())
	_update()

func _update() -> void:
	_clear_children(stock_waste_box)
	_clear_children(foundation_box)
	_clear_children(tableau_box)
	facts_label.text = "Valid players: 1 | Solitaire trainer\n%s" % model.table_text()
	if score_label != null:
		score_label.text = "%s\nSelected: %s" % [model.score_text(), _selected_text()]
	_build_stock_waste()
	_build_foundations()
	_build_tableau()

func _build_stock_waste() -> void:
	var stock_button := Button.new()
	stock_button.text = "Recycle" if model.stock.is_empty() else ""
	stock_button.custom_minimum_size = UiFactory.small_card_control_size()
	stock_button.icon = UiFactory.make_card_back_texture()
	stock_button.expand_icon = true
	stock_button.add_theme_constant_override("icon_max_width", UiFactory.small_card_icon_width())
	stock_button.add_theme_stylebox_override("normal", UiFactory.panel_style(Color("#40515e"), 7, Color("#26343f"), 1))
	stock_button.add_theme_stylebox_override("hover", UiFactory.panel_style(Color("#4f6575"), 7, Color("#26343f"), 1))
	stock_button.pressed.connect(_draw_stock)
	stock_waste_box.add_child(stock_button)
	if model.waste.is_empty():
		stock_waste_box.add_child(UiFactory.make_small_card_display("Waste", false, true))
	else:
		var selected: bool = str(model.selected.get("kind", "")) == "waste"
		var button := UiFactory.make_small_card_button(model.waste[-1], _select_waste, selected)
		button.tooltip_text = "Select waste card."
		stock_waste_box.add_child(button)

func _build_foundations() -> void:
	for suit in CardTools.SUITS:
		var pile: Array = model.foundations[suit]
		var button := Button.new()
		button.custom_minimum_size = UiFactory.small_card_control_size()
		button.text = suit if pile.is_empty() else ""
		button.add_theme_font_size_override("font_size", 18)
		button.add_theme_color_override("font_color", Color("#17212b"))
		button.add_theme_color_override("font_hover_color", Color("#17212b"))
		button.add_theme_color_override("font_pressed_color", Color("#17212b"))
		button.add_theme_color_override("font_disabled_color", Color("#40515e"))
		if not pile.is_empty():
			button.icon = UiFactory.make_card_texture(pile[-1])
			button.expand_icon = true
			button.add_theme_constant_override("icon_max_width", UiFactory.small_card_icon_width())
		button.add_theme_stylebox_override("normal", UiFactory.panel_style(Color("#f4f7f8"), 7, Color("#c8bfae"), 1))
		button.add_theme_stylebox_override("hover", UiFactory.panel_style(Color("#fff5d8"), 7, Color("#a9935d"), 1))
		button.pressed.connect(_foundation_pressed.bind(suit))
		foundation_box.add_child(button)

func _build_tableau() -> void:
	for col in range(7):
		var panel := UiFactory.make_panel()
		panel.custom_minimum_size = Vector2(UiFactory.small_card_control_size().x + 26, 0)
		panel.add_theme_stylebox_override("panel", UiFactory.panel_style(Color("#f7f4ee"), 7, Color("#c8bfae"), 1))
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 3)
		panel.add_child(column)
		var label := Label.new()
		label.text = "%d" % (col + 1)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color("#40515e"))
		column.add_child(label)
		if model.tableau[col].is_empty():
			var empty := UiFactory.make_secondary_button("Empty", _empty_tableau_pressed.bind(col))
			empty.custom_minimum_size = UiFactory.small_card_control_size()
			column.add_child(empty)
		else:
			for i in range(model.tableau[col].size()):
				var card: Dictionary = model.tableau[col][i]
				if bool(card.get("face_up", false)):
					var selected := _is_selected_tableau(col, i)
					var button := UiFactory.make_small_card_button(card, _select_tableau.bind(col, i), selected)
					if selected:
						button.tooltip_text = "Selected sequence starts here."
					column.add_child(button)
				else:
					column.add_child(UiFactory.make_small_card_display("Hidden", false, true))
		tableau_box.add_child(panel)

func _selected_text() -> String:
	var cards := model.selected_cards()
	if cards.is_empty():
		return "none"
	return CardTools.cards_text(cards)

func _is_selected_tableau(col: int, index: int) -> bool:
	return model.selected.get("kind", "") == "tableau" and int(model.selected.get("col", -1)) == col and int(model.selected.get("index", -1)) == index

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

func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.queue_free()
