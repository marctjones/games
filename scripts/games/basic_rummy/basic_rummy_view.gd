class_name BasicRummyView
extends "res://scripts/games/rummy_500/rummy_500_view.gd"

const BasicRummyModel := preload("res://scripts/games/basic_rummy/basic_rummy_model.gd")

func setup(p_status_label: Label, p_score_label: Label = null, p_rules_label: Label = null) -> void:
	status_label = p_status_label
	score_label = p_score_label
	rules_label = p_rules_label
	model = BasicRummyModel.new()
	model.new_hand()
	status_label.text = UiFactory.coach_message(model.last_message, model.guidance_text())
	if rules_label != null:
		rules_label.text = "Basic Rummy: draw one card, optionally meld sets/runs or lay off cards, then discard one card. This trainer scores the winner by the opponent's remaining hand points. Aces are low in runs."
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
