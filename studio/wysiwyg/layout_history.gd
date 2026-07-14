class_name LayoutHistory

signal history_changed

var _undo_stack: Array[Dictionary] = []
var _redo_stack: Array[Dictionary] = []
var _pending: Dictionary = {}
var _max_steps: int = 50

func clear() -> void:
	_undo_stack.clear()
	_redo_stack.clear()
	_pending = {}
	history_changed.emit()

func can_undo() -> bool:
	return !_undo_stack.is_empty()

func can_redo() -> bool:
	return !_redo_stack.is_empty()

# snapshot current layout *before* a discrete edit (add, remove, property change)
func record(layout: WidgetLayout) -> void:
	_push_undo(_snapshot(layout))
	_redo_stack.clear()
	_pending = {}
	history_changed.emit()

# start of a continuous gesture (move / resize) — only captures once per gesture
func begin(layout: WidgetLayout) -> void:
	if !_pending.is_empty():
		return
	_pending = _snapshot(layout)

# end of a continuous gesture — commits the pending before-state if any
func commit() -> void:
	if _pending.is_empty():
		return
	_push_undo(_pending)
	_redo_stack.clear()
	_pending = {}
	history_changed.emit()

func undo(current_layout: WidgetLayout) -> Dictionary:
	if !can_undo():
		return {}
	_redo_stack.append(_snapshot(current_layout))
	var snapshot = _undo_stack.pop_back()
	history_changed.emit()
	return snapshot

func redo(current_layout: WidgetLayout) -> Dictionary:
	if !can_redo():
		return {}
	_undo_stack.append(_snapshot(current_layout))
	var snapshot = _redo_stack.pop_back()
	history_changed.emit()
	return snapshot

func _push_undo(snapshot: Dictionary) -> void:
	_undo_stack.append(snapshot)
	if _undo_stack.size() > _max_steps:
		_undo_stack.pop_front()

func _snapshot(layout: WidgetLayout) -> Dictionary:
	return layout.to_dict().duplicate_deep()
