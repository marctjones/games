class_name GinRummyView
extends VBoxContainer

const GinRummyModel := preload("res://scripts/games/gin_rummy/gin_rummy_model.gd")
const CardTools := preload("res://scripts/core/card_tools.gd")
const UiFactory := preload("res://scripts/ui/ui_factory.gd")

var status_label: Label
var score_label: Label
var rules_label: Label
var model: GinRummyModel
var hand_box: Container
var table_label: Label
var facts_label: Label
var phase_label: Label
var hand_label: Label
var pile_box: HBoxContainer
var opponent_box: VBoxContainer
var reveal_opponents := false
var reveal_toggle: CheckBox
var knock_button: Button

func setup(p_status_label: Label, p_score_label: Label = null, p_rules_label: Label = null) -> void:
	status_label = p_status_label
	score_label = p_score_label
	rules_label = p_rules_label
	model = GinRummyModel.new()
	model.new_hand()
	status_label.text = model.last_message
	if rules_label != null:
		rules_label.text = "On each turn, draw one card from the stock or discard pile, then discard one card. Melds are sets of equal rank or runs in one suit. Aces are low only: A-2-3 is a run, but Q-K-A is not. Deadwood is the unmatched card value. Knock when your deadwood is 10 or less; strategy favors building melds before dumping high cards."
	var section := UiFactory.make_section()
	add_child(section)
	table_label = UiFactory.make_info_label()
	section.add_child(table_label)
	facts_label = UiFactory.make_fact_label()
	section.add_child(facts_label)
	phase_label = Label.new()
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_label.add_theme_font_size_override("font_size", 22)
	phase_label.add_theme_color_override("font_color", Color("#17212b"))
	section.add_child(phase_label)
	pile_box = HBoxContainer.new()
	pile_box.alignment = BoxContainer.ALIGNMENT_CENTER
	pile_box.add_theme_constant_override("separation", 28)
	section.add_child(pile_box)
	opponent_box = VBoxContainer.new()
	opponent_box.add_theme_constant_override("separation", 6)
	section.add_child(opponent_box)
	var controls := UiFactory.make_button_row()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	section.add_child(controls)
	knock_button = UiFactory.make_action_button("Knock", _knock)
	controls.add_child(knock_button)
	controls.add_child(UiFactory.make_secondary_button("New Hand", _restart))
	reveal_toggle = CheckBox.new()
	reveal_toggle.text = "Reveal opponent hand"
	UiFactory.style_checkbox(reveal_toggle)
	reveal_toggle.button_pressed = reveal_opponents
	reveal_toggle.toggled.connect(_reveal_opponents_toggled)
	controls.add_child(reveal_toggle)
	hand_label = Label.new()
	hand_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hand_label.add_theme_font_size_override("font_size", 18)
	hand_label.add_theme_color_override("font_color", Color("#25313a"))
	section.add_child(hand_label)
	hand_box = VBoxContainer.new()
	hand_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_box.add_theme_constant_override("separation", 8)
	section.add_child(hand_box)
	_update()

func _restart() -> void:
	model.new_hand()
	status_label.text = model.last_message
	_update()

func refresh_layout() -> void:
	_update()

func _reveal_opponents_toggled(enabled: bool) -> void:
	reveal_opponents = enabled
	_update()

func _draw_stock() -> void:
	model.draw_stock()
	status_label.text = model.last_message
	_update()

func _draw_discard() -> void:
	model.draw_discard()
	status_label.text = model.last_message
	_update()

func _player_discard(card: Dictionary) -> void:
	model.player_discard(card)
	model.bot_turn()
	status_label.text = model.last_message
	_update()

func _knock() -> void:
	status_label.text = model.knock()
	_update()

