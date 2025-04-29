extends RigidBody3D

@export var sail_mode := true
@export var floating_force := 1.4
@export var water_drag := 0.3
@export var water_angular_drag := .7
@export var longitudinal_speed := 20.
@export var barre_rotation := 0.
@export var barre_rotational_speed := 0.02
@export var bome_rotation := 0.
@export var bome_rotational_speed = 0.03
@export var air_density = 1.225
@export var drag_coefficient = 1.0
@export var lift_coefficient = 0.5
@export var sail_area = 20
@export var keel_weight = 10

var submerged := false
var probes = []
var bome_bone_index := 0
var barre_bone_index := 0

@onready var bome_skeleton: Skeleton3D = $BoatModel/ArmatureBome/Skeleton3D
@onready var barre_skeleton: Skeleton3D = $BoatModel/ArmatureBarre/Skeleton3D
@onready var wind: Node3D = $"../Wind"
@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var water = $"../Ocean"


func _ready() -> void:
	for i in range(9):
		var probe = Marker3D.new()
		probe.name = "Marker3D_%d" % i
		add_child(probe)
		probes.append(probe)
	var size = $CollisionShape3D.shape.size
	var shift_x = $CollisionShape3D.shape.size.x / 2
	var shift_y = -$CollisionShape3D.shape.size.y / 2
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

	bome_bone_index = bome_skeleton.find_bone("BomeBone")
	barre_bone_index = barre_skeleton.find_bone("BarreBone")


func _physics_process(_delta: float) -> void:
	barre_rotation += Input.get_axis("turn_right", "turn_left") * barre_rotational_speed
	barre_rotation = clamp(barre_rotation, -PI / 2, PI / 2)
	barre_skeleton.set_bone_pose_rotation(
		barre_bone_index, Quaternion(Vector3(0, 1, 0), barre_rotation)
	)

	if sail_mode:
		var barre_quaternion = Quaternion(transform.basis.y, -barre_rotation)
		var barre_force_direction = transform.basis.z * barre_quaternion
		var prod = -barre_force_direction.dot(linear_velocity) * 100

		apply_force(barre_force_direction * prod, -15 * transform.basis.x)
	else:
		apply_torque(Vector3(0, barre_rotation * 50, 0))

	bome_rotation += Input.get_axis("turn_bome_right", "turn_bome_left") * bome_rotational_speed
	bome_rotation = clamp(bome_rotation, -PI / 2, PI / 2)
	bome_skeleton.set_bone_pose_rotation(
		bome_bone_index, Quaternion(Vector3(0, 0, 1), bome_rotation)
	)
	$Bome.rotation.y = -bome_rotation

	var sail_quaternion = Quaternion(Vector3.UP, bome_rotation)
	var sail_normal = transform.basis.z * sail_quaternion
	var sail_direction = transform.basis.x * sail_quaternion
	var effective_wind_velocity = wind.wind_vector.dot(sail_normal)

	# Drag and lift effects
	var wind_effect = (
		0.5 * air_density * drag_coefficient * sail_area * pow(effective_wind_velocity, 2)
	)
	var lift_effect = (
		0.5 * air_density * lift_coefficient * sail_area * pow(effective_wind_velocity, 2)
	)

	var wind_force = sail_direction * lift_effect
	if effective_wind_velocity < 0:
		wind_force -= sail_normal * wind_effect
	else:
		wind_force += sail_normal * wind_effect

	var keel_lift = -wind_force.project(transform.basis.z)
	if sail_mode:
		apply_force(wind_force, transform.basis.y * 4)
		apply_force(keel_lift, Vector3.ZERO)
		apply_force(Vector3.DOWN * keel_weight, -10 * transform.basis.y)
	else:
		var move = Input.get_axis("move_backward", "move_forward") * 40
		apply_force(global_transform.basis.x * move)

	submerged = false
	for p in probes:
		var depth = water.get_height(p.global_position) - p.global_position.y
		if depth > 0:
			apply_force(
				Vector3.UP * floating_force * gravity * pow(depth, 2),
				p.global_position - global_position
			)
			submerged = true

	var drag = -linear_velocity * linear_velocity.length() * water_drag
	apply_force(drag)

	$Yaw.position = lerp($Yaw.position, position, 0.05)
	$WindArea.wind_force_magnitude = wind.wind_intensity * 20


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if submerged:
		state.angular_velocity *= 1 - water_angular_drag
