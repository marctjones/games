class_name TexasHoldemView
extends VBoxContainer

const TexasHoldemModel := preload("res://scripts/games/texas_holdem/texas_holdem_model.gd")
const CardTools := preload("res://scripts/core/card_tools.gd")
const PokerEvaluator := preload("res://scripts/games/poker/poker_evaluator.gd")
const UiFactory := preload("res://scripts/ui/ui_factory.gd")

var status_label: Label
var score_label: Label
var rules_label: Label
var model: TexasHoldemModel
var facts_label: Label
var result_label: Label
var board_box: HBoxContainer
var player_box: HBoxContainer
var opponent_box: HFlowContainer
var opponent_option: OptionButton
var reveal_option: OptionButton
var check_button: Button
var fold_button: Button
var reveal_target := -1

func setup(p_status_label: Label, p_score_label: Label = null, p_rules_label: Label = null) -> void:
	status_label = p_status_label
	score_label = p_score_label
	rules_label = p_rules_label
	model = TexasHoldemModel.new()
	model.new_hand()
	if rules_label != null:
		rules_label.text = "Texas Hold'em gives each player two private hole cards plus five shared community cards. This trainer uses a simplified cash-game flow: blinds/check-call advance the board, fold exits the hand, and showdown awards the pot by best five-card poker hand."
	status_label.text = UiFactory.coach_message(model.last_message, model.guidance_text())
	var section := UiFactory.make_section()
	add_child(section)
	var setup_row := UiFactory.make_button_row()
	setup_row.alignment = BoxContainer.ALIGNMENT_CENTER
	section.add_child(setup_row)
	var opponent_label := Label.new()
	opponent_label.text = "Computer opponents"
	opponent_label.add_theme_color_override("font_color", Color("#25313a"))
	setup_row.add_child(opponent_label)
	opponent_option = OptionButton.new()
	for i in range(1, 6):
		opponent_option.add_item(str(i), i)
	opponent_option.selected = model.opponent_count - 1
	opponent_option.item_selected.connect(_opponent_count_selected)
	setup_row.add_child(opponent_option)
	reveal_option = OptionButton.new()
	reveal_option.item_selected.connect(_reveal_option_selected)
	setup_row.add_child(reveal_option)
	_populate_reveal_options()
	facts_label = UiFactory.make_fact_label()
	section.add_child(facts_label)
	result_label = UiFactory.make_info_label()
	section.add_child(result_label)
	board_box = HBoxContainer.new()
	board_box.alignment = BoxContainer.ALIGNMENT_CENTER
	board_box.add_theme_constant_override("separation", UiFactory.hand_card_gap())
	section.add_child(_wrap_labeled("Community board", board_box, Color("#f4f7f8")))
	opponent_box = HFlowContainer.new()
	opponent_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opponent_box.add_theme_constant_override("h_separation", 10)
	opponent_box.add_theme_constant_override("v_separation", 10)
	section.add_child(_wrap_labeled("Computer seats", opponent_box, Color("#f7f4ee")))
	player_box = HBoxContainer.new()
	player_box.alignment = BoxContainer.ALIGNMENT_CENTER
	player_box.add_theme_constant_override("separation", UiFactory.hand_card_gap())
	section.add_child(_wrap_labeled("Your hole cards", player_box, Color("#fffaf0")))
	var controls := UiFactory.make_button_row()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	section.add_child(controls)
	check_button = UiFactory.make_action_button("Check / Call $10", _check_call)
	fold_button = UiFactory.make_secondary_button("Fold", _fold)
	controls.add_child(check_button)
	controls.add_child(fold_button)
	controls.add_child(UiFactory.make_secondary_button("New Hand", _restart))
	_update()

func _restart() -> void:
	model.new_hand()
	status_label.text = UiFactory.coach_message(model.last_message, model.guidance_text())
	_update()

func refresh_layout() -> void:
	_update()

func _opponent_count_selected(index: int) -> void:
	model.set_opponent_count(index + 1)
	reveal_target = -1
	_populate_reveal_options()
	status_label.text = "Table size changed. Bankrolls reset for the new table."
	_update()

func _reveal_option_selected(index: int) -> void:
	reveal_target = reveal_option.get_item_id(index)
	_update()

func _populate_reveal_options() -> void:
	reveal_option.clear()
	reveal_option.add_item("Hide opponent hands", -1)
	for i in range(model.opponent_count):
		reveal_option.add_item("Reveal computer %d" % (i + 1), i)
	reveal_option.add_item("Reveal all", -2)
	for i in range(reveal_option.item_count):
		if reveal_option.get_item_id(i) == reveal_target:
			reveal_option.select(i)
			return
	reveal_option.select(0)

func _check_call() -> void:
	var message := model.check_call()
	status_label.text = UiFactory.coach_message(message, model.guidance_text())
	_update()

func _fold() -> void:
	var message := model.fold()
	status_label.text = UiFactory.coach_message(message, model.guidance_text())
	_update()

func _update() -> void:
	_clear_children(board_box)
	_clear_children(player_box)
	_clear_children(opponent_box)
	facts_label.text = "Valid players: 2-6 | Computer opponents: %d\n%s" % [model.opponent_count, model.table_text()]
	if score_label != null:
		var eval_name := "waiting for 5 cards"
		if model.community.size() >= 3:
			eval_name = str(model.player_evaluation()["name"])
		score_label.text = "%s\nStage: %s\nYour current hand: %s" % [model.score_text(), model.stage.capitalize(), eval_name]
	result_label.text = model.result_text if model.done else "Board: %s\nPot: $%d\nCoach: %s" % [CardTools.cards_text(model.community), model.pot, model.guidance_text()]
	_build_board()
	_build_opponents()
	for card in model.player:
		player_box.add_child(UiFactory.make_card_display("", CardTools.is_red_suit(card.suit), false, card))
	check_button.disabled = model.done
	fold_button.disabled = model.done

func _build_board() -> void:
	for card in model.community:
		board_box.add_child(UiFactory.make_card_display("", CardTools.is_red_suit(card.suit), false, card))
	for i in range(5 - model.community.size()):
		var placeholder := UiFactory.make_card_display("Empty", false, false)
		placeholder.modulate = Color(1, 1, 1, 0.72)
		board_box.add_child(placeholder)

func _build_opponents() -> void:
	for i in range(model.bots.size()):
		var panel := UiFactory.make_panel()
		panel.custom_minimum_size = Vector2(UiFactory.small_card_control_size().x * 2 + 70, UiFactory.small_card_control_size().y + 70)
		panel.add_theme_stylebox_override("panel", UiFactory.panel_style(Color("#f4f7f8"), 7, Color("#c8bfae"), 1))
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		panel.add_child(box)
		var label := Label.new()
		label.text = "Computer %d - $%d" % [i + 1, model.computer_bankrolls[i]]
		if model.folded_bots[i]:
			label.text += " folded"
		elif _show_opponent(i) and model.community.size() >= 3:
			label.text += " - %s" % model.bot_evaluation(i)["name"]
		elif not _show_opponent(i):
			label.text += " hidden"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color("#17212b"))
		box.add_child(label)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 6)
		box.add_child(row)
		for card in model.bots[i]:
			if _show_opponent(i):
				row.add_child(UiFactory.make_small_card_display("", CardTools.is_red_suit(card.suit), false, card))
			else:
				row.add_child(UiFactory.make_small_card_display("Hidden", false, true))
		opponent_box.add_child(panel)

func _show_opponent(index: int) -> bool:
	return model.done or reveal_target == -2 or reveal_target == index

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
