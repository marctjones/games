class_name CanastaView
extends VBoxContainer

const CanastaModel := preload("res://scripts/games/canasta/canasta_model.gd")
const CardTools := preload("res://scripts/core/card_tools.gd")
const UiFactory := preload("res://scripts/ui/ui_factory.gd")

var status_label: Label
var score_label: Label
var rules_label: Label
var model: CanastaModel
var facts_label: Label
var phase_label: Label
var pile_box: HBoxContainer
var selected_box: HFlowContainer
var hand_box: HFlowContainer
var player_melds_box: VBoxContainer
var computer_melds_box: VBoxContainer
var opponent_box: HFlowContainer
var reveal_toggle: CheckBox
var meld_button: Button
var discard_button: Button
var reveal_opponent := false

func setup(p_status_label: Label, p_score_label: Label = null, p_rules_label: Label = null) -> void:
	status_label = p_status_label
	score_label = p_score_label
	rules_label = p_rules_label
	model = CanastaModel.new()
	model.new_hand()
	if rules_label != null:
		rules_label.text = "Canasta trainer: draw two from stock or take a legal discard, make same-rank melds of 3 or more, and discard one card to end the turn. Twos are wild, but melds need at least two natural cards. Red threes are automatic 100-point bonuses. A discard pile topped by a wild card or red three is frozen and cannot be taken without the natural pair requirement. Seven-card melds receive a canasta bonus."
	status_label.text = UiFactory.coach_message(model.last_message, model.guidance_text())
	var section := UiFactory.make_section()
	add_child(section)
	facts_label = UiFactory.make_fact_label()
	section.add_child(facts_label)
	phase_label = Label.new()
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	phase_label.add_theme_font_size_override("font_size", 22)
	phase_label.add_theme_color_override("font_color", Color("#17212b"))
	section.add_child(phase_label)
	pile_box = HBoxContainer.new()
	pile_box.alignment = BoxContainer.ALIGNMENT_CENTER
	pile_box.add_theme_constant_override("separation", 28)
	section.add_child(pile_box)
	var controls := UiFactory.make_button_row()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	section.add_child(controls)
	meld_button = UiFactory.make_action_button("Meld", _meld_selected)
	discard_button = UiFactory.make_action_button("Discard", _discard_selected)
	controls.add_child(meld_button)
	controls.add_child(discard_button)
	controls.add_child(UiFactory.make_secondary_button("New Hand", _restart))
	reveal_toggle = CheckBox.new()
	reveal_toggle.text = "Reveal opponent hand"
	UiFactory.style_checkbox(reveal_toggle)
	reveal_toggle.toggled.connect(_reveal_toggled)
	controls.add_child(reveal_toggle)
	selected_box = HFlowContainer.new()
	selected_box.alignment = FlowContainer.ALIGNMENT_CENTER
	selected_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selected_box.add_theme_constant_override("h_separation", UiFactory.hand_card_gap())
	selected_box.add_theme_constant_override("v_separation", UiFactory.hand_card_gap())
	section.add_child(_wrap_labeled("Selected cards", selected_box, Color("#fffdf7")))
	hand_box = HFlowContainer.new()
	hand_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_box.add_theme_constant_override("h_separation", UiFactory.hand_card_gap())
	hand_box.add_theme_constant_override("v_separation", UiFactory.hand_card_gap())
	section.add_child(_wrap_labeled("Your hand", hand_box, Color("#fffaf0")))
	player_melds_box = VBoxContainer.new()
	player_melds_box.add_theme_constant_override("separation", 6)
	section.add_child(_wrap_labeled("Your melds", player_melds_box, Color("#f4f7f8")))
	computer_melds_box = VBoxContainer.new()
	computer_melds_box.add_theme_constant_override("separation", 6)
	section.add_child(_wrap_labeled("Computer melds", computer_melds_box, Color("#f4f7f8")))
	opponent_box = HFlowContainer.new()
	opponent_box.alignment = FlowContainer.ALIGNMENT_CENTER
	opponent_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opponent_box.add_theme_constant_override("h_separation", 8)
	opponent_box.add_theme_constant_override("v_separation", 8)
	section.add_child(_wrap_labeled("Computer hand", opponent_box, Color("#f7f4ee")))
	_update()

func _restart() -> void:
	model.new_hand()
	status_label.text = UiFactory.coach_message(model.last_message, model.guidance_text())
	_update()

func refresh_layout() -> void:
	_update()

func _reveal_toggled(enabled: bool) -> void:
	reveal_opponent = enabled
	_update()

func _draw_stock() -> void:
	model.draw_stock()
	status_label.text = UiFactory.coach_message(model.last_message, model.guidance_text())
	_update()

func _draw_discard() -> void:
	model.draw_discard()
	status_label.text = UiFactory.coach_message(model.last_message, model.guidance_text())
	_update()

func _toggle_card(card: Dictionary) -> void:
	model.toggle_selected(card)
	status_label.text = UiFactory.coach_message(_selection_hint(), model.guidance_text())
	_update()

func _meld_selected() -> void:
	var message := model.meld_selected()
	status_label.text = UiFactory.coach_message(message, model.guidance_text())
	_update()

