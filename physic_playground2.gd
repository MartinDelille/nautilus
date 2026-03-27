extends Node3D

@onready var wind: Area3D = $WindArea
@onready var sail: SoftBody3D = $SailSoftBody3D

#func _process(delta: float) -> void:
#var offset: float = Input.get_axis("move_backward", "move_forward") * delta
#wind.wind_force_magnitude += offset
#prints(offset, wind.wind_force_magnitude)


func _ready() -> void:
	var mesh: Mesh = sail.mesh
	#if mesh is ArrayMesh:
	#var arrays = mesh.surface_get_arrays(0)
	#var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	#for i in range(vertices.size()):
	#var pos: Vector3 = vertices[i]
	#prints(i, ":",pos)
	#var should_pin: bool = pos.x == -0.5 or pos.y==-0.5
	#sail.set_point_pinned(i, should_pin)
	for index in range(100):
		var t = sail.get_point_transform(index)
		prints(index, ":", t)
		var is_pinned: bool = t.y == -0.5 or abs(t.y - 0.05555) < 0.0001
		#if(t.)
		sail.set_point_pinned(index, is_pinned)
	#for index in range(1000):
	#var is_pinned:bool =index in [2,3,25]
	#sail.set_point_pinned(index, false)
	#for index in [0, 1, 24, 25, 30, 31]:
	#sail.set_point_pinned(index, true)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_I:
				print("I key pressed")
				_update_wind_force(1.0)
			KEY_O:
				print("O key pressed")
				_update_wind_force(-1.0)


func _update_wind_force(offset: float) -> void:
	wind.wind_force_magnitude += offset
