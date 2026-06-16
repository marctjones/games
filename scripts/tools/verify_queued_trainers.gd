extends SceneTree

const GameCatalog := preload("res://scripts/app/game_catalog.gd")
const QueuedTrainerModel := preload("res://scripts/games/queued_trainer/queued_trainer_model.gd")

const TRAINER_IDS := [
	"skat",
	"piquet",
	"ombre_quadrille",
	"chess",
	"nine_mens_morris",
	"reversi",
	"backgammon",
	"go_9x9",
	"fox_and_geese",
	"halma",
	"ludo_pachisi",
	"go_19x19"
]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for game_id in TRAINER_IDS:
		_verify_catalog_playable(game_id)
		_verify_model(game_id)
	print("Queued trainer verification passed.")
	quit()

func _verify_catalog_playable(game_id: String) -> void:
	for game in GameCatalog.all():
		if game["id"] == game_id:
			_assert(game["status"] == "playable", "%s should be marked playable" % game_id)
			return
	_assert(false, "%s should exist in the catalog" % game_id)

func _verify_model(game_id: String) -> void:
	var model := QueuedTrainerModel.new(game_id)
	model.new_game()
	_assert(model.title != "", "%s should have a title" % game_id)
	_assert(model.guidance_text().contains("Do:") or model.guidance_text().contains("Review:"), "%s should expose structured guidance" % game_id)
	if model.kind == "card":
		_assert(not model.player_cards.is_empty(), "%s should deal a player hand" % game_id)
		_assert(not model.legal_cards().is_empty(), "%s should expose legal cards" % game_id)
	else:
		_assert(model.board.size() == model.board_size, "%s should create a board" % game_id)
		if game_id in ["go_9x9", "go_19x19", "reversi"]:
			_assert(not model.legal_moves("player").is_empty(), "%s should expose placement moves" % game_id)
		else:
			_assert(not model.legal_moves("player").is_empty(), "%s should expose movement moves" % game_id)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
