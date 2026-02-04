@tool
@icon('res://addons/state_machine/icons/State.svg')
@abstract
class_name AbstractState
extends Node

signal visibility_changed

## The [StateMachine] that owns this [AbstractState].
var state_machine: StateMachine
var visible: bool = true:
	set(value):
		if visible == value:
			return
		visible = value
		visibility_changed.emit()


static func get_nearest_abstract_state(node: Node) -> AbstractState:
	while node:
		if node is AbstractState:
			return node
		node = node.get_parent()
	return null


func _enter_tree() -> void:
	var parent := get_parent()
	if parent is StateMachine:
		state_machine = parent


func _exit_tree() -> void:
	state_machine = null


## Called when the state is entered.
@abstract func on_state_entered() -> void


## Called when the state is exited.
@abstract func on_state_exited() -> void
