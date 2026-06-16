class_name UiFactory
extends RefCounted

const CardTools := preload("res://scripts/core/card_tools.gd")
const KENNEY_CARD_DIR := "res://assets/external/PNG/Cards (large)"
const BASE_CARD_CONTROL_SIZE := Vector2(172, 212)
const BASE_CARD_TEXTURE_SIZE := Vector2(164, 164)
const BASE_CARD_ICON_WIDTH := 164
const BASE_HAND_SCROLL_HEIGHT := 230
const SMALL_CARD_FACTOR := 0.58
const BASE_APP_SIDEBAR_WIDTH := 300
const BASE_CONTENT_SIDE_MARGINS := 48
const BASE_GAME_ROW_GAP := 16
const BASE_MAX_VISIBLE_HAND_CARDS := 13
const BASE_HAND_CARD_GAP := 6
const BASE_GUIDANCE_BODY_HEIGHT := 104
const BASE_COACH_SIDEBAR_WIDTH := 390
const BASE_COACH_ADVICE_HEIGHT := 138
const BASE_COACH_SCORE_HEIGHT := 112
const BASE_COACH_RULES_HEIGHT := 270
const BASE_TTT_CELL_SIZE := 140
const BASE_CHECKERS_CELL_SIZE := 78
const BASE_GAME_TILE_SIZE := Vector2(240, 86)
const BASE_GAME_TILE_ICON_SIZE := 46

static var card_scale := 1.0
static var play_area_width := 980.0

static func configure_for_viewport(viewport_size: Vector2) -> bool:
	var reserved_width: float = BASE_APP_SIDEBAR_WIDTH + BASE_CONTENT_SIDE_MARGINS + BASE_GAME_ROW_GAP + BASE_COACH_SIDEBAR_WIDTH
	var next_play_area_width: float = max(420.0, viewport_size.x - reserved_width)
	var content_height: float = max(360.0, viewport_size.y - 220.0)
	var layout_scale: float = min(next_play_area_width / 1120.0, content_height / 760.0) * 1.08
	var one_row_scale: float = (next_play_area_width - float((BASE_MAX_VISIBLE_HAND_CARDS - 1) * BASE_HAND_CARD_GAP)) / float(BASE_CARD_CONTROL_SIZE.x * BASE_MAX_VISIBLE_HAND_CARDS)
	var readable_hand_scale: float = max(0.54, one_row_scale * 1.18)
	var next_scale: float = clamp(min(layout_scale, readable_hand_scale), 0.48, 1.24)
	next_scale = round(next_scale * 20.0) / 20.0
	var layout_changed: bool = abs(next_scale - card_scale) >= 0.01 or abs(next_play_area_width - play_area_width) >= 1.0
	play_area_width = next_play_area_width
	if not layout_changed:
		return false
	card_scale = next_scale
	return true

static func card_control_size() -> Vector2:
	return _scaled_vec(BASE_CARD_CONTROL_SIZE)

static func card_texture_size() -> Vector2:
	return _scaled_vec(BASE_CARD_TEXTURE_SIZE)

static func card_icon_width() -> int:
	return int(round(BASE_CARD_ICON_WIDTH * card_scale))

static func small_card_control_size() -> Vector2:
	return _scaled_vec(BASE_CARD_CONTROL_SIZE * SMALL_CARD_FACTOR)

static func small_card_texture_size() -> Vector2:
	return _scaled_vec(BASE_CARD_TEXTURE_SIZE * SMALL_CARD_FACTOR)

static func small_card_icon_width() -> int:
	return int(round(BASE_CARD_ICON_WIDTH * SMALL_CARD_FACTOR * card_scale))

static func hand_card_gap() -> int:
	return int(round(BASE_HAND_CARD_GAP * clamp(card_scale, 0.72, 1.0)))

static func single_hand_scroll_height() -> int:
	return int(round(BASE_HAND_SCROLL_HEIGHT * card_scale))

