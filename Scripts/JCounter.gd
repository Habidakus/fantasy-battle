class_name JCounter extends RefCounted

static var _counts : Dictionary = {}
var _index : String

static func Create(index : String) -> JCounter:
	var ret_val : JCounter = JCounter.new()
	ret_val.increment(index)
	return ret_val

func increment(index : String) -> void:
	_index = index
	if _counts.has(index):
		var f = _counts[index] + 1
		assert(f < 9999)
		_counts[index] = f
	else:
		_counts[index] = 1

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_counts[_index] = _counts[_index] - 1
