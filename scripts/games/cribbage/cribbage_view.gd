class_name CribbageView
extends VBoxContainer

const CribbageModel := preload("res://scripts/games/cribbage/cribbage_model.gd")
const CardTools := preload("res://scripts/core/card_tools.gd")
const UiFactory := preload("res://scripts/ui/ui_factory.gd")

var status_label: Label
var score_label: Label
var rules_label: Label
var model: CribbageModel
var hand_scroll: ScrollContainer
var hand_box: Container
var facts_label: Label
var result_label: Label
var table_box: HBoxContainer
var opponent_scroll: ScrollContainer
var opponent_box: HBoxContainer
var player_count_option: OptionButton
var reveal_target := -1
var reveal_option: OptionButton
var score_button: Button

func setup(p_status_label: Label, p_score_label: Label = null, p_rules_label: Label = null) -> void:
	status_label = p_status_label
	score_label = p_score_label
	rules_label = p_rules_label
	model = CribbageModel.new()
	model.new_hand()
	status_label.text = UiFactory.coach_message("Choose the required crib discard%s." % ["" if model.discard_goal() == 1 else "s"], model.guidance_text())
	if rules_label != null:
		rules_label.text = "This module focuses on cribbage discard selection, hand scoring, and a simple pegging drill after the cut. Keep cards that make fifteens, pairs, and runs. Be cautious about discarding 5s or connected cards into an opponent crib. Pegging points here cover fifteens, thirty-ones, pairs, and short runs."
	var section := UiFactory.make_section()
	add_child(section)
	var setup_row := UiFactory.make_button_row()
	setup_row.alignment = BoxContainer.ALIGNMENT_CENTER
	section.add_child(setup_row)
	var player_count_label := Label.new()
	player_count_label.text = "Players"
	player_count_label.add_theme_color_override("font_color", Color("#25313a"))
	setup_row.add_child(player_count_label)
	player_count_option = OptionButton.new()
	for i in range(2, 5):
		player_count_option.add_item(str(i), i)
	player_count_option.selected = model.player_count - 2
	player_count_option.item_selected.connect(_player_count_selected)
	setup_row.add_child(player_count_option)
	reveal_option = OptionButton.new()
	reveal_option.item_selected.connect(_reveal_option_selected)
	setup_row.add_child(reveal_option)
	_populate_reveal_options()
	facts_label = UiFactory.make_fact_label()
	section.add_child(facts_label)
	result_label = UiFactory.make_info_label()
	section.add_child(result_label)
	table_box = HBoxContainer.new()
	table_box.alignment = BoxContainer.ALIGNMENT_CENTER
	table_box.add_theme_constant_override("separation", 14)
	section.add_child(table_box)
	opponent_scroll = ScrollContainer.new()
	opponent_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	opponent_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	section.add_child(opponent_scroll)
	opponent_box = HBoxContainer.new()
	opponent_box.add_theme_constant_override("separation", 12)
	opponent_scroll.add_child(opponent_box)
	var hand := UiFactory.make_hand_scroll()
	hand_scroll = hand["scroll"]
	hand_box = hand["row"]
	section.add_child(hand_scroll)
	var controls := UiFactory.make_button_row()
	section.add_child(controls)
	score_button = UiFactory.make_action_button("Score Discards", _score_discards)
	controls.add_child(score_button)
	controls.add_child(UiFactory.make_secondary_button("New Hand", _restart))
	_update()

func _restart() -> void:
	model.new_hand()
	status_label.text = UiFactory.coach_message(
		"Choose the required crib discard%s, then score the kept hand." % ["" if model.discard_goal() == 1 else "s"],
		model.guidance_text()
	)
	_update()

func refresh_layout() -> void:
	_update()

func _player_count_selected(index: int) -> void:
	model.reset_score()
	model.set_player_count(index + 2)
	reveal_target = -1
	_populate_reveal_options()
	status_label.text = "Player count changed. Score reset for the new cribbage table."
	_update()

func _reveal_option_selected(index: int) -> void:
	reveal_target = reveal_option.get_item_id(index)
	_update()

func _populate_reveal_options() -> void:
	reveal_option.clear()
	reveal_option.add_item("Hide opponent hands", -1)
	for i in range(model.bots.size()):
		reveal_option.add_item("Reveal computer %d" % (i + 1), i)
	reveal_option.add_item("Reveal all", -2)
	for i in range(reveal_option.item_count):
		if reveal_option.get_item_id(i) == reveal_target:
			reveal_option.select(i)
			return
	reveal_option.select(0)

