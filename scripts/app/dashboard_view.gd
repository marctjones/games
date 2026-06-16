class_name DashboardView
extends RefCounted

const GameCatalog := preload("res://scripts/app/game_catalog.gd")
const UiFactory := preload("res://scripts/ui/ui_factory.gd")

static func build(parent: VBoxContainer, game_selected: Callable) -> void:
	var playable_panel := UiFactory.make_panel()
	parent.add_child(playable_panel)

	var playable := VBoxContainer.new()
	playable.add_theme_constant_override("separation", 8)
	playable_panel.add_child(playable)

	var playable_label := Label.new()
	playable_label.text = "Playable multiplayer games"
	playable_label.add_theme_font_size_override("font_size", 18)
	playable.add_child(playable_label)

	var explainer := Label.new()
	explainer.text = "These are traditionally multiplayer tabletop games, configured for solo practice against computer opponents."
	explainer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explainer.add_theme_color_override("font_color", Color("#40515e"))
	playable.add_child(explainer)

	var grid := GridContainer.new()
	var viewport_width: float = parent.get_viewport_rect().size.x
	var content_width: float = max(360.0, viewport_width - 370.0)
	var tile_width: float = UiFactory.game_tile_size().x + 12.0
	grid.columns = int(clamp(int(floor(content_width / tile_width)), 1, 5))
	grid.add_theme_constant_override("h_separation", int(round(10 * UiFactory.card_scale)))
	grid.add_theme_constant_override("v_separation", int(round(10 * UiFactory.card_scale)))
	playable.add_child(grid)

	for game in GameCatalog.all():
		if game["status"] != "playable":
			continue
		var button := UiFactory.make_game_tile(game, game_selected.bind(game["id"]))
		grid.add_child(button)