static func hand_scroll_height(card_count: int = BASE_MAX_VISIBLE_HAND_CARDS) -> int:
	var gap: int = hand_card_gap()
	var card_size: Vector2 = card_control_size()
	var available_width: float = max(card_size.x, play_area_width - 24.0)
	var per_row: int = max(1, int(floor((available_width + gap) / float(card_size.x + gap))))
	var rows: int = int(ceil(float(card_count) / float(per_row)))
	return rows * int(card_size.y) + max(0, rows - 1) * gap + 24

static func small_hand_scroll_height() -> int:
	return int(round(BASE_HAND_SCROLL_HEIGHT * SMALL_CARD_FACTOR * card_scale + 24))

static func fit_card_control_size(card_count: int) -> Vector2:
	var count: int = max(1, card_count)
	var gap: int = hand_card_gap()
	var available_width: float = max(260.0, play_area_width - 72.0)
	var raw_width: float = floor((available_width - float((count - 1) * gap)) / float(count))
	var width: float = clamp(raw_width, 44.0, card_control_size().x)
	var height: float = round(width * BASE_CARD_CONTROL_SIZE.y / BASE_CARD_CONTROL_SIZE.x)
	return Vector2(round(width), height)

static func fit_card_texture_size(card_count: int) -> Vector2:
	var control_size := fit_card_control_size(card_count)
	var texture_width: float = max(36.0, control_size.x * BASE_CARD_TEXTURE_SIZE.x / BASE_CARD_CONTROL_SIZE.x)
	return Vector2(round(texture_width), round(texture_width))

static func title_font_size() -> int:
	return int(round(30 * clamp(card_scale, 0.9, 1.18)))

static func guidance_body_height() -> int:
	return int(round(BASE_GUIDANCE_BODY_HEIGHT * clamp(card_scale, 0.9, 1.2)))

static func guidance_font_size() -> int:
	return int(round(18 * clamp(card_scale, 0.92, 1.18)))

static func info_font_size() -> int:
	return int(round(17 * clamp(card_scale, 0.92, 1.14)))

static func coach_sidebar_width() -> int:
	return int(round(BASE_COACH_SIDEBAR_WIDTH * clamp(card_scale, 0.92, 1.12)))

static func coach_advice_height() -> int:
	return int(round(BASE_COACH_ADVICE_HEIGHT * clamp(card_scale, 0.9, 1.18)))

static func coach_score_height() -> int:
	return int(round(BASE_COACH_SCORE_HEIGHT * clamp(card_scale, 0.9, 1.16)))

static func coach_rules_height() -> int:
	return int(round(BASE_COACH_RULES_HEIGHT * clamp(card_scale, 0.9, 1.16)))

static func ttt_cell_size() -> int:
	return int(round(BASE_TTT_CELL_SIZE * clamp(card_scale, 0.72, 1.2)))

static func checkers_cell_size() -> int:
	return int(round(BASE_CHECKERS_CELL_SIZE * clamp(card_scale, 0.72, 1.18)))

static func game_tile_size() -> Vector2:
	return _scaled_vec(BASE_GAME_TILE_SIZE)

static func game_tile_icon_size() -> int:
	return int(round(BASE_GAME_TILE_ICON_SIZE * clamp(card_scale, 0.75, 1.45)))

static func sidebar_icon_size() -> int:
	return int(round(22 * clamp(card_scale, 0.9, 1.25)))

static func _scaled_vec(value: Vector2) -> Vector2:
	return Vector2(round(value.x * card_scale), round(value.y * card_scale))

