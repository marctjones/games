class_name BlackjackView
extends VBoxContainer

const BlackjackModel := preload("res://scripts/games/blackjack/blackjack_model.gd")
const CardTools := preload("res://scripts/core/card_tools.gd")
const UiFactory := preload("res://scripts/ui/ui_factory.gd")

var status_label: Label
var score_label: Label
var rules_label: Label
var model: BlackjackModel
var dealer_box: HBoxContainer
var computer_scroll: ScrollContainer
var computer_box: HBoxContainer
var player_box: HBoxContainer
var facts_label: Label
var computer_option: OptionButton
var reveal_target := -1
var reveal_option: OptionButton
var hit_button: Button
var stand_button: Button
var double_button: Button
var split_button: Button
var current_message := ""

func setup(p_status_label: Label, p_score_label: Label = null, p_rules_label: Label = null) -> void:
	status_label = p_status_label
	score_label = p_score_label
	rules_label = p_rules_label
	if rules_label != null:
		rules_label.text = "Goal: beat the dealer without going over 21. Number cards count face value, face cards count 10, and aces count 1 or 11. The dealer stands on 17. This trainer supports hit, stand, one-card double-down, and one split when the first two cards have the same blackjack value. Strategy: decide against the dealer up-card; stand more often when the dealer shows 2-6, double strong 10/11 spots, and split aces/eights."
	model = BlackjackModel.new()
	model.new_hand()
	var section := UiFactory.make_section()
	add_child(section)
	var setup_row := UiFactory.make_button_row()
	setup_row.alignment = BoxContainer.ALIGNMENT_CENTER
	section.add_child(setup_row)
	var computer_label := Label.new()
	computer_label.text = "Computer seats"
	computer_label.add_theme_color_override("font_color", Color("#25313a"))
	setup_row.add_child(computer_label)
	computer_option = OptionButton.new()
	for i in range(0, 6):
		computer_option.add_item(str(i), i)
	computer_option.selected = model.computer_count
	computer_option.item_selected.connect(_computer_count_selected)
	setup_row.add_child(computer_option)
	reveal_option = OptionButton.new()
	reveal_option.item_selected.connect(_reveal_option_selected)
	setup_row.add_child(reveal_option)
	_populate_reveal_options()
	facts_label = UiFactory.make_fact_label()
	section.add_child(facts_label)
	var table_panel := UiFactory.make_panel()
	section.add_child(table_panel)
	var table := VBoxContainer.new()
	table.add_theme_constant_override("separation", 14)
	table_panel.add_child(table)
	var dealer_label := Label.new()
	dealer_label.text = "Dealer"
	dealer_label.add_theme_font_size_override("font_size", 16)
	dealer_label.add_theme_color_override("font_color", Color("#17212b"))
	dealer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table.add_child(dealer_label)
	dealer_box = HBoxContainer.new()
	dealer_box.alignment = BoxContainer.ALIGNMENT_CENTER
	dealer_box.add_theme_constant_override("separation", 10)
	table.add_child(dealer_box)
	var computer_label_row := Label.new()
	computer_label_row.text = "Computer seats"
	computer_label_row.add_theme_font_size_override("font_size", 16)
	computer_label_row.add_theme_color_override("font_color", Color("#17212b"))
	computer_label_row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table.add_child(computer_label_row)
	computer_scroll = ScrollContainer.new()
	computer_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	computer_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	table.add_child(computer_scroll)
	computer_box = HBoxContainer.new()
	computer_box.alignment = BoxContainer.ALIGNMENT_CENTER
	computer_box.add_theme_constant_override("separation", 14)
	computer_scroll.add_child(computer_box)
	var controls := UiFactory.make_button_row()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	table.add_child(controls)
	hit_button = UiFactory.make_action_button("Hit", _hit)
	stand_button = UiFactory.make_action_button("Stand", _stand)
	double_button = UiFactory.make_action_button("Double", _double_down)
	split_button = UiFactory.make_action_button("Split", _split_pair)
	controls.add_child(hit_button)
	controls.add_child(stand_button)
	controls.add_child(double_button)
	controls.add_child(split_button)
	controls.add_child(UiFactory.make_secondary_button("New Hand", _restart))
	var player_label := Label.new()
	player_label.text = "You"
	player_label.add_theme_font_size_override("font_size", 16)
	player_label.add_theme_color_override("font_color", Color("#17212b"))
	player_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table.add_child(player_label)
	player_box = HBoxContainer.new()
	player_box.alignment = BoxContainer.ALIGNMENT_CENTER
	player_box.add_theme_constant_override("separation", 10)
	table.add_child(player_box)
	_update("Decide whether to hit or stand. Basic dealer AI stands on 17.")

func _restart() -> void:
	model.new_hand()
	_update("New hand. Decide whether to hit or stand. Basic dealer AI stands on 17.")

func refresh_layout() -> void:
	_update(current_message)

func _computer_count_selected(index: int) -> void:
	model.reset_score()
	model.set_computer_count(index)
	reveal_target = -1
	_populate_reveal_options()
	_update("Computer seat count changed. Score reset for the new table.")

func _reveal_option_selected(index: int) -> void:
	reveal_target = reveal_option.get_item_id(index)
	_update(current_message)

