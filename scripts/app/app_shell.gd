class_name AppShell
extends RefCounted

const GameCatalog := preload("res://scripts/app/game_catalog.gd")
const UiFactory := preload("res://scripts/ui/ui_factory.gd")

static func build(host: Control, game_selected: Callable) -> Dictionary:
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#222831")
	host.add_theme_stylebox_override("panel", background)

	var root := HBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	host.add_child(root)

	var sidebar_panel := PanelContainer.new()
	sidebar_panel.custom_minimum_size = Vector2(300, 0)
	sidebar_panel.add_theme_stylebox_override("panel", UiFactory.panel_style(Color("#2f3b45"), 0, Color.TRANSPARENT, 0))
	root.add_child(sidebar_panel)

	var sidebar := VBoxContainer.new()
	sidebar.add_theme_constant_override("separation", 8)
	sidebar.add_theme_constant_override("margin_left", 14)
	sidebar.add_theme_constant_override("margin_right", 14)
	sidebar.add_theme_constant_override("margin_top", 14)
	sidebar.add_theme_constant_override("margin_bottom", 14)
	sidebar_panel.add_child(sidebar)

	var heading := Label.new()
	heading.text = "Classic Games Coach"
	heading.add_theme_font_size_override("font_size", 22)
	heading.add_theme_color_override("font_color", Color("#f2f4f6"))
	sidebar.add_child(heading)

	var subheading := Label.new()
	subheading.text = "Multiplayer games vs computer opponents"
	subheading.add_theme_color_override("font_color", Color("#c7d0d8"))
	subheading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sidebar.add_child(subheading)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_child(scroll)

	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 3)
	scroll.add_child(menu)

	var menu_buttons := []
	for game in GameCatalog.all():
		var button := Button.new()
		var suffix := "" if game["status"] == "playable" else " (queued)"
		button.text = "%s%s" % [game["name"], suffix]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, int(round(34 * clamp(UiFactory.card_scale, 0.9, 1.25))))
		UiFactory.style_menu_button(button, game["status"] == "playable")
		UiFactory.apply_button_icon(button, game.get("icon", ""), UiFactory.sidebar_icon_size())
		button.set_meta("icon_path", game.get("icon", ""))
		button.pressed.connect(game_selected.bind(game["id"]))
		menu.add_child(button)
		menu_buttons.append(button)

	var game_scroll := ScrollContainer.new()
	game_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(game_scroll)

	var content_panel := PanelContainer.new()
	content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_panel.add_theme_stylebox_override("panel", UiFactory.panel_style(Color("#f4f1e8"), 0, Color.TRANSPARENT, 0))
	game_scroll.add_child(content_panel)

	var game_area := VBoxContainer.new()
	game_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	game_area.add_theme_constant_override("separation", 14)
	game_area.add_theme_constant_override("margin_left", 24)
	game_area.add_theme_constant_override("margin_right", 24)
	game_area.add_theme_constant_override("margin_top", 22)
	game_area.add_theme_constant_override("margin_bottom", 22)
	content_panel.add_child(game_area)

	return {
		"sidebar": sidebar,
		"game_area": game_area,
		"content_panel": content_panel,
		"game_scroll": game_scroll,
		"menu_buttons": menu_buttons,
	}