static func panel_style(color: Color, radius: int = 8, border_color: Color = Color("#d2cab8"), border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

static func make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", panel_style(Color("#fffaf0")))
	return panel

static func style_guidance_panel(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", panel_style(Color("#fffdf7"), 8, Color("#8b7337"), 2))

static func style_guidance_heading(label: Label) -> void:
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color("#5d4a13"))

static func style_guidance_body(label: Label) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(0, guidance_body_height())
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", guidance_font_size())
	label.add_theme_color_override("font_color", Color("#17212b"))
	label.add_theme_constant_override("line_spacing", 4)

static func make_guidance_panel() -> Dictionary:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	style_guidance_panel(panel)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var heading := Label.new()
	heading.text = "Rules / Coach"
	style_guidance_heading(heading)
	box.add_child(heading)

	var body := Label.new()
	style_guidance_body(body)
	box.add_child(body)

	return {"panel": panel, "heading": heading, "body": body}

static func style_coach_sidebar_panel(panel: PanelContainer) -> void:
	panel.custom_minimum_size = Vector2(coach_sidebar_width(), 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", panel_style(Color("#ede7dc"), 8, Color("#b9aa91"), 1))

static func make_coach_sidebar() -> Dictionary:
	var panel := PanelContainer.new()
	style_coach_sidebar_panel(panel)

	var outer := VBoxContainer.new()
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)

	var heading := Label.new()
	heading.text = "Learning Coach"
	heading.add_theme_font_size_override("font_size", int(round(21 * clamp(card_scale, 0.92, 1.14))))
	heading.add_theme_color_override("font_color", Color("#17212b"))
	outer.add_child(heading)

	var advice_section := _make_coach_section("Advice / Next Move", Color("#fffdf7"), Color("#8b7337"), coach_advice_height(), guidance_font_size())
	outer.add_child(advice_section["panel"])

	var score_section := _make_coach_section("Score", Color("#eef6f5"), Color("#6a9290"), coach_score_height(), info_font_size())
	outer.add_child(score_section["panel"])

	var rules_section := _make_coach_section("Rules / Strategy", Color("#f7f4ee"), Color("#b9aa91"), coach_rules_height(), info_font_size())
	rules_section["panel"].size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(rules_section["panel"])

	return {
		"panel": panel,
		"heading": heading,
		"advice": advice_section["body"],
		"score": score_section["body"],
		"rules": rules_section["body"],
	}

static func _make_coach_section(title: String, color: Color, border_color: Color, min_height: int, body_font_size: int) -> Dictionary:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", panel_style(color, 8, border_color, 1))

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 15)
	heading.add_theme_color_override("font_color", Color("#40515e"))
	box.add_child(heading)

	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(0, min_height)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("font_size", body_font_size)
	body.add_theme_color_override("font_color", Color("#17212b"))
	body.add_theme_constant_override("line_spacing", 4)
	box.add_child(body)

	return {"panel": panel, "heading": heading, "body": body}

static func make_section() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	return box

static func make_button_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	return row

static func make_hand_scroll() -> Dictionary:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.custom_minimum_size = Vector2(0, hand_scroll_height())
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HFlowContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("h_separation", hand_card_gap())
	row.add_theme_constant_override("v_separation", hand_card_gap())
	scroll.add_child(row)
	return {"scroll": scroll, "row": row}

static func style_menu_button(button: Button, playable: bool) -> void:
	var normal_color := Color("#40515e") if playable else Color("#36424b")
	var hover_color := Color("#4f6575") if playable else Color("#414d56")
	button.add_theme_color_override("font_color", Color("#f4f7f8") if playable else Color("#aeb8bf"))
	button.add_theme_stylebox_override("normal", panel_style(normal_color, 6, Color.TRANSPARENT, 0))
	button.add_theme_stylebox_override("hover", panel_style(hover_color, 6, Color.TRANSPARENT, 0))
	button.add_theme_stylebox_override("pressed", panel_style(Color("#627a8c"), 6, Color.TRANSPARENT, 0))

static func apply_button_icon(button: Button, icon_path: String, size: int = 24) -> void:
	var texture := load_icon_texture(icon_path, size)
	if texture == null:
		return
	button.icon = texture
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", size)
	button.add_theme_constant_override("h_separation", 8)

static func load_icon_texture(icon_path: String, size: int) -> Texture2D:
	if icon_path == "":
		return null
	var svg_text := FileAccess.get_file_as_string(icon_path)
	if svg_text == "":
		return null
	var image := Image.new()
	var err := image.load_svg_from_string(svg_text, float(size) / 96.0)
	if err != OK:
		return null
	return ImageTexture.create_from_image(image)

