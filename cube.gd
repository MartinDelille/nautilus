extends RigidBody3D

@export var floating_force:=1.0
@export var water_drag := 0.05
@export var water_angular_drag := 0.05
@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

const water_height:= 0.0

var submerged=false

func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	submerged=false
	var depth = water_height - global_position.y
	if depth > 0:
		apply_central_force(Vector3.UP*floating_force*gravity*depth)
		submerged=true

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if submerged:
		state.linear_velocity*=1-water_drag
		state.angular_velocity*=1-water_angular_drag
