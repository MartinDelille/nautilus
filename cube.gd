extends RigidBody3D

@export var floating_force := 1.4
@export var water_drag := 0.05
@export var water_angular_drag := 0.05
@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var water = get_node('/root/Map/WaterPlane')

@onready var probes = $ProbeContainer.get_children()

var submerged = false

func _physics_process(_delta: float) -> void:
	submerged = false
	for p in probes:
		var depth = water.get_height(p.global_position) - p.global_position.y
		if depth > 0:
			apply_force(Vector3.UP * floating_force * gravity * depth, p.global_position - global_position)
			submerged = true

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if submerged:
		state.linear_velocity*=1-water_drag
		state.angular_velocity*=1-water_angular_drag
