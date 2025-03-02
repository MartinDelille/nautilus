extends Node3D

@export var wind_direction := 0.
@export var wind_intensity := 3.

@export var wind_vector: Vector3:
	get:
		return Vector3.RIGHT * Quaternion(Vector3.UP, wind_direction * PI / 180) * wind_intensity


func _init() -> void:
	print(Vector3.RIGHT)
	print(Vector3.RIGHT * Quaternion(Vector3.UP, PI / 2))


func _process(_delta: float) -> void:
	$Arrow.rotation = Vector3(0, -wind_direction * PI / 180, 0)
