@tool
extends Node

var OceanTile = preload("res://water_scene.tscn")
var spawn_point = preload("res://grid_spawn_info.tres")
var water_material = preload("res://water_material.tres")

var time: float
@onready var wave_angle = water_material.get_shader_parameter("wave_angle")
@onready var wave_frequency = water_material.get_shader_parameter("wave_frequency")
@onready var wave_amplitude = water_material.get_shader_parameter("wave_amplitude")
@onready var wave_speed = water_material.get_shader_parameter("wave_speed")
@onready var height_scale = water_material.get_shader_parameter("height_scale")


func create_ocean_tiles():
	for i in 17:
		var spawn_location = spawn_point.spawn_points[i]
		var tile_subdivision = spawn_point.subdivision[i]
		var tile_scale = spawn_point.scale[i]
		var instance = OceanTile.instantiate()

		add_child(instance)

		instance.position = Vector3(spawn_location.x, 0.0, spawn_location.y) * 100.5
		var new_mesh = instance.mesh.duplicate()
		instance.mesh = new_mesh
		instance.mesh.set_subdivide_width(tile_subdivision)
		instance.mesh.set_subdivide_depth(tile_subdivision)
		instance.set_scale(Vector3(tile_scale, 1.0, tile_scale))


func _ready() -> void:
	create_ocean_tiles()


func _process(delta: float) -> void:
	time += delta
	water_material.set_shader_parameter("wave_time", time)


func get_height(world_position: Vector3) -> float:
	var wave_direction = Vector2(cos(wave_angle), sin(wave_angle))
	var pos = Vector2(world_position.x, world_position.z) * wave_direction
	return sin(pos.dot(wave_direction) * wave_frequency + time * wave_speed) * wave_amplitude
