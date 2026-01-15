extends RigidBody3D

@export var floating_force := 4.6
@export var water_drag := 0.3
@export var water_angular_drag := .7
@export var longitudinal_speed := 20.
@export var barre_rotation := 0.
@export var barre_rotational_speed := 0.01
@export var boom_rotational_speed := 0.03
@export var air_density := 1.225
@export var drag_coefficient := 1.0
@export var lift_coefficient := 0.5
@export var sail_area := 30
@export var keel_weight := 100

var submerged := false
var probes = []
var barre_bone_index := 0
var sheet_limit: float = 60.0

@onready var barre_skeleton: Skeleton3D = $BoatModel/ArmatureBarre/Skeleton3D
@onready var wind: Node3D = $"../Wind"
@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var water = $"../Ocean"
@onready var boom: RigidBody3D = $Boom
@onready var hinge: HingeJoint3D = $HingeJoint3D


func _display_vector(
	_v: Vector3, _where := Vector3.ZERO, _color := Color(1., 1., 1.), _target: Node3D = null
):
	pass


func _display_quaternion(q: Quaternion, where := Vector3.ZERO, color := Color(1., 1., 0.)):
	var v := Vector3(q.x, q.y, q.z) * q.get_angle() * 100
	_display_vector(v, where, color)


func _apply_and_display_force(
	force: Vector3,
	where := Vector3.ZERO,
	color := Color(1., 0., 1.),
	display_vector := true,
	target: Node3D = null
):
	if target == null:
		target = self
	else:
		where += target.global_position
	target.apply_force(force, where)
	if display_vector:
		_display_vector(force, where, color, target)


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

	barre_bone_index = barre_skeleton.find_bone("BarreBone")


func _process(_delta: float) -> void:
	var instant_rotation: float = (
		Input.get_axis("move_backward", "move_forward") * boom_rotational_speed
	)

	sheet_limit += instant_rotation * 20
	sheet_limit = clamp(sheet_limit, 10, 80)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		var drag_event: InputEventScreenDrag = event
		var dir := drag_event.relative
		print("drag: ", dir)
		sheet_limit += dir.y * 0.1
		barre_rotation += dir.x * 0.01


func _physics_process(_delta: float) -> void:
	barre_rotation += Input.get_axis("turn_right", "turn_left") * barre_rotational_speed
	barre_rotation = clamp(barre_rotation, -PI / 2, PI / 2)
	barre_skeleton.set_bone_pose_rotation(
		barre_bone_index, Quaternion(Vector3(0, 1, 0), barre_rotation)
	)

	apply_torque(Vector3(0, -barre_rotation * 100, 0))

	hinge.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(-sheet_limit))
	hinge.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(sheet_limit))

	var boom_length = 4  # Replace with actual length if available
	var boom_force_position = (
		boom.global_transform.origin - boom.global_transform.basis.x * boom_length
	)
	boom_force_position = -boom.global_transform.basis.x * boom_length
	_apply_and_display_force(
		wind.wind_vector * 5,
		boom_force_position,
		Color(1, 1, 0),
		true,
		boom,
	)

	var sail_quaternion = boom.global_transform.basis.get_rotation_quaternion()
	var sail_normal = sail_quaternion * transform.basis.z
	var sail_direction = sail_quaternion * transform.basis.x

	var effective_wind_velocity = wind.wind_vector.dot(sail_normal)
	var sail_scale = 16
	_display_vector(sail_scale * sail_normal, transform.basis.y * 4, Color(0, 1, 0))
	_display_vector(sail_scale * sail_direction, transform.basis.y * 4, Color(1, 0, 0))
	_display_vector(8 * wind.wind_vector, transform.basis.y * 8, Color(0, 1, 1))

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
	_apply_and_display_force(wind_force, boom_force_position, Color(0, 0, 1.), true, boom)
	_apply_and_display_force(keel_lift, Vector3.ZERO, Color(.9, .5, .1), true, boom)
	_apply_and_display_force(Vector3.DOWN * keel_weight, -10 * transform.basis.y)

	submerged = false
	for p in probes:
		var depth = water.get_height(p.global_position) - p.global_position.y + 0.5
		if depth > 0:
			_apply_and_display_force(
				Vector3.UP * floating_force * gravity * pow(depth, 2),
				p.global_position - global_position,
				Color(1., 0, 1),
				false
			)
			submerged = true

	var drag = -linear_velocity * linear_velocity.length() * water_drag
	_apply_and_display_force(drag)

	$Yaw.position = lerp($Yaw.position, position, 0.05)
	$WindArea.wind_force_magnitude = wind.wind_intensity * 20


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if submerged:
		state.angular_velocity *= 1 - water_angular_drag
