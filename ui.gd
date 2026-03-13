extends Control

@export var shall_apply_force: bool = true


func _ready() -> void:
	$ForceCheckBox.toggled.connect(_on_check_toggled)


func _on_check_toggled(checked: bool):
	shall_apply_force = checked
