@tool
@icon('res://addons/state_machine/icons/StateMachine.svg')
class_name StateMachine
extends AbstractState
## Manages a set of child [State] nodes and handles transitions between them.[br]
## [b]Usage:[/b][br]
## - Add [State] nodes as direct children of this node.[br]
## - Assign [member initial_state] in the Inspector.[br]
## - Call [method change_state] to change the active [State].[br]
## [br]
## Notes:[br]
## - Only the active [State] will have processing enabled. This allows for state-specific logic and input handling.[br]
## - Child nodes of each [State] will be hidden when the state is inactive, and shown when active, if they have a 'visible' property.
## - When in the editor, all processing of this node and its children is disabled to prevent unintended behavior.[br]

## Emitted when [member active_state] is changed, after all active_state transitions have finished.
signal state_changed(state: AbstractState, previous_state: AbstractState)

## The first [State] to enter when the [StateMachine] is initialized.
@export var initial_state: AbstractState:
	set(value):
		initial_state = value
		if Engine.is_editor_hint():
			update_configuration_warnings()

var previous_state: AbstractState
## The currently active [AbstractState].[br]
## Setting this property will transition to the new state, calling [method on_state_exited] on the previous state and [method on_state_entered] on the new state.
var active_state: AbstractState:
	set(value):
		if Engine.is_editor_hint():
			push_error('Cannot change active_state while in editor.')
			return

		if active_state == value:
			return

		if active_state:
			_deactivate_state(active_state)

		previous_state = active_state
		active_state = value

		if active_state:
			_activate_state(active_state)

		state_changed.emit(active_state, previous_state)


## Returns the nearest ancestor [StateMachine] of the given [param node], or null if none exists.
static func get_nearest_state_machine(node: Node) -> StateMachine:
	var parent := node.get_parent()
	while parent:
		if parent is StateMachine:
			return parent
		parent = parent.get_parent()
	return null


func _enter_tree() -> void:
	super._enter_tree()
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exiting_tree)
	visibility_changed.connect(_on_visibility_changed)


func _ready() -> void:
	if Engine.is_editor_hint():
		_disable_processing(self)
		for states in get_states():
			_disable_processing(states)
		return

	assert(initial_state != null, 'StateMachine "%s" has no Initial State assigned.' % name)

	visible = false
	for state in get_states():
		state.process_mode = Node.PROCESS_MODE_DISABLED

	if get_master_state_machine() == self:
		active_state = initial_state


func _exit_tree() -> void:
	super._exit_tree()
	child_entered_tree.disconnect(_on_child_entered_tree)
	child_exiting_tree.disconnect(_on_child_exiting_tree)
	visibility_changed.disconnect(_on_visibility_changed)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	if get_children().filter(is_instance_of.bind(AbstractState)).size() == 0:
		warnings.append('StateMachine requires at least one child AbstractState.')

	if initial_state == null:
		warnings.append('Initial State is not assigned.')

	elif initial_state.state_machine != self:
		warnings.append('The assigned Initial State (%s) is not an ancestor of this StateMachine.' % initial_state.name)

	return warnings


## Returns the master (top-level) [StateMachine] of this [StateMachine].
func get_master_state_machine() -> StateMachine:
	if state_machine:
		return state_machine.get_master_state_machine()
	return self


func on_state_entered() -> void:
	active_state = initial_state


func on_state_exited() -> void:
	active_state = null


## Returns the [AbstractState] with the specified name, or null if no such [AbstractState] exists.[br]
## Substates can be accessed using a path-like syntax, e.g. "StateA/SubstateB".
func get_state(state_name: String) -> AbstractState:
	var node := get_node_or_null(state_name)
	if node is AbstractState:
		return node
	return null


## Transitions to the [AbstractState] with the specified name.[br]
## Substates can be accessed using a path-like syntax, e.g. "StateA/SubstateB".
func change_state(state_name: String) -> void:
	var node := get_node_or_null(state_name)

	if node is not AbstractState:
		# if state_machine:
		# 	# Try changing state in parent StateMachine
		# 	state_machine.change_state(state_name)
		# 	return
		push_error('StateMachine "%s" has no AbstractState "%s".' % [name, state_name])
		return

	active_state = node


func get_states() -> Array[AbstractState]:
	var states: Array[AbstractState]
	for child in get_children():
		if child is AbstractState:
			states.append(child)
	return states


func change_state_to_default() -> void:
	active_state = initial_state


func change_state_to_previous() -> void:
	if active_state == previous_state:
		push_error('StateMachine "%s": Current active_state is the same as previous_state. Falling back to initial_state.' % name)
		active_state = initial_state
		return
	active_state = previous_state


func _on_visibility_changed() -> void:
	if Engine.is_editor_hint():
		for state in get_states():
			state.visible = state == initial_state and visible
		return

	for state in get_states():
		state.visible = state == active_state and visible


func _on_child_entered_tree(child: Node) -> void:
	if Engine.is_editor_hint() and child is AbstractState:
		if not child.ready.is_connected(_disable_processing):
			child.ready.connect(_disable_processing.bind(child))
		update_configuration_warnings()
		return


func _on_child_exiting_tree(child: Node) -> void:
	if Engine.is_editor_hint() and child is AbstractState:
		if child.ready.is_connected(_disable_processing):
			child.ready.disconnect(_disable_processing)
		update_configuration_warnings()
		return


## Used to disable all processing on a node in the editor.
func _disable_processing(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	node.set_process_input(false)
	node.set_process_internal(false)
	node.set_process_shortcut_input(false)
	node.set_process_unhandled_input(false)
	node.set_process_unhandled_key_input(false)


func _activate_state(state: AbstractState) -> void:
	state.process_mode = Node.PROCESS_MODE_INHERIT
	state.visible = true
	state.on_state_entered()


func _deactivate_state(state: AbstractState) -> void:
	state.process_mode = Node.PROCESS_MODE_DISABLED
	state.visible = false
	state.on_state_exited()
