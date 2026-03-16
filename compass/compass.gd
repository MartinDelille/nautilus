extends MeshInstance3D

@export var spring_strength: float = 0.05
@export var damping: float = 0.99
@export var max_angular_velocity: float = 0.5

var angular_velocity: Vector3 = Vector3.ZERO


func _process(delta: float) -> void:
	var target_rotation: Vector3 = Vector3(0, -1, 0)
	var displacement: Vector3 = target_rotation - global_rotation
	var spring_force: Vector3 = displacement * spring_strength
	angular_velocity += spring_force
	angular_velocity *= damping
	angular_velocity = angular_velocity.limit_length(max_angular_velocity)
	global_rotation += angular_velocity * delta