static func make_game_tile(game: Dictionary, pressed: Callable) -> Button:
	var button := Button.new()
	button.text = game["name"]
	button.custom_minimum_size = game_tile_size()
	style_menu_button(button, game["status"] == "playable")
	apply_button_icon(button, game.get("icon", ""), game_tile_icon_size())
	button.pressed.connect(pressed)
	return button

static func make_card_button(card: Dictionary, pressed: Callable, selected: bool = false) -> Button:
	return _make_card_button_sized(card, pressed, selected, card_control_size(), card_icon_width())

static func make_small_card_button(card: Dictionary, pressed: Callable, selected: bool = false) -> Button:
	return _make_card_button_sized(card, pressed, selected, small_card_control_size(), small_card_icon_width())

static func make_fit_card_button(card: Dictionary, pressed: Callable, selected: bool = false, fit_count: int = 11) -> Button:
	var control_size := fit_card_control_size(fit_count)
	return _make_card_button_sized(card, pressed, selected, control_size, int(fit_card_texture_size(fit_count).x))

static func _make_card_button_sized(card: Dictionary, pressed: Callable, selected: bool, control_size: Vector2, icon_width: int) -> Button:
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = control_size
	button.icon = make_card_texture(card, selected)
	button.expand_icon = true
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.add_theme_constant_override("icon_max_width", icon_width)
	var color := Color("#fffdf7") if not selected else Color("#f7df8f")
	button.add_theme_stylebox_override("normal", panel_style(color, 7, Color("#c8bfae"), 1))
	button.add_theme_stylebox_override("hover", panel_style(Color("#fff5d8"), 7, Color("#a9935d"), 1))
	button.add_theme_stylebox_override("pressed", panel_style(Color("#efd37a"), 7, Color("#8b7337"), 1))
	button.add_theme_stylebox_override("disabled", panel_style(Color("#e4dfd4"), 7, Color("#c8bfae"), 1))
	button.add_theme_color_override("font_disabled_color", Color("#7f8588"))
	button.pressed.connect(pressed)
	return button

static func style_suggested_card_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", panel_style(Color("#fff3c2"), 7, Color("#b68b19"), 2))
	button.add_theme_stylebox_override("hover", panel_style(Color("#ffeaa3"), 7, Color("#8b6912"), 2))
	button.add_theme_stylebox_override("pressed", panel_style(Color("#efd37a"), 7, Color("#73560c"), 2))

static func style_new_card_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", panel_style(Color("#e2f5ff"), 7, Color("#21759b"), 2))
	button.add_theme_stylebox_override("hover", panel_style(Color("#d1efff"), 7, Color("#145d7d"), 2))
	button.add_theme_stylebox_override("pressed", panel_style(Color("#bde4f6"), 7, Color("#0d4c68"), 2))

static func style_checkbox(toggle: CheckBox) -> void:
	toggle.add_theme_color_override("font_color", Color("#25313a"))
	toggle.add_theme_color_override("font_hover_color", Color("#17212b"))
	toggle.add_theme_color_override("font_pressed_color", Color("#17212b"))
	toggle.add_theme_color_override("font_disabled_color", Color("#6f7d85"))

static func coach_message(primary: String, coach_tip: String = "", context: String = "") -> String:
	var clean_primary := primary
	if coach_tip != "":
		var legacy_index := clean_primary.find("Coach tip:")
		if legacy_index >= 0:
			clean_primary = clean_primary.substr(0, legacy_index).strip_edges()
	var lines := []
	if clean_primary != "":
		lines.append(clean_primary)
	if coach_tip != "":
		if coach_tip.find("\n") >= 0:
			lines.append(coach_tip)
		else:
			lines.append("Coach: %s" % coach_tip)
	if context != "":
		lines.append(context)
	return "\n".join(lines)

static func make_card_display(text: String, red: bool = false, hidden: bool = false, card: Dictionary = {}) -> PanelContainer:
	return _make_card_display_sized(text, red, hidden, card, card_control_size(), card_texture_size())

static func make_small_card_display(text: String, red: bool = false, hidden: bool = false, card: Dictionary = {}) -> PanelContainer:
	return _make_card_display_sized(text, red, hidden, card, small_card_control_size(), small_card_texture_size())

