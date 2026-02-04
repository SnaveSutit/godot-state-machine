@tool
@icon('res://addons/state_machine/icons/ChangeStateButton.svg')
class_name ChangeStateButton
extends Button
## A button that changes the target_state of a [StateMachine] when pressed.

enum StateSelectionMode {
	## Targets a specific [AbstractState] assigned to [member target_state].
	SPECIFIC,
	## Targets the [StateMachine.initial_state] of the [StateMachine].
	INITIAL,
	## Targets the [StateMachine.previous_state] of the [StateMachine].
	PREVIOUS,
	## Targets the state by the name stored in the state machine's metadata under the key &'target_state'.[br]
	## [codeblock]state_machine.set_meta(&'target_state', 'StateName')[/codeblock]
	FROM_META,
}
enum StateMachineSelectionMode {
	## Targets the nearest ancestor [StateMachine].
	NEAREST,
	## Targets the parent [StateMachine] of the nearest ancestor [StateMachine].
	PARENT,
	## Targets the root (top-level) [StateMachine].
	ROOT,
}

## The mode to use when determining which AbstractState to switch to. [br]
@export var state_selection_mode := StateSelectionMode.SPECIFIC:
	set(value):
		state_selection_mode = value
		if Engine.is_editor_hint():
			notify_property_list_changed()
			update_configuration_warnings()
## The mode to use when determining which StateMachine to target. [br]
@export var state_machine_selection_mode := StateMachineSelectionMode.NEAREST
## The [AbstractState] to switch to when the button is pressed.
@export var target_state: AbstractState:
	set(value):
		target_state = value
		if Engine.is_editor_hint():
			update_configuration_warnings()


## Helper function to set &'target_state' metadata in the given state machine for use with [StateSelectionMode.FROM_META].
static func set_target_state_meta(p_state_machine: StateMachine, p_state_name: String) -> void:
	p_state_machine.set_meta(&'target_state', p_state_name)


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	var _state_machine := StateMachine.get_nearest_state_machine(self)
	assert(_state_machine is StateMachine, 'ChangeStateButton must be a descendant of a StateMachine node.')

	pressed.connect(_on_pressed)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	var _state_machine := StateMachine.get_nearest_state_machine(self)
	if not _state_machine:
		warnings.append('ChangeStateButton must be a descendant of a StateMachine node.')

	if state_selection_mode == StateSelectionMode.SPECIFIC:
		if not target_state:
			warnings.append('Target AbstractState is not assigned.')
		elif target_state.get_parent() != _state_machine:
			warnings.append('The assigned Target AbstractState (%s) is not a child of the StateMachine this button belongs to (%s).' % [target_state.name, _state_machine.name])

	return warnings


func _validate_property(property: Dictionary) -> void:
	if property.name == 'target_state' and state_selection_mode != StateSelectionMode.SPECIFIC:
		property.usage |= PROPERTY_USAGE_READ_ONLY


func _on_pressed() -> void:
	var _state_machine := StateMachine.get_nearest_state_machine(self)
	match state_machine_selection_mode:
		StateMachineSelectionMode.PARENT:
			_state_machine = _state_machine.state_machine
		StateMachineSelectionMode.ROOT:
			_state_machine = _state_machine.get_master_state_machine()

	match state_selection_mode:
		StateSelectionMode.INITIAL:
			target_state = _state_machine.initial_state
		StateSelectionMode.PREVIOUS:
			target_state = _state_machine.previous_state
		StateSelectionMode.FROM_META:
			var meta_state = _state_machine.get_meta(&'target_state')
			if meta_state is not String:
				push_error('Metadata "target_state" is missing or not a String in the StateMachine.')
				return
			target_state = _state_machine.get_state(meta_state)

	_state_machine.set_deferred('active_state', target_state)
