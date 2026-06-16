class_name PinochleView
extends "res://scripts/games/trick_taking/trick_taking_view.gd"

const PinochleModel := preload("res://scripts/games/pinochle/pinochle_model.gd")

func setup(p_status_label: Label, p_score_label: Label = null, p_rules_label: Label = null) -> void:
	status_label = p_status_label
	score_label = p_score_label
	rules_label = p_rules_label
	model = PinochleModel.new()
	model.new_round("pinochle")
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
	model.new_round("pinochle")
	status_label.text = UiFactory.coach_message(model.status_text(), model.guidance_text())
	model.advance_bots()
	_update()
