extends SceneTree

const UiFactory := preload("res://scripts/ui/ui_factory.gd")

func _initialize() -> void:
	var samples := [
		{"rank": "A", "suit": "S"},
		{"rank": "2", "suit": "H"},
		{"rank": "10", "suit": "D"},
		{"rank": "K", "suit": "C"},
	]
	for card in samples:
		var texture := UiFactory.make_card_texture(card)
		if texture == null:
			push_error("Failed to load card texture: %s%s" % [card.rank, card.suit])
			quit(1)
			return
		if texture.get_width() != 64 or texture.get_height() != 64:
			push_error("Card texture is not the Kenney 64x64 sprite: %s%s" % [card.rank, card.suit])
			quit(1)
			return
	var back_texture := UiFactory.make_card_back_texture()
	if back_texture == null:
		push_error("Failed to load card back texture")
		quit(1)
		return
	if back_texture.get_width() != 64 or back_texture.get_height() != 64:
		push_error("Card back is not the Kenney 64x64 sprite")
		quit(1)
		return
	for piece in ["r", "R", "b", "B"]:
		var checker_texture := UiFactory.make_checker_piece_texture(piece)
		if checker_texture == null:
			push_error("Failed to load checker texture: %s" % piece)
			quit(1)
			return
	var red_image := Image.new()
	var black_image := Image.new()
	if red_image.load("res://assets/generated/checkers/red_man.png") != OK:
		push_error("Failed to load red checker image")
		quit(1)
		return
	if black_image.load("res://assets/generated/checkers/black_man.png") != OK:
		push_error("Failed to load black checker image")
		quit(1)
		return
	var red_center := red_image.get_pixel(40, 40)
	var black_center := black_image.get_pixel(40, 40)
	if red_center.r <= black_center.r + 0.15:
		push_error("Checker red/black images are not visually distinct")
		quit(1)
		return
	print("Card and checker asset verification passed.")
	quit()