func _update() -> void:
	for child in hand_box.get_children():
		child.queue_free()
	for child in pile_box.get_children():
		child.queue_free()
	for child in opponent_box.get_children():
		child.queue_free()
	table_label.text = model.table_text()
	status_label.text = UiFactory.coach_message(model.last_message, model.guidance_text())
	facts_label.text = "Valid players: 2 | Computer opponents: 1 | %s" % model.score_text()
	if score_label != null:
		score_label.text = "%s\nYour deadwood: %d\nComputer cards: %d\nTop discard: %s" % [
			model.score_text(),
			GinRummyModel.deadwood(model.player),
			model.bot.size(),
			top_card_text()
		]
	phase_label.text = _phase_text()
	hand_label.text = _hand_text()
	hand_box.add_theme_constant_override("separation", 8)
	knock_button.disabled = model.phase != "draw" or GinRummyModel.deadwood(model.player) > 10
	pile_box.add_child(_make_stock_pile())
	if not model.discard.is_empty():
		pile_box.add_child(_make_discard_pile())
	else:
		pile_box.add_child(_make_empty_discard_pile())
	_build_visible_computer_hand()
	var recommended_discard := {}
	if model.phase == "discard":
		recommended_discard = model.choose_discard(model.player)
	_build_grouped_hand(recommended_discard)

func _build_visible_computer_hand() -> void:
	var label := Label.new()
	label.text = "Computer hand - %s" % model.last_bot_action
	if _show_opponent_hand():
		label.text += " - deadwood %d" % GinRummyModel.deadwood(model.bot)
	else:
		label.text += " - hidden"
	label.add_theme_color_override("font_color", Color("#25313a"))
	opponent_box.add_child(label)
	if _show_opponent_hand():
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.custom_minimum_size = Vector2(0, UiFactory.small_hand_scroll_height())
		opponent_box.add_child(scroll)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", UiFactory.hand_card_gap())
		scroll.add_child(row)
		_build_visible_grouped_cards(row, model.bot)

func _show_opponent_hand() -> bool:
	return reveal_opponents or model.phase == "done"

func _make_hidden_card_group(title: String, count: int) -> PanelContainer:
	var panel := UiFactory.make_panel()
	var card_size := UiFactory.card_control_size()
	panel.custom_minimum_size = Vector2(card_size.x + 48, card_size.y + 58)
	panel.add_theme_stylebox_override("panel", UiFactory.panel_style(Color("#f4f7f8"), 7, Color("#c8bfae"), 1))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var label := Label.new()
	label.text = "%s (%d cards)" % [title, count]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("#17212b"))
	box.add_child(label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	for i in range(count):
		row.add_child(UiFactory.make_card_display("Hidden", false, true))
	return panel

func _build_visible_grouped_cards(parent: HBoxContainer, cards_source: Array) -> void:
	var meld_groups := GinRummyModel.best_meld_groups(cards_source)
	var used_indices := []
	var group_number := 1
	for group in meld_groups:
		var cards := []
		for index in group:
			used_indices.append(index)
			cards.append(cards_source[index])
		parent.add_child(_make_visible_card_group("Meld %d: %s" % [group_number, _meld_kind(cards)], cards, false))
		group_number += 1
	var deadwood_cards := []
	for i in range(cards_source.size()):
		if not used_indices.has(i):
			deadwood_cards.append(cards_source[i])
	if deadwood_cards.is_empty():
		parent.add_child(_make_note_group("Deadwood", "None."))
	else:
		parent.add_child(_make_visible_card_group("Deadwood: %d points" % GinRummyModel.deadwood(cards_source), deadwood_cards, true))

func _make_visible_card_group(title: String, cards: Array, is_deadwood: bool) -> PanelContainer:
	var panel := UiFactory.make_panel()
	var card_size := UiFactory.small_card_control_size()
	panel.custom_minimum_size = Vector2(card_size.x + 48, card_size.y + 58)
	panel.add_theme_stylebox_override("panel", UiFactory.panel_style(Color("#fffaf0") if is_deadwood else Color("#f4f7f8"), 7, Color("#c8bfae"), 1))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var label := Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("#17212b"))
	box.add_child(label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	for card in cards:
		row.add_child(UiFactory.make_small_card_display("", CardTools.is_red_suit(card.suit), false, card))
	return panel

func _build_grouped_hand(recommended_discard: Dictionary) -> void:
	var meld_groups := GinRummyModel.best_meld_groups(model.player)
	var used_indices := []
	var meld_cards := []
	for group in meld_groups:
		for index in group:
			used_indices.append(index)
			meld_cards.append(model.player[index])
	var deadwood_cards := []
	for i in range(model.player.size()):
		if not used_indices.has(i):
			deadwood_cards.append(model.player[i])
	meld_cards.sort_custom(CardTools.sort_cards)
	deadwood_cards.sort_custom(CardTools.sort_cards)
	hand_box.add_child(_make_stable_hand_section(
		"Melds: %d group%s" % [meld_groups.size(), "" if meld_groups.size() == 1 else "s"],
		meld_cards,
		recommended_discard,
		"No complete set or run yet. Build 3+ matching ranks or 3+ consecutive cards in one suit.",
		false
	))
	hand_box.add_child(_make_stable_hand_section(
		"Deadwood: %d points" % GinRummyModel.deadwood(model.player),
		deadwood_cards,
		recommended_discard,
		"None. You are gin unless you still need to discard.",
		true
	))

func _make_stable_hand_section(title: String, cards: Array, recommended_discard: Dictionary, empty_text: String, is_deadwood: bool) -> PanelContainer:
	var panel := UiFactory.make_panel()
	var fit_size := UiFactory.fit_card_control_size(11)
	panel.custom_minimum_size = Vector2(0, fit_size.y + 58)
	panel.add_theme_stylebox_override("panel", UiFactory.panel_style(Color("#fffaf0") if is_deadwood else Color("#f4f7f8"), 7, Color("#c8bfae"), 1))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var label := Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("#17212b"))
	box.add_child(label)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", UiFactory.hand_card_gap())
	if cards.is_empty():
		var note := Label.new()
		note.text = empty_text
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.custom_minimum_size = Vector2(0, max(58, int(fit_size.y * 0.45)))
		note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		note.add_theme_color_override("font_color", Color("#40515e"))
		box.add_child(note)
	else:
		box.add_child(row)
		for card in cards:
			row.add_child(_make_hand_card_button(card, recommended_discard, 11))
	return panel