static func _make_card_display_sized(text: String, red: bool, hidden: bool, card: Dictionary, control_size: Vector2, texture_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = control_size
	var bg_color := Color("#fffdf7")
	var border_color := Color("#c8bfae")
	if hidden:
		bg_color = Color("#40515e")
		border_color = Color("#26343f")
	panel.add_theme_stylebox_override("panel", panel_style(bg_color, 7, border_color, 1))
	var texture_rect := TextureRect.new()
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.custom_minimum_size = texture_size
	texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if card.size() > 0:
		texture_rect.texture = make_card_texture(card)
	elif hidden:
		texture_rect.texture = make_card_back_texture()
	else:
		texture_rect.texture = make_text_card_texture(text, red)
	panel.add_child(texture_rect)
	return panel

static func make_card_texture(card: Dictionary, selected: bool = false) -> Texture2D:
	var rank := str(card.rank)
	var suit := str(card.suit)
	var kenney := _load_png_texture(_kenney_card_path(rank, suit))
	if kenney != null:
		return kenney
	var path := "res://assets/generated/cards/%s_%s%s.png" % [rank, suit, "_selected" if selected else ""]
	var generated := _load_png_texture(path)
	if generated != null:
		return generated
	var red := CardTools.is_red_suit(suit)
	var color := "#a7202a" if red else "#17212b"
	var bg := "#f7df8f" if selected else "#fffdf7"
	var small_suit := _suit_svg(suit, 12, 36, 12, color)
	var center_suit := _suit_svg(suit, 32, 52, 32, color)
	var svg := """
<svg xmlns="http://www.w3.org/2000/svg" width="96" height="128" viewBox="0 0 96 128">
  <rect x="2" y="2" width="92" height="124" rx="10" fill="%s" stroke="#c8bfae" stroke-width="3"/>
  <text x="12" y="28" font-family="Arial, sans-serif" font-size="22" font-weight="700" fill="%s">%s</text>
  %s
  %s
  <text x="84" y="108" font-family="Arial, sans-serif" font-size="22" font-weight="700" text-anchor="end" fill="%s">%s</text>
</svg>
""" % [bg, color, rank, small_suit, center_suit, color, rank]
	return _texture_from_svg(svg, 1.0)

static func make_card_back_texture() -> Texture2D:
	var kenney := _load_png_texture("%s/card_back.png" % KENNEY_CARD_DIR)
	if kenney != null:
		return kenney
	var generated := _load_png_texture("res://assets/generated/cards/back.png")
	if generated != null:
		return generated
	var svg := """
<svg xmlns="http://www.w3.org/2000/svg" width="96" height="128" viewBox="0 0 96 128">
  <rect x="2" y="2" width="92" height="124" rx="10" fill="#40515e" stroke="#26343f" stroke-width="3"/>
  <rect x="14" y="14" width="68" height="100" rx="7" fill="none" stroke="#f4f7f8" stroke-width="4" stroke-dasharray="8 6"/>
  <path d="M31 64h34M48 47v34" stroke="#f4f7f8" stroke-width="6" stroke-linecap="round"/>
</svg>
"""
	return _texture_from_svg(svg, 1.0)

static func _kenney_card_path(rank: String, suit: String) -> String:
	return "%s/card_%s_%s.png" % [KENNEY_CARD_DIR, _kenney_suit_name(suit), _kenney_rank_name(rank)]

static func _kenney_suit_name(suit: String) -> String:
	match suit:
		"S":
			return "spades"
		"H":
			return "hearts"
		"D":
			return "diamonds"
		"C":
			return "clubs"
	return suit.to_lower()

static func _kenney_rank_name(rank: String) -> String:
	if rank in ["A", "J", "Q", "K"]:
		return rank
	if rank.length() == 1:
		return "0%s" % rank
	return rank

static func make_text_card_texture(text: String, red: bool = false) -> Texture2D:
	var color := "#a7202a" if red else "#17212b"
	var svg := """
<svg xmlns="http://www.w3.org/2000/svg" width="96" height="128" viewBox="0 0 96 128">
  <rect x="2" y="2" width="92" height="124" rx="10" fill="#fffdf7" stroke="#c8bfae" stroke-width="3"/>
  <text x="48" y="72" font-family="Arial, sans-serif" font-size="24" font-weight="700" text-anchor="middle" fill="%s">%s</text>
</svg>
""" % [color, text]
	return _texture_from_svg(svg, 1.0)

static func make_action_button(text: String, pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(124, 42)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color("#ffffff"))
	button.add_theme_stylebox_override("normal", panel_style(Color("#2f6f73"), 6, Color.TRANSPARENT, 0))
	button.add_theme_stylebox_override("hover", panel_style(Color("#378388"), 6, Color.TRANSPARENT, 0))
	button.add_theme_stylebox_override("pressed", panel_style(Color("#285f63"), 6, Color.TRANSPARENT, 0))
	button.add_theme_stylebox_override("disabled", panel_style(Color("#8fa5a7"), 6, Color.TRANSPARENT, 0))
	button.pressed.connect(pressed)
	return button

static func make_secondary_button(text: String, pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(124, 42)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color("#26343f"))
	button.add_theme_stylebox_override("normal", panel_style(Color("#efe7d6"), 6, Color("#c8bfae"), 1))
	button.add_theme_stylebox_override("hover", panel_style(Color("#f7efd9"), 6, Color("#a9935d"), 1))
	button.add_theme_stylebox_override("pressed", panel_style(Color("#dfd1b8"), 6, Color("#8b7337"), 1))
	button.pressed.connect(pressed)
	return button

static func make_ttt_cell(pressed: Callable) -> Button:
	var button := Button.new()
	var size := ttt_cell_size()
	button.custom_minimum_size = Vector2(size, size)
	style_ttt_cell(button)
	button.pressed.connect(pressed)
	return button

static func style_ttt_cell(button: Button) -> void:
	button.add_theme_font_size_override("font_size", int(round(54 * clamp(card_scale, 0.72, 1.18))))
	button.add_theme_color_override("font_color", Color("#17212b"))
	button.add_theme_stylebox_override("normal", panel_style(Color("#fffaf0"), 6, Color("#b8aa92"), 1))
	button.add_theme_stylebox_override("hover", panel_style(Color("#fff2cf"), 6, Color("#a9935d"), 1))
	button.add_theme_stylebox_override("pressed", panel_style(Color("#eed27a"), 6, Color("#8b7337"), 1))
	button.add_theme_stylebox_override("disabled", panel_style(Color("#ece3d2"), 6, Color("#b8aa92"), 1))

static func make_checkers_cell(pressed: Callable) -> Button:
	var button := Button.new()
	var size := checkers_cell_size()
	button.custom_minimum_size = Vector2(size, size)
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(pressed)
	return button

static func style_checkers_cell(button: Button, dark: bool, selected: bool, legal_target: bool, piece: String) -> void:
	var color := Color("#b78352") if dark else Color("#efd8b5")
	if legal_target:
		color = Color("#d6c473")
	if selected:
		color = Color("#e5bf48")
	var style := panel_style(color, 2, Color("#5c4531"), 1)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.text = ""
	button.icon = make_checker_piece_texture(piece)
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", int(round(checkers_cell_size() * 0.8)))

static func make_checker_piece_texture(piece: String) -> Texture2D:
	if piece == "":
		return null
	var generated := _load_png_texture("res://assets/generated/checkers/%s.png" % _checker_piece_asset_name(piece))
	if generated != null:
		return generated
	var red := piece == "r" or piece == "R"
	var crowned := piece == "R" or piece == "B"
	var fill := "#8c2028" if red else "#17212b"
	var stroke := "#f1c45a" if crowned else "#ffffff"
	var crown := "<path d='M28 49l9-12 11 12 11-12 9 12v8H28z' fill='#f1c45a'/>" if crowned else ""
	var svg := """
<svg xmlns="http://www.w3.org/2000/svg" width="80" height="80" viewBox="0 0 80 80">
  <circle cx="40" cy="40" r="27" fill="%s" stroke="%s" stroke-width="4"/>
  <ellipse cx="40" cy="32" rx="20" ry="8" fill="rgba(255,255,255,0.16)"/>
  %s
</svg>
""" % [fill, stroke, crown]
	return _texture_from_svg(svg, 0.85)

static func _checker_piece_asset_name(piece: String) -> String:
	match piece:
		"r":
			return "red_man"
		"R":
			return "red_king"
		"b":
			return "black_man"
		"B":
			return "black_king"
	return "unknown"

static func _load_png_texture(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		return null
	return ImageTexture.create_from_image(image)

static func _texture_from_svg(svg: String, scale: float) -> Texture2D:
	var image := Image.new()
	var err := image.load_svg_from_string(svg, scale)
	if err != OK:
		return null
	return ImageTexture.create_from_image(image)

static func _suit_svg(suit: String, x: int, y: int, size: int, color: String) -> String:
	match suit:
		"H":
			return _heart_svg(x, y, size, color)
		"D":
			return _diamond_svg(x, y, size, color)
		"C":
			return _club_svg(x, y, size, color)
		"S":
			return _spade_svg(x, y, size, color)
	return ""

static func _heart_svg(x: int, y: int, size: int, color: String) -> String:
	return "<path d='M %d %d C %d %d %d %d %d %d C %d %d %d %d %d %d C %d %d %d %d %d %d Z' fill='%s'/>" % [
		x + size / 2, y + size,
		x - size / 8, y + size / 2, x, y, x + size / 3, y + size / 6,
		x + size / 2, y + size / 4, x + size * 2 / 3, y + size / 6, x + size, y,
		x + size * 9 / 8, y + size / 2, x + size / 2, y + size, x + size / 2, y + size,
		color
	]

static func _diamond_svg(x: int, y: int, size: int, color: String) -> String:
	return "<path d='M %d %d L %d %d L %d %d L %d %d Z' fill='%s'/>" % [
		x + size / 2, y,
		x + size, y + size / 2,
		x + size / 2, y + size,
		x, y + size / 2,
		color
	]

static func _club_svg(x: int, y: int, size: int, color: String) -> String:
	return "<g fill='%s'><circle cx='%d' cy='%d' r='%d'/><circle cx='%d' cy='%d' r='%d'/><circle cx='%d' cy='%d' r='%d'/><path d='M %d %d L %d %d L %d %d Z'/></g>" % [
		color,
		x + size / 2, y + size / 4, size / 4,
		x + size / 4, y + size / 2, size / 4,
		x + size * 3 / 4, y + size / 2, size / 4,
		x + size / 2, y + size / 2,
		x + size / 4, y + size,
		x + size * 3 / 4, y + size
	]

static func _spade_svg(x: int, y: int, size: int, color: String) -> String:
	return "<g fill='%s'><path d='M %d %d C %d %d %d %d %d %d C %d %d %d %d %d %d C %d %d %d %d %d %d Z'/><path d='M %d %d L %d %d L %d %d Z'/></g>" % [
		color,
		x + size / 2, y,
		x - size / 8, y + size / 2, x, y + size, x + size / 3, y + size * 3 / 4,
		x + size / 2, y + size * 2 / 3, x + size * 2 / 3, y + size * 3 / 4, x + size, y + size,
		x + size * 9 / 8, y + size / 2, x + size / 2, y, x + size / 2, y,
		x + size / 2, y + size / 2,
		x + size / 4, y + size,
		x + size * 3 / 4, y + size
	]

static func _suit_symbol(suit: String) -> String:
	match suit:
		"S":
			return "♠"
		"H":
			return "♥"
		"D":
			return "♦"
		"C":
			return "♣"
	return suit

static func make_info_label() -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", info_font_size())
	label.add_theme_color_override("font_color", Color("#25313a"))
	label.add_theme_constant_override("line_spacing", 3)
	return label

static func make_fact_label() -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("#40515e"))
	label.add_theme_constant_override("line_spacing", 2)
	return label
