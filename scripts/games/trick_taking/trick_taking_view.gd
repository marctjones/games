class_name TrickTakingView
extends VBoxContainer

const TrickTakingModel := preload("res://scripts/games/trick_taking/trick_taking_model.gd")
const CardTools := preload("res://scripts/core/card_tools.gd")
const UiFactory := preload("res://scripts/ui/ui_factory.gd")

var status_label: Label
var score_label: Label
var rules_label: Label
var model: TrickTakingModel
var mode := "spades"
var facts_label: Label
var table_label: Label
var table_grid: GridContainer
var opponent_box: VBoxContainer
var hand_scroll: ScrollContainer
var hand_box: Container
var reveal_option: OptionButton
var reveal_target := 0
var contract_row: HBoxContainer
var contract_option: OptionButton
var contract_confirm_button: Button

func game_mode() -> String:
	return mode

func setup(p_status_label: Label, p_score_label: Label = null, p_rules_label: Label = null) -> void:
	status_label = p_status_label
	score_label = p_score_label
	rules_label = p_rules_label
	model = TrickTakingModel.new()
	model.new_round(game_mode())
	if rules_label != null:
		rules_label.text = model.rules_summary
	status_label.text = UiFactory.coach_message(model.status_text(), model.guidance_text())
	var section := UiFactory.make_section()
	add_child(section)
	facts_label = UiFactory.make_fact_label()
	section.add_child(facts_label)
	table_label = UiFactory.make_info_label()
	section.add_child(table_label)
	table_grid = GridContainer.new()
	table_grid.columns = 3
	table_grid.add_theme_constant_override("h_separation", 12)
	table_grid.add_theme_constant_override("v_separation", 10)
	section.add_child(table_grid)
	opponent_box = VBoxContainer.new()
	opponent_box.add_theme_constant_override("separation", 8)
	section.add_child(opponent_box)
	contract_row = UiFactory.make_button_row()
	var contract_label := Label.new()
	contract_label.text = "Contract"
	contract_label.add_theme_color_override("font_color", Color("#25313a"))
	contract_row.add_child(contract_label)
	contract_option = OptionButton.new()
	UiFactory.style_option_button(contract_option)
	contract_option.item_selected.connect(_contract_option_selected)
	contract_row.add_child(contract_option)
	contract_confirm_button = UiFactory.make_action_button("Confirm", _confirm_contract_choice)
	contract_row.add_child(contract_confirm_button)
	section.add_child(contract_row)
	var hand := UiFactory.make_hand_scroll()
	hand_scroll = hand["scroll"]
	hand_box = hand["row"]
	section.add_child(hand_scroll)
	var controls := UiFactory.make_button_row()
	controls.add_child(UiFactory.make_secondary_button("New Round", _restart))
	reveal_option = OptionButton.new()
	reveal_option.add_item("Hide opponent hands", 0)
	reveal_option.add_item("Reveal West", 1)
	reveal_option.add_item("Reveal North", 2)
	reveal_option.add_item("Reveal East", 3)
	reveal_option.add_item("Reveal all", 4)
	reveal_option.item_selected.connect(_reveal_option_selected)
	controls.add_child(reveal_option)
	section.add_child(controls)
	model.advance_bots()
	_update()

func _restart() -> void:
	model.new_round(game_mode())
	status_label.text = UiFactory.coach_message(model.status_text(), model.guidance_text())
	model.advance_bots()
	_update()

func refresh_layout() -> void:
	_update()

func _reveal_option_selected(index: int) -> void:
	reveal_target = reveal_option.get_item_id(index)
	_update()

func _card_pressed(card: Dictionary) -> void:
	var message := model.play_player_card(card)
	if message != "":
		status_label.text = message
		return
	_update()

func _contract_option_selected(index: int) -> void:
	model.select_contract_option(index)
	status_label.text = UiFactory.coach_message(model.status_text(), model.guidance_text())

func _confirm_contract_choice() -> void:
	var message := model.confirm_contract_selection()
	status_label.text = UiFactory.coach_message(message if message != "" else model.status_text(), model.guidance_text())
	model.advance_bots()
	_update()