func _make_card_group(title: String, cards: Array, recommended_discard: Dictionary, is_deadwood: bool) -> PanelContainer:
	var panel := UiFactory.make_panel()
	var card_size := UiFactory.card_control_size()
	panel.custom_minimum_size = Vector2(card_size.x + 48, card_size.y + 58)
	panel.add_theme_stylebox_override("panel", UiFactory.panel_style(Color("#fffaf0") if is_deadwood else Color("#f4f7f8"), 7, Color("#c8bfae"), 1))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var label := Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("#17212b"))
	box.add_child(label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	for card in cards:
		row.add_child(_make_hand_card_button(card, recommended_discard))
	return panel

func _make_note_group(title: String, text: String) -> PanelContainer:
	var panel := UiFactory.make_panel()
	var card_size := UiFactory.card_control_size()
	panel.custom_minimum_size = Vector2(card_size.x + 68, card_size.y + 58)
	panel.add_theme_stylebox_override("panel", UiFactory.panel_style(Color("#f4f7f8"), 7, Color("#c8bfae"), 1))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color("#17212b"))
	box.add_child(title_label)
	var body := Label.new()
	body.text = text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", Color("#40515e"))
	box.add_child(body)
	return panel

func _make_hand_card_button(card: Dictionary, recommended_discard: Dictionary, fit_count: int = 11) -> Button:
	var is_recommended: bool = model.phase == "discard" and card == recommended_discard
	var is_new_card := _is_last_drawn_card(card)
	var pressed := _player_discard.bind(card) if model.phase == "discard" else _inspect_hand_card.bind(card)
	var button := UiFactory.make_fit_card_button(card, pressed, is_recommended and not is_new_card, fit_count)
	if is_new_card:
		_style_new_drawn_card(button)
	if model.phase == "discard":
		if is_new_card and is_recommended:
			button.tooltip_text = "Newly drawn card. Coach suggestion: discard this card."
		elif is_new_card:
			button.tooltip_text = "Newly drawn card from the %s." % model.last_draw_source
		else:
			button.tooltip_text = "Discard this card." if not is_recommended else "Coach suggestion: discard this card."
	else:
		button.tooltip_text = "Keep reading your hand, then choose the stock pile or discard pile."
	return button

