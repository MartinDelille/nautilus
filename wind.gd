@tool
extends Node3D

@export var wind_angle_degree := 0.
@export var wind_intensity := 3.

@export var wind_angle_radiant: float:
	get:
		return wind_angle_degree * PI / 180
@export var wind_vector: Vector3:
	get:
		return Vector3.RIGHT * Quaternion(Vector3.UP, wind_angle_radiant) * wind_intensity


func _process(_delta: float) -> void:
	$Arrow.rotation.y = -wind_angle_radiant
