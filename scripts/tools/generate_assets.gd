extends SceneTree

const CARD_SUITS := ["S", "H", "D", "C"]
const CARD_RANKS := ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
const CARD_DIR := "res://assets/generated/cards"
const CHECKERS_DIR := "res://assets/generated/checkers"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CARD_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CHECKERS_DIR))
	for suit in CARD_SUITS:
		for rank in CARD_RANKS:
			_save_svg_png(_card_svg(rank, suit, false), "%s/%s_%s.png" % [CARD_DIR, rank, suit])
			_save_svg_png(_card_svg(rank, suit, true), "%s/%s_%s_selected.png" % [CARD_DIR, rank, suit])
	_save_svg_png(_card_back_svg(), "%s/back.png" % CARD_DIR)
	for piece in ["r", "R", "b", "B"]:
		_save_svg_png(_checker_svg(piece), "%s/%s.png" % [CHECKERS_DIR, _checker_piece_asset_name(piece)])
	quit()

func _save_svg_png(svg: String, path: String) -> void:
	var image := Image.new()
	var err := image.load_svg_from_string(svg, 1.0)
	if err != OK:
		push_error("Could not render SVG for %s" % path)
		return
	image.save_png(path)

func _card_svg(rank: String, suit: String, selected: bool) -> String:
	var red := suit == "H" or suit == "D"
	var color := "#a7202a" if red else "#17212b"
	var bg := "#f7df8f" if selected else "#fffdf7"
	var small_suit := _suit_svg(suit, 12, 36, 12, color)
	var center_suit := _suit_svg(suit, 32, 52, 32, color)
	return """
<svg xmlns="http://www.w3.org/2000/svg" width="96" height="128" viewBox="0 0 96 128">
  <rect x="2" y="2" width="92" height="124" rx="10" fill="%s" stroke="#c8bfae" stroke-width="3"/>
  <text x="12" y="28" font-family="Arial, sans-serif" font-size="22" font-weight="700" fill="%s">%s</text>
  %s
  %s
  <text x="84" y="108" font-family="Arial, sans-serif" font-size="22" font-weight="700" text-anchor="end" fill="%s">%s</text>
</svg>
""" % [bg, color, rank, small_suit, center_suit, color, rank]

func _card_back_svg() -> String:
	return """
<svg xmlns="http://www.w3.org/2000/svg" width="96" height="128" viewBox="0 0 96 128">
  <rect x="2" y="2" width="92" height="124" rx="10" fill="#40515e" stroke="#26343f" stroke-width="3"/>
  <rect x="14" y="14" width="68" height="100" rx="7" fill="none" stroke="#f4f7f8" stroke-width="4" stroke-dasharray="8 6"/>
  <path d="M31 64h34M48 47v34" stroke="#f4f7f8" stroke-width="6" stroke-linecap="round"/>
</svg>
"""

func _checker_svg(piece: String) -> String:
	var red := piece == "r" or piece == "R"
	var crowned := piece == "R" or piece == "B"
	var fill := "#8c2028" if red else "#17212b"
	var stroke := "#f1c45a" if crowned else "#ffffff"
	var crown := "<path d='M28 49l9-12 11 12 11-12 9 12v8H28z' fill='#f1c45a'/>" if crowned else ""
	return """
<svg xmlns="http://www.w3.org/2000/svg" width="80" height="80" viewBox="0 0 80 80">
  <circle cx="40" cy="40" r="27" fill="%s" stroke="%s" stroke-width="4"/>
  <ellipse cx="40" cy="32" rx="20" ry="8" fill="#ffffff" opacity="0.16"/>
  %s
</svg>
""" % [fill, stroke, crown]

func _checker_piece_asset_name(piece: String) -> String:
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

func _suit_svg(suit: String, x: int, y: int, size: int, color: String) -> String:
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

func _heart_svg(x: int, y: int, size: int, color: String) -> String:
	return "<path d='M %d %d C %d %d %d %d %d %d C %d %d %d %d %d %d C %d %d %d %d %d %d Z' fill='%s'/>" % [
		x + size / 2, y + size,
		x - size / 8, y + size / 2, x, y, x + size / 3, y + size / 6,
		x + size / 2, y + size / 4, x + size * 2 / 3, y + size / 6, x + size, y,
		x + size * 9 / 8, y + size / 2, x + size / 2, y + size, x + size / 2, y + size,
		color
	]

func _diamond_svg(x: int, y: int, size: int, color: String) -> String:
	return "<path d='M %d %d L %d %d L %d %d L %d %d Z' fill='%s'/>" % [
		x + size / 2, y, x + size, y + size / 2, x + size / 2, y + size, x, y + size / 2, color
	]

func _club_svg(x: int, y: int, size: int, color: String) -> String:
	return "<g fill='%s'><circle cx='%d' cy='%d' r='%d'/><circle cx='%d' cy='%d' r='%d'/><circle cx='%d' cy='%d' r='%d'/><path d='M %d %d L %d %d L %d %d Z'/></g>" % [
		color, x + size / 2, y + size / 4, size / 4, x + size / 4, y + size / 2, size / 4,
		x + size * 3 / 4, y + size / 2, size / 4, x + size / 2, y + size / 2, x + size / 4, y + size, x + size * 3 / 4, y + size
	]

func _spade_svg(x: int, y: int, size: int, color: String) -> String:
	return "<g fill='%s'><path d='M %d %d C %d %d %d %d %d %d C %d %d %d %d %d %d C %d %d %d %d %d %d Z'/><path d='M %d %d L %d %d L %d %d Z'/></g>" % [
		color, x + size / 2, y, x - size / 8, y + size / 2, x, y + size, x + size / 3, y + size * 3 / 4,
		x + size / 2, y + size * 2 / 3, x + size * 2 / 3, y + size * 3 / 4, x + size, y + size,
		x + size * 9 / 8, y + size / 2, x + size / 2, y, x + size / 2, y, x + size / 2, y + size / 2,
		x + size / 4, y + size, x + size * 3 / 4, y + size
	]
