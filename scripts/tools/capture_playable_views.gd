extends SceneTree

const GameCatalog := preload("res://scripts/app/game_catalog.gd")

const OUTPUT_DIR := "res://tmp/ui_screenshots"
const VIEWPORT_SIZE := Vector2i(1600, 1000)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	DisplayServer.window_set_size(VIEWPORT_SIZE)
	root.size = VIEWPORT_SIZE
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	_clear_old_screenshots()
	var scene: Control = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await _settle_frames(4)
	for game in GameCatalog.all():
		if game["status"] != "playable":
			continue
		var game_id := str(game["id"])
		scene.call("_on_game_selected", game_id)
		await _settle_frames(6)
		var image := root.get_texture().get_image()
		var path := "%s/%02d_%s.png" % [OUTPUT_DIR, _playable_index(game_id), game_id]
		var error := image.save_png(path)
		if error != OK:
			push_error("Could not save screenshot %s: %s" % [path, error])
			quit(1)
	print("Playable screenshots saved to %s" % ProjectSettings.globalize_path(OUTPUT_DIR))
	quit()

func _settle_frames(count: int) -> void:
	for i in range(count):
		await process_frame

func _clear_old_screenshots() -> void:
	var output_path := ProjectSettings.globalize_path(OUTPUT_DIR)
	var dir := DirAccess.open(output_path)
	if dir == null:
		return
	for file_name in dir.get_files():
		if file_name.ends_with(".png"):
			dir.remove(file_name)

func _playable_index(game_id: String) -> int:
	var index := 0
	for game in GameCatalog.all():
		if game["status"] == "playable":
			index += 1
		if game["id"] == game_id:
			return index
	return index
