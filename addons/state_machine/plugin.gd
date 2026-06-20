@tool
extends EditorPlugin

var editor_selection := EditorInterface.get_selection()


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	editor_selection.selection_changed.connect(_on_selection_changed)


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	editor_selection.selection_changed.disconnect(_on_selection_changed)


func update_selected_state_visibility(selection: Array[Node]) -> void:
	if selection.size() == 0:
		return
	var first_node := selection[0]

	# Only show children of the selected [AbstractState].
	var selected_state := AbstractState.get_nearest_abstract_state(first_node)

	var machine := selected_state.get_master_state_machine()
	var queue: Array[AbstractState] = [machine]
	while queue.size() > 0:
		var state := queue.pop_front()
		if state is StateMachine:
			for child in state.get_states():
				child.visible = child == selected_state
				if child is AbstractState:
					queue.push_back(child)
		else:
			state.visible = state == selected_state


func _on_selection_changed() -> void:
	var selection := editor_selection.get_selected_nodes()
	update_selected_state_visibility(selection)


func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass
