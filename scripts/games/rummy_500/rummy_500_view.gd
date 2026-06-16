class_name Rummy500View
extends VBoxContainer

const Rummy500Model := preload("res://scripts/games/rummy_500/rummy_500_model.gd")
const CardTools := preload("res://scripts/core/card_tools.gd")
const RummyTools := preload("res://scripts/games/rummy/rummy_tools.gd")
const UiFactory := preload("res://scripts/ui/ui_factory.gd")

var status_label: Label
var score_label: Label
var rules_label: Label
var model: Rummy500Model
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
var layoff_button: Button
var discard_button: Button
var reveal_opponent := false

func setup(p_status_label: Label, p_score_label: Label = null, p_rules_label: Label = null) -> void:
	status_label = p_status_label
	score_label = p_score_label
	rules_label = p_rules_label
	model = Rummy500Model.new()
	model.new_hand()
	status_label.text = UiFactory.coach_message(model.last_message, model.guidance_text())
	if rules_label != null:
		rules_label.text = "Rummy 500: draw from stock or from the visible discard spread, then meld sets/runs, lay off single cards on existing melds, and discard one card to end your turn. You may take a lower discard only if you also take every newer discard above it and immediately use the selected card in a meld or layoff. Melded cards score immediately; cards left in hand count against you when someone goes out. Aces are low in runs in this trainer."
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
	pile_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pile_box.add_theme_constant_override("separation", 28)
	section.add_child(pile_box)
	var controls := UiFactory.make_button_row()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	section.add_child(controls)
	meld_button = UiFactory.make_action_button("Meld", _meld_selected)
	layoff_button = UiFactory.make_secondary_button("Lay Off", _layoff_selected)
	discard_button = UiFactory.make_action_button("Discard", _discard_selected)
	controls.add_child(meld_button)
	controls.add_child(layoff_button)
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
	section.add_child(_wrap_labeled("Your table melds", player_melds_box, Color("#f4f7f8")))
	computer_melds_box = VBoxContainer.new()
	computer_melds_box.add_theme_constant_override("separation", 6)
	section.add_child(_wrap_labeled("Computer table melds", computer_melds_box, Color("#f4f7f8")))
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

func _draw_discard_at(discard_index: int) -> void:
	model.draw_discard_at(discard_index)
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

func _layoff_selected() -> void:
	var message := model.layoff_selected()
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
	facts_label.text = _facts_text()
	phase_label.text = _phase_text()
	if score_label != null:
		score_label.text = _score_text()
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
		if model.has_pickup_requirement():
			label.text = "Select %s with a meld, or select it alone for a legal layoff." % CardTools.card_text(model.required_pickup_card)
		else:
			label.text = "Choose cards in your hand."
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.custom_minimum_size = Vector2(0, UiFactory.info_font_size() * 2)
		selected_box.add_child(label)
		return
	for card in model.selected:
		selected_box.add_child(UiFactory.make_fit_card_button(card, _toggle_card.bind(card), true, 13))

func _build_hand() -> void:
	hand_box.add_theme_constant_override("h_separation", UiFactory.hand_card_gap())
	hand_box.add_theme_constant_override("v_separation", UiFactory.hand_card_gap())
	var suggested_discard := RummyTools.choose_discard(model.player) if model.phase == "act" and not model.player.is_empty() else {}
	for card in model.player:
		var selected := model.selected.has(card)
		var button := UiFactory.make_fit_card_button(card, _toggle_card.bind(card), selected, 14)
		if _is_last_drawn_card(card):
			_style_new_drawn_card(button)
			button.tooltip_text = "Newly drawn card from the %s." % model.last_draw_source
			if model.has_pickup_requirement() and card == model.required_pickup_card:
				button.tooltip_text = "Required discard-pile pickup card. Use it in a meld or layoff before discarding."
		elif suggested_discard.size() > 0 and card == suggested_discard and not selected:
			UiFactory.style_suggested_card_button(button)
			button.tooltip_text = "Coach suggestion: likely discard if you do not meld or lay off."
		elif selected:
			button.tooltip_text = "Selected for meld, layoff, or discard."
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
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("h_separation", UiFactory.hand_card_gap())
		row.add_theme_constant_override("v_separation", UiFactory.hand_card_gap())
		var title := Label.new()
		title.text = "%d" % (i + 1)
		title.custom_minimum_size = Vector2(24, 0)
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
	var valid_meld := RummyTools.is_valid_meld(model.selected)
	var can_layoff := model.selected.size() == 1 and _selected_can_layoff()
	var requirement_satisfied := not model.has_pickup_requirement() or model.selected.has(model.required_pickup_card)
	meld_button.disabled = model.phase != "act" or model.done or not valid_meld or not requirement_satisfied
	layoff_button.disabled = model.phase != "act" or model.done or not can_layoff or not requirement_satisfied
	discard_button.disabled = model.phase != "act" or model.done or model.selected.size() != 1 or model.has_pickup_requirement()

func _selected_can_layoff() -> bool:
	if model.selected.size() != 1:
		return false
	var card: Dictionary = model.selected[0]
	for meld in model.player_melds:
		if RummyTools.can_layoff(card, meld):
			return true
	for meld in model.bot_melds:
		if RummyTools.can_layoff(card, meld):
			return true
	return false

