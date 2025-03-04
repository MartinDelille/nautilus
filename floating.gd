extends RigidBody3D

@export var floating_force := 1.4
@export var water_drag := 0.05
@export var water_angular_drag := 0.05
@export var longitudinal_speed := 20.
@export var rotational_speed := 10.
@export var bome_rotation := 0.
@export var bome_rotational_speed = 0.05
@export var air_density = 1.225
@export var drag_coefficient = 1.0
@export var lift_coefficient = 0.5
@export var sail_area = 20

var submerged := false
var probes = []
var bome_bone_index := 0

@onready var skeleton: Skeleton3D = $BoatModel/Armature/Skeleton3D
@onready var wind: Node3D = $"../Wind"
@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var water = get_node("/root/Map/Ocean")


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

	bome_bone_index = skeleton.find_bone("BomeBone")


func _physics_process(_delta: float) -> void:
	var rotation_y = Input.get_axis("turn_right", "turn_left") * rotational_speed
	bome_rotation += Input.get_axis("turn_bome_right", "turn_bome_left") * bome_rotational_speed
	bome_rotation = clamp(bome_rotation, -PI / 2, PI / 2)

	apply_torque(Vector3(0, rotation_y, 0))

	var bome_quaternion = Quaternion(Vector3(0, 0, 1), bome_rotation)
	skeleton.set_bone_pose_rotation(bome_bone_index, bome_quaternion)

	var sail_quaternion = Quaternion(Vector3.UP, bome_rotation - global_rotation.y)
	var sail_normal = Vector3.BACK * sail_quaternion
	var sail_direction = Vector3.RIGHT * sail_quaternion

	var effective_wind_velocity = wind.wind_vector.dot(sail_normal)

	# Drag and lift forces
	var wind_force = (
		0.5 * air_density * drag_coefficient * sail_area * pow(effective_wind_velocity, 2)
	)
	var lift_force = (
		0.5 * air_density * lift_coefficient * sail_area * pow(effective_wind_velocity, 2)
	)

	var force = sail_direction * lift_force
	if effective_wind_velocity > 0:
		force += sail_normal * wind_force
	else:
		force -= sail_normal * wind_force

	var keel_lift_axe = Vector3.BACK * Quaternion(Vector3.DOWN, global_rotation.y)
	var keel_lift = -force.project(keel_lift_axe)

	apply_force(force, Vector3(0, 2, 0))
	apply_force(keel_lift, Vector3(0, -2, 0))

	$LiftForceArrow.rotation = Vector3.DOWN * bome_rotation
	$LiftForceArrow.scale.x = lift_force
	$WindForceArrow.rotation = Vector3.DOWN * (bome_rotation + PI / 2)
	$WindForceArrow.scale.x = wind_force

	submerged = false
	for p in probes:
		var depth = water.get_height(p.global_position) - p.global_position.y
		if depth > 0:
			apply_force(
				Vector3.UP * floating_force * gravity * depth, p.global_position - global_position
			)
			submerged = true

	$Yaw.position = lerp($Yaw.position, position, 0.002)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if submerged:
		state.linear_velocity *= 1 - water_drag
		state.angular_velocity *= 1 - water_angular_drag