func _toggle_discard(card: Dictionary) -> void:
	model.toggle_discard(card)
	status_label.text = UiFactory.coach_message(
		"Selected crib discard%s: %s" % ["" if model.selected_discards.size() == 1 else "s", CardTools.cards_text(model.selected_discards)],
		model.guidance_text()
	)
	_update()

func _score_discards() -> void:
	var result := model.score_discards()
	if result.begins_with("Choose exactly"):
		status_label.text = result
		return
	result_label.text = result
	status_label.text = UiFactory.coach_message(
		"Cribbage hand scored.",
		"Review whether the discard protected fifteens, pairs, and runs while limiting crib risk."
	)
	_update()

func _update() -> void:
	for child in hand_box.get_children():
		child.queue_free()
	for child in table_box.get_children():
		child.queue_free()
	for child in opponent_box.get_children():
		child.queue_free()
	facts_label.text = "Valid players: 2-4 | Computer opponents: %d | Discards needed: %d | %s" % [
		model.player_count - 1,
		model.discard_goal(),
		model.score_text()
	]
	if score_label != null:
		score_label.text = "%s\nPlayers: %d\nComputer opponents: %d\nDiscards needed: %d" % [
			model.score_text(),
			model.player_count,
			model.player_count - 1,
			model.discard_goal()
		]
	score_button.disabled = model.cut_card.size() > 0 or model.selected_discards.size() != model.discard_goal()
	hand_scroll.custom_minimum_size = Vector2(0, UiFactory.hand_scroll_height(6))
	opponent_scroll.custom_minimum_size = Vector2(0, UiFactory.small_hand_scroll_height() + 48)
	table_box.add_child(_make_crib_board())
	if model.cut_card.size() > 0:
		table_box.add_child(UiFactory.make_card_display("", false, false, model.cut_card))
	else:
		table_box.add_child(UiFactory.make_card_display("Cut", false, true))
	table_box.add_child(UiFactory.make_card_display("Crib", false, true))
	for i in range(model.bots.size()):
		opponent_box.add_child(_make_opponent_hand(i))
	for card in model.player:
		var button := UiFactory.make_card_button(card, _toggle_discard.bind(card), model.selected_discards.has(card))
		if not model.selected_discards.has(card) and model.suggested_discards().has(card):
			UiFactory.style_suggested_card_button(button)
			button.tooltip_text = "Coach suggestion: consider discarding this card."
		elif model.selected_discards.has(card):
			button.tooltip_text = "Selected for the crib."
		button.disabled = model.cut_card.size() > 0
		hand_box.add_child(button)
	if model.cut_card.is_empty():
		result_label.text = model.prompt_text()

func _make_opponent_hand(index: int) -> PanelContainer:
	var panel := UiFactory.make_panel()
	var card_size := UiFactory.small_card_control_size()
	var visible := _show_opponent_hand(index)
	panel.custom_minimum_size = Vector2(card_size.x * max(4, model.bots[index].size()) + 78, card_size.y + 58) if visible else Vector2(card_size.x * 2 + 120, 58)
	panel.add_theme_stylebox_override("panel", UiFactory.panel_style(Color("#f4f7f8"), 7, Color("#c8bfae"), 1))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var label := Label.new()
	var score_text := ""
	if model.cut_card.size() > 0:
		score_text = " = %d" % CribbageModel.score_hand(model.bots[index], model.cut_card)
	elif _show_opponent_hand(index):
		score_text = " - raw %d before cut" % CribbageModel.score_hand(model.bots[index], {})
	elif not _show_opponent_hand(index):
		score_text = " - hidden"
	label.text = "Computer %d hand%s" % [index + 1, score_text]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("#17212b"))
	box.add_child(label)
	if not visible:
		return panel
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	for card in model.bots[index]:
		if _show_opponent_hand(index):
			row.add_child(UiFactory.make_small_card_display("", CardTools.is_red_suit(card.suit), false, card))
		else:
			row.add_child(UiFactory.make_small_card_display("Hidden", false, true))
	return panel

func _show_opponent_hand(index: int) -> bool:
	return model.cut_card.size() > 0 or reveal_target == -2 or reveal_target == index

func _make_crib_board() -> PanelContainer:
	var panel := UiFactory.make_panel()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.custom_minimum_size = Vector2(240, 92)
	var grid := GridContainer.new()
	grid.columns = 12
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	panel.add_child(grid)
	for i in range(24):
		var peg := ColorRect.new()
		peg.custom_minimum_size = Vector2(10, 10)
		peg.color = Color("#7b5732") if i % 2 == 0 else Color("#c8bfae")
		grid.add_child(peg)
	return panel