func _is_last_drawn_card(card: Dictionary) -> bool:
	return model.phase == "discard" and model.last_drawn_card.size() > 0 and card == model.last_drawn_card

func _style_new_drawn_card(button: Button) -> void:
	UiFactory.style_new_card_button(button)

func _inspect_hand_card(card: Dictionary) -> void:
	status_label.text = UiFactory.coach_message(
		"Choose from the stock or discard pile first.",
		"Your hand stays fully visible so you can decide which draw helps your melds."
	)

func _meld_kind(cards: Array) -> String:
	if cards.size() < 3:
		return "meld"
	var rank := str(cards[0].rank)
	var same_rank := true
	for card in cards:
		if str(card.rank) != rank:
			same_rank = false
	if same_rank:
		return "set"
	var suit := str(cards[0].suit)
	var same_suit := true
	for card in cards:
		if str(card.suit) != suit:
			same_suit = false
	if same_suit:
		return "run"
	return "meld"

func _make_stock_pile() -> VBoxContainer:
	var box := _make_pile_box("Stock pile", "%d cards" % model.deck.size())
	var button := _make_pile_button(UiFactory.make_card_back_texture(), _draw_stock)
	button.disabled = model.phase != "draw" or model.deck.is_empty()
	button.tooltip_text = "Draw an unknown card from the stock pile."
	box.add_child(button)
	return box

func _make_discard_pile() -> VBoxContainer:
	var top_card: Dictionary = model.discard[-1]
	var box := _make_pile_box("Discard pile", "Take %s" % top_card_text())
	var button := _make_pile_button(UiFactory.make_card_texture(top_card), _draw_discard)
	button.disabled = model.phase != "draw"
	button.tooltip_text = "Take the visible discard card."
	box.add_child(button)
	return box

func _make_empty_discard_pile() -> VBoxContainer:
	var box := _make_pile_box("Discard pile", "Empty")
	var display := UiFactory.make_card_display("Empty")
	display.modulate = Color(1, 1, 1, 0.55)
	box.add_child(display)
	return box

func _make_pile_box(title: String, subtitle: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color("#17212b"))
	box.add_child(title_label)
	var subtitle_label := Label.new()
	subtitle_label.text = subtitle
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_color_override("font_color", Color("#40515e"))
	box.add_child(subtitle_label)
	return box

func _make_pile_button(texture: Texture2D, pressed: Callable) -> Button:
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = UiFactory.card_control_size()
	button.icon = texture
	button.expand_icon = true
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.add_theme_constant_override("icon_max_width", UiFactory.card_icon_width())
	button.add_theme_stylebox_override("normal", UiFactory.panel_style(Color("#fffdf7"), 7, Color("#c8bfae"), 1))
	button.add_theme_stylebox_override("hover", UiFactory.panel_style(Color("#fff5d8"), 7, Color("#a9935d"), 1))
	button.add_theme_stylebox_override("pressed", UiFactory.panel_style(Color("#efd37a"), 7, Color("#8b7337"), 1))
	button.add_theme_stylebox_override("disabled", UiFactory.panel_style(Color("#e4dfd4"), 7, Color("#c8bfae"), 1))
	button.pressed.connect(pressed)
	return button

func _phase_text() -> String:
	match model.phase:
		"draw":
			return "Step 1: click either pile to draw one card"
		"discard":
			return "Step 2: click one card in your hand to discard"
		"bot":
			return "Computer is taking its turn"
		"done":
			return "Hand complete"
	return ""

func _hand_text() -> String:
	match model.phase:
		"draw":
			return "Your hand is locked until you draw."
		"discard":
			return "Choose one discard. The blue card is newly drawn; the gold card is the basic coach suggestion."
		"done":
			return "Start a new hand to keep practicing."
	return ""

func top_card_text() -> String:
	if model.discard.is_empty():
		return "none"
	var card: Dictionary = model.discard[-1]
	return "%s%s" % [card.rank, card.suit]