func _make_stock_pile() -> VBoxContainer:
	var box := _make_pile_box("Stock pile", "%d cards" % model.deck.size())
	var button := _make_pile_button(UiFactory.make_card_back_texture(), _draw_stock)
	button.disabled = model.phase != "draw" or model.deck.is_empty() or model.done
	button.tooltip_text = "Draw an unknown card from the stock pile."
	box.add_child(button)
	return box

func _make_discard_pile() -> VBoxContainer:
	if model.allow_discard_pile_pickup:
		return _make_spread_discard_pile()
	return _make_top_discard_pile()

func _make_top_discard_pile() -> VBoxContainer:
	var top_text := "Empty" if model.discard.is_empty() else "Take %s" % top_card_text()
	var box := _make_pile_box("Discard pile", top_text)
	var texture := UiFactory.make_card_back_texture() if model.discard.is_empty() else UiFactory.make_card_texture(model.discard[-1])
	var button := _make_pile_button(texture, _draw_discard)
	button.disabled = model.phase != "draw" or model.discard.is_empty() or model.done
	button.tooltip_text = "Take the visible discard card."
	box.add_child(button)
	return box

func _make_spread_discard_pile() -> VBoxContainer:
	var box := _make_pile_box("Discard spread", _discard_spread_subtitle())
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if model.discard.is_empty():
		var display := UiFactory.make_small_card_display("Empty")
		display.modulate = Color(1, 1, 1, 0.55)
		box.add_child(display)
		return box
	var row := HFlowContainer.new()
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("h_separation", 6)
	row.add_theme_constant_override("v_separation", 6)
	box.add_child(row)
	for i in range(model.discard.size()):
		var card: Dictionary = model.discard[i]
		var button := UiFactory.make_small_card_button(card, _draw_discard_at.bind(i))
		var can_take := model.can_take_discard_at(i)
		button.disabled = not can_take
		if i == model.discard.size() - 1:
			button.tooltip_text = "Take the top discard card."
		elif can_take:
			button.tooltip_text = "Take %s and the %d newer discard%s to its right; %s must be used immediately." % [
				CardTools.card_text(card),
				model.discard_pickup_count(i) - 1,
				"" if model.discard_pickup_count(i) == 2 else "s",
				CardTools.card_text(card),
			]
		else:
			button.tooltip_text = "You cannot take %s because it has no immediate meld or layoff." % CardTools.card_text(card)
		row.add_child(button)
	return box

func _discard_spread_subtitle() -> String:
	if model.discard.is_empty():
		return "Empty"
	return "Oldest left, top card right. Click a usable card."

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

func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.queue_free()

func _selection_hint() -> String:
	if model.has_pickup_requirement() and not model.selected.has(model.required_pickup_card):
		return "Use %s in your first meld or layoff before discarding." % CardTools.card_text(model.required_pickup_card)
	if model.selected.is_empty():
		return "Select cards to meld, lay off, or discard."
	if RummyTools.is_valid_meld(model.selected):
		return "Selected cards form a valid %s worth %d points." % [RummyTools.meld_kind(model.selected), RummyTools.meld_points(model.selected)]
	if model.selected.size() == 1 and _selected_can_layoff():
		return "Selected card can be laid off on an existing meld."
	if model.selected.size() == 1:
		return "Selected one card. Discard it, or select more cards to form a meld."
	return "Selected cards are not one valid meld yet."

func _phase_text() -> String:
	match model.phase:
		"draw":
			if not model.allow_discard_pile_pickup:
				return "1. Draw: stock or top discard"
			return "1. Draw: stock or a usable discard"
		"act":
			if model.has_pickup_requirement():
				return "2. Act: use %s, then discard" % CardTools.card_text(model.required_pickup_card)
			return "2. Act: meld, lay off, then discard"
		"bot":
			return "Computer turn"
		"done":
			return "Hand complete"
	return ""

func _facts_text() -> String:
	var requirement := ""
	if model.has_pickup_requirement():
		requirement = "\nMust use: %s" % CardTools.card_text(model.required_pickup_card)
	return "Players: you + 1 computer\nStock: %d  Discard: %s\nCards: you %d  computer %d%s" % [
		model.deck.size(),
		top_card_text(),
		model.player.size(),
		model.bot.size(),
		requirement
	]

func _score_text() -> String:
	return "%s\n\nThis hand\nYou: %d melded, %d in hand\nComputer: %d melded, %d in hand" % [
		model.score_text(),
		model.player_hand_points,
		RummyTools.hand_points(model.player),
		model.computer_hand_points,
		RummyTools.hand_points(model.bot)
	]

func _is_last_drawn_card(card: Dictionary) -> bool:
	return model.is_drawn_card(card)

func _style_new_drawn_card(button: Button) -> void:
	UiFactory.style_new_card_button(button)

func top_card_text() -> String:
	if model.discard.is_empty():
		return "none"
	var card: Dictionary = model.discard[-1]
	return CardTools.card_text(card)
