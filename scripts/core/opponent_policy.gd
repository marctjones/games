class_name OpponentPolicy
extends RefCounted

const BEGINNER := "beginner"
const CASUAL := "casual"
const STANDARD := "standard"
const ADVANCED := "advanced"
const EXPERT := "expert"
const DEFAULT := STANDARD

const ORDER := [BEGINNER, CASUAL, STANDARD, ADVANCED, EXPERT]
const LABELS := {
	BEGINNER: "Beginner",
	CASUAL: "Casual",
	STANDARD: "Standard",
	ADVANCED: "Advanced",
	EXPERT: "Expert",
}

static func normalize(value: String) -> String:
	return value if ORDER.has(value) else DEFAULT

static func label(value: String) -> String:
	return str(LABELS[normalize(value)])

static func index_for(value: String) -> int:
	return ORDER.find(normalize(value))

static func option_ids() -> Array:
	return ORDER.duplicate()

static func description(value: String) -> String:
	match normalize(value):
		BEGINNER:
			return "Beginner: legal but mistake-prone choices."
		CASUAL:
			return "Casual: blocks obvious tactics but misses some planning."
		STANDARD:
			return "Standard: uses the current game heuristic."
		ADVANCED:
			return "Advanced: favors stronger tactical and scoring choices."
		EXPERT:
			return "Expert: uses the strongest available non-cheating heuristic."
	return ""

static func fairness_note() -> String:
	return "Computer opponents use only legal public information plus their own private hand. They do not inspect hidden hands or unknown deck cards."

static func policy_text(value: String) -> String:
	return "Difficulty: %s\nFair play: %s" % [description(value), fairness_note()]

static func pick_scored(scored: Array, difficulty: String):
	if scored.is_empty():
		return null
	var ranked := scored.duplicate(true)
	ranked.sort_custom(func(a, b): return float(a.get("score", 0.0)) > float(b.get("score", 0.0)))
	var choice_index := _choice_index(ranked.size(), difficulty)
	return ranked[choice_index].get("item")

static func pick_ranked(ranked_best_first: Array, difficulty: String):
	if ranked_best_first.is_empty():
		return null
	return ranked_best_first[_choice_index(ranked_best_first.size(), difficulty)]

static func rummy_visible_pickup_threshold(difficulty: String) -> int:
	match normalize(difficulty):
		BEGINNER:
			return 5
		CASUAL:
			return 3
		STANDARD:
			return 1
		ADVANCED, EXPERT:
			return 0
	return 1

static func allows_speculative_pickup(difficulty: String) -> bool:
	return normalize(difficulty) in [ADVANCED, EXPERT]

static func search_depth(difficulty: String) -> int:
	match normalize(difficulty):
		BEGINNER, CASUAL:
			return 0
		STANDARD:
			return 1
		ADVANCED:
			return 2
		EXPERT:
			return 3
	return 1

static func _choice_index(count: int, difficulty: String) -> int:
	if count <= 1:
		return 0
	match normalize(difficulty):
		BEGINNER:
			return count - 1
		CASUAL:
			return min(count - 1, max(1, int(floor(float(count) / 2.0))))
		STANDARD, ADVANCED, EXPERT:
			return 0
	return 0
