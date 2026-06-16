extends Control

const AppShell := preload("res://scripts/app/app_shell.gd")
const DashboardView := preload("res://scripts/app/dashboard_view.gd")
const GameCatalog := preload("res://scripts/app/game_catalog.gd")
const OpponentPolicy := preload("res://scripts/core/opponent_policy.gd")
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
const QueuedTrainerView := preload("res://scripts/games/queued_trainer/queued_trainer_view.gd")
const Rummy500View := preload("res://scripts/games/rummy_500/rummy_500_view.gd")
const SpadesView := preload("res://scripts/games/spades/spades_view.gd")
const TexasHoldemView := preload("res://scripts/games/texas_holdem/texas_holdem_view.gd")
const TicTacToeView := preload("res://scripts/games/tic_tac_toe/tic_tac_toe_view.gd")
const WhistView := preload("res://scripts/games/whist/whist_view.gd")

var sidebar: VBoxContainer
var game_area: VBoxContainer
var content_panel: PanelContainer
var game_scroll: ScrollContainer
var game_body_row: HBoxContainer
var title_label: Label
var status_panel: PanelContainer
var status_heading_label: Label
var status_label: Label
var coach_panel: PanelContainer
var score_label: Label
var rules_label: Label
var difficulty_option: OptionButton
var current_view: VBoxContainer
var current_game_id := "home"
var opponent_difficulty := OpponentPolicy.DEFAULT
var menu_buttons: Array = []

func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	UiFactory.configure_for_viewport(get_viewport_rect().size)
	_build_shell()
	_show_home()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_refresh_responsive_layout()

func _refresh_responsive_layout() -> void:
	if not UiFactory.configure_for_viewport(get_viewport_rect().size):
		return
	if game_area == null:
		return
	_refresh_sidebar_menu_buttons()
	_refresh_header_style()
	_refresh_coach_style()
	if current_game_id == "home":
		_build_shell()
		_show_home()
	elif current_view != null and current_view.has_method("refresh_layout"):
		current_view.refresh_layout()

func _build_shell() -> void:
	for child in get_children():
		child.queue_free()
	var shell := AppShell.build(self, _on_game_selected, _on_difficulty_selected, opponent_difficulty)
	sidebar = shell["sidebar"]
	game_area = shell["game_area"]
	content_panel = shell["content_panel"]
	game_scroll = shell["game_scroll"]
	menu_buttons = shell["menu_buttons"]
	difficulty_option = shell["difficulty_option"]

func _refresh_sidebar_menu_buttons() -> void:
	for item in menu_buttons:
		var button: Button = item
		button.custom_minimum_size = Vector2(0, int(round(34 * clamp(UiFactory.card_scale, 0.9, 1.25))))
		UiFactory.apply_button_icon(button, str(button.get_meta("icon_path", "")), UiFactory.sidebar_icon_size())

func _clear_game_area() -> void:
	for child in game_area.get_children():
		child.queue_free()
	game_body_row = null
	title_label = null
	status_panel = null
	status_heading_label = null
	status_label = null
	coach_panel = null
	score_label = null
	rules_label = null

func _add_title(text: String) -> void:
	title_label = Label.new()
	title_label.text = text
	title_label.add_theme_font_size_override("font_size", UiFactory.title_font_size())
	title_label.add_theme_color_override("font_color", Color("#222831"))
	game_area.add_child(title_label)

func _add_header(text: String) -> void:
	_add_title(text)
	var guidance := UiFactory.make_guidance_panel()
	status_panel = guidance["panel"]
	status_heading_label = guidance["heading"]
	status_label = guidance["body"]
	game_area.add_child(status_panel)

func _refresh_header_style() -> void:
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", UiFactory.title_font_size())
	if status_panel != null:
		UiFactory.style_guidance_panel(status_panel)
	if status_heading_label != null:
		UiFactory.style_guidance_heading(status_heading_label)
	if status_panel != null and status_label != null:
		UiFactory.style_guidance_body(status_label)

func _refresh_coach_style() -> void:
	if coach_panel != null:
		UiFactory.style_coach_sidebar_panel(coach_panel)

func _show_home() -> void:
	current_view = null
	current_game_id = "home"
	_clear_game_area()
	_add_header("One-player classic games")
	status_label.text = "%s\n\n%s" % [GameCatalog.home_status_text(), OpponentPolicy.policy_text(opponent_difficulty)]
	DashboardView.build(game_area, _on_game_selected)