func _update() -> void:
	_clear_children(hand_box)
	_clear_children(table_grid)
	_clear_children(opponent_box)
	table_label.text = model.table_text()
	facts_label.text = "Valid players: 4 | Computer opponents: 3 | Team game\n%s" % model.score_text()
	if score_label != null:
		score_label.text = "%s\nTurn: %s" % [model.score_text(), TrickTakingModel.player_name(model.turn)]
	_refresh_contract_controls()
	hand_scroll.custom_minimum_size = Vector2(0, UiFactory.hand_scroll_height(model.hand_size))
	_build_table()
	_build_opponent_hands()
	status_label.text = UiFactory.coach_message(model.status_text(), model.guidance_text())
	if model.round_over or model.is_waiting_for_player_contract():
		return
	var legal := model.legal_cards(0)
	var suggested := model.suggest_player_card() if model.turn == 0 else {}
	for card in model.hands[0]:
		var button := UiFactory.make_card_button(card, _card_pressed.bind(card))
		button.disabled = model.turn != 0 or not legal.has(card)
		if suggested.size() > 0 and card == suggested:
			UiFactory.style_suggested_card_button(button)
			button.tooltip_text = "Coach suggestion: play this card."
		hand_box.add_child(button)

func _refresh_contract_controls() -> void:
	if contract_row == null or contract_option == null or contract_confirm_button == null:
		return
	var waiting := model.is_waiting_for_player_contract()
	contract_row.visible = waiting
	if not waiting:
		return
	contract_option.clear()
	for i in range(model.contract_option_labels().size()):
		contract_option.add_item(str(model.contract_option_labels()[i]), i)
	contract_option.select(model.selected_contract_option)
	contract_confirm_button.disabled = contract_option.item_count == 0

func _build_table() -> void:
	table_grid.add_child(_seat_label(""))
	table_grid.add_child(_seat_label("North\n%d cards" % model.hands[2].size()))
	table_grid.add_child(_seat_label(""))
	table_grid.add_child(_seat_label("West\n%d cards" % model.hands[1].size()))
	var trick := HBoxContainer.new()
	var card_size := UiFactory.card_control_size()
	trick.custom_minimum_size = Vector2(card_size.x * 4 + 80, card_size.y + 20)
	trick.alignment = BoxContainer.ALIGNMENT_CENTER
	trick.add_theme_constant_override("separation", 8)
	for play in model.current_trick:
		var card: Dictionary = play["card"]
		trick.add_child(UiFactory.make_card_display("", CardTools.is_red_suit(card.suit), false, card))
	table_grid.add_child(trick)
	table_grid.add_child(_seat_label("East\n%d cards" % model.hands[3].size()))
	table_grid.add_child(_seat_label(""))
	table_grid.add_child(_seat_label("You\n%d cards" % model.hands[0].size()))
	table_grid.add_child(_seat_label(""))

func _build_opponent_hands() -> void:
	opponent_box.add_child(_make_visible_hand_row("North hand", model.hands[2], 2))
	opponent_box.add_child(_make_visible_hand_row("West hand", model.hands[1], 1))
	opponent_box.add_child(_make_visible_hand_row("East hand", model.hands[3], 3))

func _make_visible_hand_row(title: String, cards: Array, player_index: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var label := Label.new()
	label.text = "%s (%d cards)" % [title, cards.size()]
	label.text += " - %s" % _hand_note(cards) if _should_reveal_player(player_index) else " - hidden"
	label.add_theme_color_override("font_color", Color("#25313a"))
	box.add_child(label)
	if not _should_reveal_player(player_index):
		return box
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, UiFactory.small_hand_scroll_height())
	box.add_child(scroll)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UiFactory.hand_card_gap())
	scroll.add_child(row)
	for card in cards:
		row.add_child(UiFactory.make_small_card_display("", CardTools.is_red_suit(card.suit), false, card))
	return box

func _hand_note(cards: Array) -> String:
	var suit_counts := {"S": 0, "H": 0, "D": 0, "C": 0}
	var high_cards := 0
	for card in cards:
		suit_counts[card.suit] = int(suit_counts.get(card.suit, 0)) + 1
		if CardTools.rank_value(card.rank) >= 11:
			high_cards += 1
	var voids := []
	for suit in CardTools.SUITS:
		if int(suit_counts[suit]) == 0:
			voids.append(suit)
	var void_text := "void %s" % CardTools.join_strings(voids, ",") if not voids.is_empty() else "no voids"
	return "%d high cards, %s" % [high_cards, void_text]

func _should_reveal_player(player_index: int) -> bool:
	return reveal_target == 4 or reveal_target == player_index

func _seat_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(120, 52)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("#25313a"))
	return label

func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.queue_free()