func _discard_selected() -> void:
	var message := model.discard_selected()
	status_label.text = UiFactory.coach_message(message, model.guidance_text())
	_update()

func _update() -> void:
	_clear_children(pile_box)
	_clear_children(selected_box)
	_clear_children(hand_box)
	_clear_children(player_melds_box)
	_clear_children(computer_melds_box)
	_clear_children(opponent_box)
	facts_label.text = "Valid players: 2 | Computer opponents: 1\n%s" % model.table_text()
	phase_label.text = _phase_text()
	if score_label != null:
		score_label.text = "%s\nThis hand - You melded: %d, in hand: %d\nComputer melded: %d, in hand: %d" % [
			model.score_text(),
			model.table_points(model.player_melds),
			model.hand_points(model.player),
			model.table_points(model.bot_melds),
			model.hand_points(model.bot)
		]
	pile_box.add_child(_make_stock_pile())
	pile_box.add_child(_make_discard_pile())
	_build_selected_cards()
	_build_hand()
	_build_melds(player_melds_box, model.player_melds)
	_build_melds(computer_melds_box, model.bot_melds)
	_build_opponent_hand()
	_refresh_buttons()

func _build_selected_cards() -> void:
	if model.selected.is_empty():
		var label := UiFactory.make_fact_label()
		label.text = "Choose matching ranks from your hand."
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		selected_box.add_child(label)
		return
	for card in model.selected:
		selected_box.add_child(UiFactory.make_fit_card_button(card, _toggle_card.bind(card), true, 14))

func _build_hand() -> void:
	for card in model.player:
		var selected := model.selected.has(card)
		var button := UiFactory.make_fit_card_button(card, _toggle_card.bind(card), selected, 15)
		if selected:
			button.tooltip_text = "Selected for meld or discard."
		button.disabled = model.done
		hand_box.add_child(button)

func _build_melds(parent: VBoxContainer, melds: Array) -> void:
	if melds.is_empty():
		var label := UiFactory.make_fact_label()
		label.text = "No melds yet."
		parent.add_child(label)
		return
	for i in range(melds.size()):
		var row := HFlowContainer.new()
		row.add_theme_constant_override("h_separation", UiFactory.hand_card_gap())
		row.add_theme_constant_override("v_separation", UiFactory.hand_card_gap())
		var title := Label.new()
		title.text = "%d (%d pts)" % [i + 1, model.meld_points(melds[i])]
		title.custom_minimum_size = Vector2(78, 0)
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title.add_theme_color_override("font_color", Color("#40515e"))
		row.add_child(title)
		for card in melds[i]:
			row.add_child(UiFactory.make_small_card_display("", CardTools.is_red_suit(card.suit), false, card))
		parent.add_child(row)

func _build_opponent_hand() -> void:
	if reveal_opponent or model.done:
		for card in model.bot:
			opponent_box.add_child(UiFactory.make_small_card_display("", CardTools.is_red_suit(card.suit), false, card))
	else:
		var label := Label.new()
		label.text = "Hidden (%d cards). Use Reveal opponent hand to inspect." % model.bot.size()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color("#40515e"))
		opponent_box.add_child(label)

func _refresh_buttons() -> void:
	meld_button.disabled = model.phase != "act" or model.done or not model.is_valid_meld(model.selected)
	discard_button.disabled = model.phase != "act" or model.done or model.selected.size() != 1

func _make_stock_pile() -> VBoxContainer:
	var box := _make_pile_box("Stock pile", "%d cards" % model.deck.size())
	var button := _make_pile_button(UiFactory.make_card_back_texture(), _draw_stock)
	button.disabled = model.phase != "draw" or model.done
	button.tooltip_text = "Draw two unknown cards from the stock pile."
	box.add_child(button)
	return box

func _make_discard_pile() -> VBoxContainer:
	var top_text := "Empty" if model.discard.is_empty() else "Take %s" % top_card_text()
	if model.is_discard_frozen():
		top_text += " (frozen)"
	var box := _make_pile_box("Discard pile", top_text)
	var texture := UiFactory.make_card_back_texture() if model.discard.is_empty() else UiFactory.make_card_texture(model.discard[-1])
	var button := _make_pile_button(texture, _draw_discard)
	button.disabled = model.phase != "draw" or model.discard.is_empty() or model.done or not model.can_take_discard(model.player)
	button.tooltip_text = "Take the visible discard card."
	box.add_child(button)
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

func _selection_hint() -> String:
	if model.selected.is_empty():
		return "Select cards to meld or one card to discard."
	if model.is_valid_meld(model.selected):
		return "Selected cards form a valid same-rank meld worth %d points." % model.meld_points(model.selected)
	if model.selected.size() == 1:
		return "Selected one card. Discard it, or select matching ranks to meld."
	return "Selected cards are not a same-rank meld yet."

func _phase_text() -> String:
	match model.phase:
		"draw":
			return "1. Draw: stock or discard"
		"act":
			return "2. Act: meld same ranks, then discard"
		"bot":
			return "Computer turn"
		"done":
			return "Hand complete"
	return ""

func top_card_text() -> String:
	if model.discard.is_empty():
		return "none"
	var card: Dictionary = model.discard[-1]
	return CardTools.card_text(card)

func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.queue_free()
