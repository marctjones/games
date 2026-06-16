class_name StrategyText
extends RefCounted

static func advice(action: String, reason: String = "", watch: String = "", drill: String = "") -> String:
	var lines := []
	if action != "":
		lines.append("Do: %s" % action)
	if reason != "":
		lines.append("Why: %s" % reason)
	if watch != "":
		lines.append("Watch: %s" % watch)
	if drill != "":
		lines.append("Drill: %s" % drill)
	return "\n".join(lines)

static func score_delta_text(before: int, after: int, lower_is_better: bool = true) -> String:
	var delta := before - after if lower_is_better else after - before
	if delta > 0:
		return "improves by %d" % delta
	if delta < 0:
		return "costs %d" % abs(delta)
	return "does not change the score"

static func review(result: String, lesson: String, next_focus: String = "") -> String:
	var lines := []
	if result != "":
		lines.append("Review: %s" % result)
	if lesson != "":
		lines.append("Lesson: %s" % lesson)
	if next_focus != "":
		lines.append("Next: %s" % next_focus)
	return "\n".join(lines)
