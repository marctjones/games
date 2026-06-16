class_name FiveCardDrawView
extends VBoxContainer

const FiveCardDrawModel := preload("res://scripts/games/five_card_draw/five_card_draw_model.gd")
const CardTools := preload("res://scripts/core/card_tools.gd")
const PokerEvaluator := preload("res://scripts/games/poker/poker_evaluator.gd")
const UiFactory := preload("res://scripts/ui/ui_factory.gd")

var status_label: Label
var score_label: Label
var rules_label: Label
var model: FiveCardDrawModel
var hand_scroll: ScrollContainer
var hand_box: Container
var facts_label: Label
var result_label: Label
var deck_row: HBoxContainer
var opponent_scroll: ScrollContainer
var opponent_box: HBoxContainer
var opponent_option: OptionButton
var reveal_target := -1
var reveal_option: OptionButton
var showdown_button: Button

func setup(p_status_label: Label, p_score_label: Label = null, p_rules_label: Label = null) -> void:
	status_label = p_status_label
	score_label = p_score_label
	rules_label = p_rules_label
	if rules_label != null:
		rules_label.text = "Five-card draw has one private five-card hand per player. Select up to three cards to replace, then draw/showdown. Strategy: keep made pairs or better, keep four-card flushes and open-ended straight draws, and discard isolated low cards."
	model = FiveCardDrawModel.new()
	model.new_hand()
	status_label.text = UiFactory.coach_message("Select up to three cards to replace, then draw.", model.guidance_text())
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
	deck_row = HBoxContainer.new()
	deck_row.alignment = BoxContainer.ALIGNMENT_CENTER
	deck_row.add_theme_constant_override("separation", 12)
	section.add_child(deck_row)
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
	showdown_button = UiFactory.make_action_button("Draw / Showdown", _showdown)
	controls.add_child(showdown_button)
	controls.add_child(UiFactory.make_secondary_button("New Hand", _restart))
	_update()

func _restart() -> void:
	model.new_hand()
	status_label.text = UiFactory.coach_message("New hand. Select up to three cards to replace, then draw.", model.guidance_text())
	_update()

func refresh_layout() -> void:
	_update()

func _opponent_count_selected(index: int) -> void:
	model.reset_score()
	model.set_opponent_count(index + 1)
	reveal_target = -1
	_populate_reveal_options()
	status_label.text = "Table size changed. Score reset for the new opponent count."
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

func _toggle(card: Dictionary) -> void:
	var message := model.toggle_discard(card)
	if message != "":
		status_label.text = message
	else:
		status_label.text = UiFactory.coach_message(
			"Selected discards: %s" % CardTools.cards_text(model.selected),
			model.guidance_text()
		)
	_update()

func _showdown() -> void:
	if model.done:
		return
	result_label.text = model.showdown()
	status_label.text = UiFactory.coach_message(
		"Draw/showdown complete.",
		"Review whether your discards preserved made pairs, trips, four-card flushes, and open-ended straight draws."
	)
	_update()

func _update() -> void:
	for child in hand_box.get_children():
		child.queue_free()
	for child in deck_row.get_children():
		child.queue_free()
	for child in opponent_box.get_children():
		child.queue_free()
	facts_label.text = "Valid players: 2-6 | Computer opponents: %d | %s" % [model.opponent_count, model.score_text()]
	if score_label != null:
		var eval_text: String = str(PokerEvaluator.evaluate_five(model.player)["name"])
		score_label.text = "%s\nComputer opponents: %d\nYour hand: %s\nSelected discards: %d" % [
			model.score_text(),
			model.opponent_count,
			eval_text,
			model.selected.size()
		]
	hand_scroll.custom_minimum_size = Vector2(0, UiFactory.hand_scroll_height(5))
	opponent_scroll.custom_minimum_size = Vector2(0, UiFactory.small_hand_scroll_height() + 48)
	deck_row.add_child(UiFactory.make_card_display("Deck", false, true))
	for i in range(model.bots.size()):
		opponent_box.add_child(_make_opponent_hand(i))
	if not model.done:
		result_label.text = model.prompt_text()
	showdown_button.disabled = model.done
	for card in model.player:
		var button := UiFactory.make_card_button(card, _toggle.bind(card), model.selected.has(card))
		if not model.selected.has(card) and model.suggested_discards().has(card):
			UiFactory.style_suggested_card_button(button)
			button.tooltip_text = "Coach suggestion: consider discarding this card."
		elif model.selected.has(card):
			button.tooltip_text = "Selected to discard."
		button.disabled = model.done
		hand_box.add_child(button)

func _make_opponent_hand(index: int) -> PanelContainer:
	var panel := UiFactory.make_panel()
	var card_size := UiFactory.small_card_control_size()
	var visible := _show_opponent_hand(index)
	panel.custom_minimum_size = Vector2(card_size.x * 5 + 78, card_size.y + 58) if visible else Vector2(card_size.x * 2 + 120, 58)
	panel.add_theme_stylebox_override("panel", UiFactory.panel_style(Color("#f4f7f8"), 7, Color("#c8bfae"), 1))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var label := Label.new()
	var eval_text := ""
	if _show_opponent_hand(index):
		var hand_eval := PokerEvaluator.evaluate_five(model.bots[index])
		eval_text = " - %s" % hand_eval["name"]
	else:
		eval_text = " - hidden"
	label.text = "Computer %d hand%s" % [index + 1, eval_text]
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
	return model.done or reveal_target == -2 or reveal_target == index
