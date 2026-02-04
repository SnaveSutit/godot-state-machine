@tool
@icon('res://addons/state_machine/icons/State.svg')
class_name State
extends AbstractState
## A base class for states within a [StateMachine].[br]
## States can have their own [State] children, allowing for hierarchical state management.[br]
## Best practices:[br]
## - Connect signals in [method on_state_entered] and disconnect them in [method on_state_exited].[br]
## - Input processing is automatically enabled only when this state is active, allowing state-specific inputs to be handled here.[br]
## - Don't override [method _enter_tree] and [method _exit_tree] to avoid unintended behavior in the editor. Use [method on_state_entered] and [method on_state_exited] instead.


## Returns the nearest ancestor [State] of the given [param node], or null if none exists.
static func get_nearest_state(node: Node) -> State:
	while node:
		if node is State:
			return node
		node = node.get_parent()
	return null


func _enter_tree() -> void:
	super._enter_tree()
	visibility_changed.connect(_on_visibility_changed)
	visible = false


func _exit_tree() -> void:
	super._exit_tree()
	visibility_changed.disconnect(_on_visibility_changed)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray

	if not state_machine:
		warnings.append('State must be a child of a StateMachine in order to function properly.')

	var method_names = self.get_method_list().map(func(m: Dictionary) -> String: return m.name)
	if method_names.count('_enter_tree') > 3:
		warnings.append("This State\'s script defines _enter_tree(), This function will run within the editor and may cause unintended behavior. Consider using on_state_entered() or _ready() instead.")
	if method_names.count('_exit_tree') > 3:
		warnings.append("This State\'s script defines _exit_tree(), This function will run within the editor and may cause unintended behavior. Consider using on_state_exited() instead.")

	return warnings


## Called when the state is entered.
func on_state_entered() -> void:
	pass


## Called when the state is exited.
func on_state_exited() -> void:
	pass


func _on_visibility_changed() -> void:
	for child in get_children():
		if 'visible' in child:
			child.visible = visible
