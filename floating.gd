extends RigidBody3D

const ForceUtils = preload("res://force_utils.gd")

@export var floating_force := 50
@export var water_drag := 2.
@export var water_angular_drag := .7
@export var longitudinal_speed := 20.
@export var rudder_rotation := 0.
@export var rudder_rotational_speed := 1.
@export var rudder_torque := 1000
@export var boom_rotation := 0.
@export var boom_rotational_speed := 0.03
@export var air_density := 1.225
@export var drag_coefficient := 1.0
@export var lift_coefficient := 0.5
@export var sail_area := 30
@export var keel_weight := 200

var submerged := false
var probes = []
var boom_bone_index := 0
var rudder_bone_index := 0
var mainsheet = 0.1

@onready var boom_skeleton: Skeleton3D = $BoatModel/ArmatureBoom/Skeleton3D
@onready var rudder_skeleton: Skeleton3D = $BoatModel/ArmatureBarre/Skeleton3D
@onready var wind: Node3D = $"../Wind"
@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var water = $"../Ocean"
@onready var sail: SoftBody3D = $Boom/Sail


func _ready() -> void:
	for i in range(4):
		var probe = Marker3D.new()
		probe.name = "Marker3D_%d" % i
		add_child(probe)
		probes.append(probe)
	var size = $CollisionShape3D.shape.size
	var shift_x = $CollisionShape3D.shape.size.x / 2
	var shift_y = -$CollisionShape3D.shape.size.y * 1.5
	var shift_z = $CollisionShape3D.shape.size.z / 2
	probes[0].transform.origin = Vector3(shift_x, shift_y, shift_z)
	probes[1].transform.origin = Vector3(shift_x, shift_y, -shift_z)
	probes[2].transform.origin = Vector3(-shift_x, shift_y, shift_z)
	probes[3].transform.origin = Vector3(-shift_x, shift_y, -shift_z)

	boom_bone_index = boom_skeleton.find_bone("BoomBone")
	rudder_bone_index = rudder_skeleton.find_bone("BarreBone")
	ForceUtils.set_font_size(40, 200)

	for index in [2, 3, 11, 18, 21, 28, 31, 38, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49]:
		sail.set_point_pinned(index, true, NodePath(".."))


func _physics_process(delta: float) -> void:
	DebugDraw2D.set_text("FPS:", Engine.get_frames_per_second(), 0)
	DebugDraw2D.set_text(
		"Knots:", "%6.1f" % (Vector2(linear_velocity.x, linear_velocity.z).length() * 1.94384)
	)
	DebugDraw2D.set_text("Rotation speed:", "%6.1f" % rad_to_deg(-angular_velocity.y))

	mainsheet += Input.get_axis("move_backward", "move_forward") * delta
	mainsheet = clamp(mainsheet, 0.1, 2.0)
	rudder_rotation += Input.get_axis("turn_right", "turn_left") * rudder_rotational_speed * delta
	rudder_rotation = clamp(rudder_rotation, -PI / 2, PI / 2)
	rudder_skeleton.set_bone_pose_rotation(
		rudder_bone_index, Quaternion(Vector3(0, 1, 0), rudder_rotation)
	)

	apply_torque(Vector3(0, -rudder_rotation * rudder_torque * linear_velocity.length(), 0))

	boom_skeleton.set_bone_pose_rotation(
		boom_bone_index, Quaternion(Vector3(0, 0, 1), boom_rotation)
	)
	$Boom.rotation.y = -boom_rotation

	var sail_quaternion = Quaternion(Vector3.UP, boom_rotation)
	var sail_normal = transform.basis.z * sail_quaternion
	var sail_direction = transform.basis.x * sail_quaternion

	boom_rotation -= sail_normal.dot(wind.wind_vector) * .01
	boom_rotation = clamp(boom_rotation, -mainsheet, mainsheet)

	var effective_wind_velocity = wind.wind_vector.dot(sail_normal)
	var sail_scale = 16
	ForceUtils.display_vector(
		self, sail_scale * sail_normal, transform.basis.y * 4, Color(0, 1, 0), "sail normal", 0.
	)
	ForceUtils.display_vector(
		self,
		sail_scale * sail_direction,
		transform.basis.y * 4,
		Color(1, 0, 0),
		"sail direction",
		0.
	)
	ForceUtils.display_vector(
		self, 8 * wind.wind_vector, transform.basis.y * 8, Color(0, 1, 1), "wind vector"
	)

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

	var keel_lift = -linear_velocity.project(transform.basis.z) * 4000
	var factor = 0.05

	ForceUtils.apply_and_display_force(
		self, wind_force, Vector3.ZERO, Color(1, 1, 0), "wind force", factor
	)
	ForceUtils.apply_and_display_force(
		self, keel_lift, Vector3.ZERO, Color(.9, .5, .1), "keel lift", factor
	)
	ForceUtils.display_vector(
		self, wind_force + keel_lift, Vector3.ZERO, Color(0., 1., 0.), "sum", factor
	)
	ForceUtils.apply_and_display_force(
		self,
		Vector3.DOWN * keel_weight,
		-10 * transform.basis.y,
		Color(.5, .1, .2),
		"keel weight",
		factor
	)

	submerged = false
	for p in probes:
		var depth = water.get_height(p.global_position) - p.global_position.y + 0.5
		if depth > 0:
			ForceUtils.apply_and_display_force(
				self,
				Vector3.UP * floating_force * gravity * pow(depth, 2),
				p.global_position - global_position,
				Color(1., 0, 1),
				"probe",
				0.
			)
			submerged = true

	var drag = -linear_velocity * linear_velocity.length() * water_drag
	ForceUtils.apply_and_display_force(self, drag, Vector3.ZERO, Color(0., 1., 0.5), "drag", .1)

	$Yaw.position = lerp($Yaw.position, position, 0.05)
	$WindArea.wind_force_magnitude = wind.wind_intensity * 20


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if submerged:
		state.angular_velocity *= water_angular_drag