func _on_game_selected(game_id: String) -> void:
	match game_id:
		"tic_tac_toe":
			_mount_game_view("Tic-tac-toe", TicTacToeView.new())
		"blackjack":
			_mount_game_view("Blackjack", BlackjackView.new())
		"cribbage":
			_mount_game_view("Cribbage", CribbageView.new())
		"gin_rummy":
			_mount_game_view("Gin Rummy", GinRummyView.new())
		"rummy_500":
			_mount_game_view("Rummy 500", Rummy500View.new())
		"klondike":
			_mount_game_view("Klondike Solitaire", KlondikeView.new())
		"five_card_draw":
			_mount_game_view("Five-Card Draw Poker", FiveCardDrawView.new())
		"texas_holdem":
			_mount_game_view("Texas Hold'em", TexasHoldemView.new())
		"rummy":
			_mount_game_view("Basic Rummy", BasicRummyView.new())
		"euchre":
			_mount_game_view("Euchre", EuchreView.new())
		"spades":
			_mount_game_view("Spades", SpadesView.new())
		"bridge":
			_mount_game_view("Bridge Trainer", BridgeView.new())
		"pinochle":
			_mount_game_view("Pinochle", PinochleView.new())
		"whist":
			_mount_game_view("Whist", WhistView.new())
		"canasta":
			_mount_game_view("Canasta", CanastaView.new())
		"checkers":
			_mount_game_view("Checkers / Draughts", CheckersView.new())
		"hearts":
			_mount_game_view("Hearts", HeartsView.new())
		"skat", "piquet", "ombre_quadrille", "chess", "nine_mens_morris", "reversi", "backgammon", "go_9x9", "fox_and_geese", "halma", "ludo_pachisi", "go_19x19":
			_mount_game_view(GameCatalog.name_for(game_id), QueuedTrainerView.new(game_id))
		_:
			_show_queued_game(game_id)

func _mount_game_view(title: String, view: VBoxContainer) -> void:
	_clear_game_area()
	_add_title(title)
	current_game_id = title
	current_view = view
	game_body_row = HBoxContainer.new()
	game_body_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game_body_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	game_body_row.add_theme_constant_override("separation", 16)
	game_area.add_child(game_body_row)
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.add_theme_constant_override("separation", 10)
	game_body_row.add_child(view)
	var coach := UiFactory.make_coach_sidebar()
	coach_panel = coach["panel"]
	status_label = coach["advice"]
	score_label = coach["score"]
	rules_label = coach["rules"]
	score_label.text = "Score appears here after the game starts."
	rules_label.text = "Rules and strategy notes appear here for the selected game."
	game_body_row.add_child(coach_panel)
	view.setup(status_label, score_label, rules_label)
	_apply_difficulty_to_current_view()

func _show_queued_game(game_id: String) -> void:
	var game_name := GameCatalog.name_for(game_id)
	current_view = null
	current_game_id = game_id
	_clear_game_area()
	_add_header(game_name)
	status_label.text = "Queued module. This entry is reserved in the platform plan. Next implementation step: rules engine, legal move generator, basic computer opponent, and coaching hooks."

func _on_difficulty_selected(index: int) -> void:
	if difficulty_option == null:
		return
	var id := str(difficulty_option.get_item_metadata(index))
	opponent_difficulty = OpponentPolicy.normalize(id)
	if current_game_id == "home":
		status_label.text = "%s\n\n%s" % [GameCatalog.home_status_text(), OpponentPolicy.policy_text(opponent_difficulty)]
	else:
		_apply_difficulty_to_current_view()

func _apply_difficulty_to_current_view() -> void:
	if current_view == null:
		return
	if current_view.has_method("set_difficulty"):
		current_view.set_difficulty(opponent_difficulty)
	else:
		var model = current_view.get("model")
		if model != null and model.has_method("set_difficulty"):
			model.set_difficulty(opponent_difficulty)
	if current_view.has_method("refresh_layout"):
		current_view.refresh_layout()
	if score_label != null:
		var current_score := score_label.text
		if current_score.find("\nDifficulty:") >= 0:
			current_score = current_score.substr(0, current_score.find("\nDifficulty:"))
		score_label.text = "%s\n%s" % [current_score, OpponentPolicy.policy_text(opponent_difficulty)]
