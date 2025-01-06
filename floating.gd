extends RigidBody3D

@export var floating_force := 1.4
@export var water_drag := 0.05
@export var water_angular_drag := 0.05
@export var longitudinal_speed := 20.
@export var rotational_speed := 10.

var submerged := false
var probes = []

@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var water = get_node("/root/Map/WaterPlane")


func _ready() -> void:
	for i in range(9):
		var probe = Marker3D.new()
		probe.name = "Marker3D_%d" % i
		add_child(probe)
		probes.append(probe)
	var size = $CollisionShape3D.shape.size
	var shift_x = $CollisionShape3D.shape.size.x / 2
	var shift_y = -$CollisionShape3D.shape.size.y / 4
	var shift_z = $CollisionShape3D.shape.size.z / 2
	probes[0].transform.origin = Vector3(shift_x, shift_y, shift_z)
	probes[1].transform.origin = Vector3(shift_x, shift_y, 0)
	probes[2].transform.origin = Vector3(shift_x, shift_y, -shift_z)
	probes[3].transform.origin = Vector3(0, shift_y, shift_z)
	probes[4].transform.origin = Vector3(0, shift_y, 0)
	probes[5].transform.origin = Vector3(0, shift_y, -shift_z)
	probes[6].transform.origin = Vector3(-shift_x, shift_y, shift_z)
	probes[7].transform.origin = Vector3(-shift_x, shift_y, 0)
	probes[8].transform.origin = Vector3(-shift_x, shift_y, -shift_z)


func _physics_process(_delta: float) -> void:
	var forward_vector = transform.basis.z
	var advance = Input.get_axis("move_backward", "move_forward") * longitudinal_speed
	var rotation_y = Input.get_axis("turn_right", "turn_left") * rotational_speed

	apply_force(forward_vector * advance)
	apply_torque(Vector3(0, rotation_y, 0))

	submerged = false
	for p in probes:
		var depth = water.get_height(p.global_position) - p.global_position.y
		if depth > 0:
			apply_force(
				Vector3.UP * floating_force * gravity * depth, p.global_position - global_position
			)
			submerged = true


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if submerged:
		state.linear_velocity *= 1 - water_drag
		state.angular_velocity *= 1 - water_angular_drag
