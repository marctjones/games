class_name HeartsView
extends VBoxContainer

const HeartsModel := preload("res://scripts/games/hearts/hearts_model.gd")
const CardTools := preload("res://scripts/core/card_tools.gd")
const UiFactory := preload("res://scripts/ui/ui_factory.gd")

var status_label: Label
var score_label: Label
var rules_label: Label
var model: HeartsModel
var hand_scroll: ScrollContainer
var hand_box: Container
var table_label: Label
var facts_label: Label
var table_grid: GridContainer
var opponent_box: VBoxContainer
var reveal_target := 0
var reveal_option: OptionButton

func setup(p_status_label: Label, p_score_label: Label = null, p_rules_label: Label = null) -> void:
	status_label = p_status_label
	score_label = p_score_label
	rules_label = p_rules_label
	status_label.text = "You are South. Basic bots follow suit and otherwise dump high penalty cards. Passing is automatic by round direction."
	if rules_label != null:
		rules_label.text = "Hearts is a trick-taking game where low score is best. Follow suit if you can. Hearts are 1 penalty point each and the queen of spades is 13. Each round now auto-passes three risk cards left, right, across, then hold. Strategy: avoid winning penalty tricks, lead safe low cards, and discard dangerous penalty cards when void in the led suit."
	model = HeartsModel.new()
	model.new_round()
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
	var hand := UiFactory.make_hand_scroll()
	hand_scroll = hand["scroll"]
	hand_box = hand["row"]
	section.add_child(hand_scroll)
	var row := UiFactory.make_button_row()
	row.add_child(UiFactory.make_secondary_button("New Round", _restart))
	reveal_option = OptionButton.new()
	reveal_option.add_item("Hide opponent hands", 0)
	reveal_option.add_item("Reveal West", 1)
	reveal_option.add_item("Reveal North", 2)
	reveal_option.add_item("Reveal East", 3)
	reveal_option.add_item("Reveal all", 4)
	reveal_option.item_selected.connect(_reveal_option_selected)
	row.add_child(reveal_option)
	section.add_child(row)
	model.advance_bots()
	_update()

func _restart() -> void:
	model.new_round()
	status_label.text = "New round. You are South. %s" % model.pass_summary
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

func _update() -> void:
	for child in hand_box.get_children():
		child.queue_free()
	for child in table_grid.get_children():
		child.queue_free()
	for child in opponent_box.get_children():
		child.queue_free()
	table_label.text = model.table_text()
	facts_label.text = "Valid players: 4 | Computer opponents: 3 | %s" % model.match_score_text()
	if score_label != null:
		score_label.text = "%s\nRound - You: %d  West: %d  North: %d  East: %d\nTurn: %s" % [
			model.match_score_text(),
			model.scores[0],
			model.scores[1],
			model.scores[2],
			model.scores[3],
			HeartsModel.player_name(model.turn)
		]
	hand_scroll.custom_minimum_size = Vector2(0, UiFactory.hand_scroll_height(13))
	_build_table()
	_build_opponent_hands()
	status_label.text = UiFactory.coach_message(model.status_text(), model.player_guidance_text())
	if model.round_over:
		return
	var legal := model.legal_cards(0)
	var suggested := model.suggest_player_card(legal) if model.turn == 0 and not legal.is_empty() else {}
	for card in model.hands[0]:
		var button := UiFactory.make_card_button(card, _card_pressed.bind(card))
		button.disabled = model.turn != 0 or not legal.has(card)
		if suggested.size() > 0 and card == suggested:
			UiFactory.style_suggested_card_button(button)
			button.tooltip_text = "Coach suggestion: play this card."
		hand_box.add_child(button)

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
		trick.add_child(UiFactory.make_card_display("", false, false, play["card"]))
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
	if _should_reveal_player(player_index):
		label.text += " - %s" % _hearts_hand_note(cards)
	else:
		label.text += " - hidden"
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

func _should_reveal_player(player_index: int) -> bool:
	return reveal_target == 4 or reveal_target == player_index

func _hearts_hand_note(cards: Array) -> String:
	var heart_count := 0
	var has_queen_spades := false
	var suit_counts := {"S": 0, "H": 0, "D": 0, "C": 0}
	for card in cards:
		suit_counts[card.suit] = int(suit_counts.get(card.suit, 0)) + 1
		if card.suit == "H":
			heart_count += 1
		elif card.suit == "S" and card.rank == "Q":
			has_queen_spades = true
	var voids := []
	for suit in CardTools.SUITS:
		if int(suit_counts[suit]) == 0:
			voids.append(suit)
	var queen_text := "queen of spades" if has_queen_spades else "no queen of spades"
	var void_text := "void in %s" % CardTools.join_strings(voids, ", ") if not voids.is_empty() else "no void suits"
	return "%d hearts, %s, %s" % [heart_count, queen_text, void_text]

func _seat_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(120, 52)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("#25313a"))
	return label
