extends Node3D

@onready var yaw: Node3D = $"."
@onready var pitch: Node3D = %Pitch
@onready var camera_3d: Camera3D = $Pitch/Camera3D


func _input(event: InputEvent) -> void:
	var wheel_movement = Vector3.ZERO
	if event is InputEventMouseMotion:
		var mouse_movement = event.relative * PI / 300
		if event.pressure:
			yaw.rotate_y(-mouse_movement.x)
			pitch.rotate_x(-mouse_movement.y)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			wheel_movement.z = -event.factor
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			wheel_movement.z = event.factor
	if event is InputEventPanGesture:
		wheel_movement.z = event.delta.angle() * .1
	camera_3d.translate(wheel_movement)
