# meta-description: A default template for a State script.
# meta-default: true

@tool
extends _BASE_


func _ready() -> void:
	pass # Initialization code here


func _process(_delta: float) -> void:
	pass # Per-frame logic here


func _physics_process(_delta: float) -> void:
	pass # Physics-related per-frame logic here


func on_state_entered() -> void:
	pass # Logic to execute when this state is entered


func on_state_exited() -> void:
	pass # Logic to execute when this state is exited
