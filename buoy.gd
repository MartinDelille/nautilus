extends RigidBody3D

@export var floating_force := 1.4
@export var water_drag := 0.05
@export var water_angular_drag := .1
@export var courant := 30.
@export var anchor_tension := 50.

var submerged := false

@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var wind: Node3D = $"../Wind"
@onready var water = $"../Ocean"
@onready var anchor = $Anchor


func _physics_process(_delta: float) -> void:
	var depth = water.get_height(position) - position.y + 1
	submerged = depth > 0
	if submerged:
		apply_force(Vector3.UP * floating_force * gravity * depth)
	var fan_direction = -global_transform.basis.z
	apply_torque(Vector3.UP * wind.wind_vector.dot(fan_direction))
	apply_force(Vector3(1, 0, 1) * courant)
	var anchor_force = anchor.position - position
	if anchor_force.length() > anchor_tension:
		apply_force(
			anchor_force * (anchor_force.length() - anchor_tension), -global_transform.basis.y * 0.1
		)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if submerged:
		state.linear_velocity *= 1 - water_drag
		state.angular_velocity *= 1 - water_angular_drag
