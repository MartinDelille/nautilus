extends RigidBody3D

#@export var floating_force := 10.6
@export var floating_force := 100.6
@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var boom:RigidBody3D=$boom

const ForceUtils = preload("res://force_utils.gd")

var probes = []


func _ready() -> void:
	for i in range(4):
		var probe = Marker3D.new()
		probe.name = "Marker3D_%d" % i
		add_child(probe)
		probes.append(probe)
	var size = $CollisionShape3D.shape.size
	var shift_x = $CollisionShape3D.shape.size.x / 2
	var shift_y = -$CollisionShape3D.shape.size.y * 0.5
	var shift_z = $CollisionShape3D.shape.size.z / 2
	probes[0].transform.origin = Vector3(shift_x, shift_y, shift_z)
	probes[1].transform.origin = Vector3(shift_x, shift_y, -shift_z)
	probes[2].transform.origin = Vector3(-shift_x, shift_y, shift_z)
	probes[3].transform.origin = Vector3(-shift_x, shift_y, -shift_z)


func _physics_process(delta: float) -> void:
	#prints(position.y)
	#var f = Vector3(0., -position.y * 200., 0.)
	#ForceUtils._apply_and_display_force(self, f)
	var i = 0
	for p in probes:
		i += 1
		var depth = -p.global_position.y + 0.5
		if depth > 0:
			ForceUtils._display_vector(self, p.position, Vector3.ZERO, Color(1, 0, 0), "pos %d" % i)
			ForceUtils._apply_and_display_force(
				self,
				Vector3.UP * floating_force * gravity * pow(depth, 2),
				p.position,  #- global_position,
				Color(1., 0, 1),
				"probe %d" %  i,
				true
			)
	#ForceUtils._apply_and_display_force(boom, Vector3.FORWARD*0.1, Vector3.LEFT, Color(0,1,0), "wind")
	boom.angular_velocity = boom.angular_velocity*0.1
	#ForceUtils._display_vector(boom, Vector3.FORWARD, Vector3.RIGHT*0.4 , Color(0,0,1), "wind2")
	#ForceUtils._apply_and_display_force(boom, Vector3.FORWARD*0.1, Vector3.RIGHT*2.9 , Color(0,0,1), "wind2", 10)
	
	var offset: float = (
		Input.get_axis("turn_left", "turn_right") 
	)
	ForceUtils._apply_and_display_force(boom,  boom.basis.z*0.1*offset, boom.basis.y, Color(1,1,0), "wind2", 10)
	#ForceUtils.
	#boom.apply_torque(Vector3.UP*0.1)
