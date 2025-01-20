extends MeshInstance3D

var time: float
@onready var material = get_surface_override_material(0)
@onready var wave_angle = material.get_shader_parameter("wave_angle")
@onready var wave_frequency = material.get_shader_parameter("wave_frequency")
@onready var wave_amplitude = material.get_shader_parameter("wave_amplitude")
@onready var wave_speed = material.get_shader_parameter("wave_speed")
@onready var height_scale = material.get_shader_parameter("height_scale")


func _process(delta: float) -> void:
	time += delta
	material.set_shader_parameter("wave_time", time)


func get_height(world_position: Vector3) -> float:
	var wave_direction = Vector2(cos(wave_angle), sin(wave_angle))
	var pos = Vector2(world_position.x, world_position.z) * wave_direction
	return sin(pos.dot(wave_direction) * wave_frequency + time * wave_speed) * wave_amplitude
