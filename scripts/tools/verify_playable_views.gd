extends SceneTree

const UiFactory := preload("res://scripts/ui/ui_factory.gd")
const BasicRummyView := preload("res://scripts/games/basic_rummy/basic_rummy_view.gd")
const BlackjackView := preload("res://scripts/games/blackjack/blackjack_view.gd")
const BridgeView := preload("res://scripts/games/bridge/bridge_view.gd")
const CanastaView := preload("res://scripts/games/canasta/canasta_view.gd")
const CheckersView := preload("res://scripts/games/checkers/checkers_view.gd")
const CribbageView := preload("res://scripts/games/cribbage/cribbage_view.gd")
const EuchreView := preload("res://scripts/games/euchre/euchre_view.gd")
const FiveCardDrawView := preload("res://scripts/games/five_card_draw/five_card_draw_view.gd")
const GinRummyView := preload("res://scripts/games/gin_rummy/gin_rummy_view.gd")
const HeartsView := preload("res://scripts/games/hearts/hearts_view.gd")
const KlondikeView := preload("res://scripts/games/klondike/klondike_view.gd")
const PinochleView := preload("res://scripts/games/pinochle/pinochle_view.gd")
const Rummy500View := preload("res://scripts/games/rummy_500/rummy_500_view.gd")
const SpadesView := preload("res://scripts/games/spades/spades_view.gd")
const TexasHoldemView := preload("res://scripts/games/texas_holdem/texas_holdem_view.gd")
const TicTacToeView := preload("res://scripts/games/tic_tac_toe/tic_tac_toe_view.gd")
const WhistView := preload("res://scripts/games/whist/whist_view.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	UiFactory.configure_for_viewport(Vector2(1440, 900))
	var views := [
		BlackjackView,
		BridgeView,
		CanastaView,
		CheckersView,
		CribbageView,
		EuchreView,
		FiveCardDrawView,
		GinRummyView,
		HeartsView,
		KlondikeView,
		PinochleView,
		Rummy500View,
		SpadesView,
		TexasHoldemView,
		BasicRummyView,
		TicTacToeView,
		WhistView,
	]
	for view_script in views:
		var status_label := Label.new()
		var score_label := Label.new()
		var rules_label := Label.new()
		var view: VBoxContainer = view_script.new()
		view.setup(status_label, score_label, rules_label)
		if view.has_method("refresh_layout"):
			view.refresh_layout()
		_assert_not_empty(status_label.text, "%s status text" % view_script.resource_path)
		_assert_not_empty(score_label.text, "%s score text" % view_script.resource_path)
		_assert_not_empty(rules_label.text, "%s rules text" % view_script.resource_path)
		view.free()
		status_label.free()
		score_label.free()
		rules_label.free()
	await process_frame
	print("Playable view verification passed.")
	quit()

func _assert_not_empty(text: String, label: String) -> void:
	if text.strip_edges() == "":
		push_error("%s was empty." % label)
		quit(1)