func _populate_reveal_options() -> void:
	reveal_option.clear()
	reveal_option.add_item("Hide opponent hands", -1)
	reveal_option.add_item("Reveal dealer", -2)
	for i in range(model.computer_count):
		reveal_option.add_item("Reveal computer %d" % (i + 1), i)
	reveal_option.add_item("Reveal all", -3)
	for i in range(reveal_option.item_count):
		if reveal_option.get_item_id(i) == reveal_target:
			reveal_option.select(i)
			return
	reveal_option.select(0)

func _hit() -> void:
	_update(model.hit())

func _stand() -> void:
	_update(model.stand())

func _double_down() -> void:
	_update(model.double_down())

func _split_pair() -> void:
	_update(model.split_pair())

func _update(message: String) -> void:
	current_message = message
	for child in dealer_box.get_children():
		child.queue_free()
	for child in computer_box.get_children():
		child.queue_free()
	computer_scroll.custom_minimum_size = Vector2(0, UiFactory.small_card_control_size().y + 78)
	for i in range(model.dealer.size()):
		var hidden := i > 0 and not _show_dealer_hand()
		var card: Dictionary = model.dealer[i]
		dealer_box.add_child(UiFactory.make_card_display("??", CardTools.is_red_suit(card.suit), hidden, {} if hidden else card))
	if model.computer_hands.is_empty():
		computer_box.add_child(_make_empty_computer_note())
	for i in range(model.computer_hands.size()):
		computer_box.add_child(_make_computer_seat(i))
	for child in player_box.get_children():
		child.queue_free()
	for card in model.player:
		player_box.add_child(UiFactory.make_card_display("", CardTools.is_red_suit(card.suit), false, card))
	facts_label.text = "Valid players: 1 human plus dealer; optional 0-5 computer seats | %s" % model.score_text()
	if score_label != null:
		score_label.text = "%s\n%s\nDealer: %s (%s)\nComputer seats: %d" % [
			model.score_text(),
			model.player_table_text(),
			_dealer_cards_text(),
			_dealer_value_text(),
			model.computer_count
		]
	hit_button.disabled = model.done
	stand_button.disabled = model.done
	double_button.disabled = not model.can_double()
	split_button.disabled = not model.can_split()
	status_label.text = UiFactory.coach_message(
		message,
		model.basic_strategy_hint(),
		"Current read: you have %d against dealer %s." % [model.hand_value(model.player), _dealer_value_text()]
	)

func _make_computer_seat(index: int) -> PanelContainer:
	var panel := UiFactory.make_panel()
	panel.add_theme_stylebox_override("panel", UiFactory.panel_style(Color("#f4f7f8"), 7, Color("#c8bfae"), 1))
	var card_size := UiFactory.small_card_control_size()
	panel.custom_minimum_size = Vector2(card_size.x * 2 + 58, card_size.y + 58)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var label := Label.new()
	var outcome := ""
	if model.done:
		outcome = " - %s" % model.computer_results[index]
	elif _show_computer_hand(index):
		outcome = " - %s" % _blackjack_hand_note(model.computer_hands[index])
	else:
		outcome = " - hidden"
	label.text = "Computer %d%s" % [index + 1, outcome]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("#17212b"))
	box.add_child(label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	for card in model.computer_hands[index]:
		if _show_computer_hand(index):
			row.add_child(UiFactory.make_small_card_display("", CardTools.is_red_suit(card.suit), false, card))
		else:
			row.add_child(UiFactory.make_small_card_display("Hidden", false, true))
	return panel

func _show_dealer_hand() -> bool:
	return model.done or reveal_target == -2 or reveal_target == -3

func _show_computer_hand(index: int) -> bool:
	return model.done or reveal_target == -3 or reveal_target == index

func _dealer_cards_text() -> String:
	var parts := []
	for i in range(model.dealer.size()):
		if i > 0 and not _show_dealer_hand():
			parts.append("??")
		else:
			parts.append(CardTools.card_text(model.dealer[i]))
	return CardTools.join_strings(parts, " ")

func _dealer_value_text() -> String:
	if _show_dealer_hand():
		return str(model.hand_value(model.dealer))
	return "shown %s" % CardTools.card_text(model.dealer[0])

func _computer_summary_text() -> String:
	if model.computer_hands.is_empty():
		return "No computer seats."
	var lines := []
	for i in range(model.computer_hands.size()):
		if _show_computer_hand(i):
			var result := ""
			if model.done:
				result = " - %s" % model.computer_results[i]
			lines.append("Computer %d: %s (%d)%s" % [
				i + 1,
				CardTools.cards_text(model.computer_hands[i]),
				model.hand_value(model.computer_hands[i]),
				result
			])
		else:
			lines.append("Computer %d: hidden (%d cards)" % [i + 1, model.computer_hands[i].size()])
	return CardTools.join_strings(lines, "\n")

func _blackjack_hand_note(hand: Array) -> String:
	var total := model.hand_value(hand)
	if total > 21:
		return "%d bust" % total
	if total >= 17:
		return "%d stand" % total
	return "%d draw" % total

func _make_empty_computer_note() -> PanelContainer:
	var panel := UiFactory.make_panel()
	panel.custom_minimum_size = Vector2(UiFactory.card_control_size().x * 2, UiFactory.card_control_size().y * 0.55)
	panel.add_theme_stylebox_override("panel", UiFactory.panel_style(Color("#f4f7f8"), 7, Color("#c8bfae"), 1))
	var label := Label.new()
	label.text = "No computer seats at this table."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("#40515e"))
	panel.add_child(label)
	return panel
