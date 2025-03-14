@tool
extends Node

const TILE_WIDTH = 100
const TILE_INDICES = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]

var OceanTile = preload("res://water_scene.tscn")
var spawn_point = preload("res://grid_spawn_info.tres")
var water_material = load("res://water_material.tres")
var tiles = {}
var time: float

@onready var wave_angle1 = water_material.get_shader_parameter("angle1")
@onready var wave_stepness1 = water_material.get_shader_parameter("stepness1")
@onready var wave_length1 = water_material.get_shader_parameter("wavelength1")

@onready var wave_angle2 = water_material.get_shader_parameter("angle2")
@onready var wave_stepness2 = water_material.get_shader_parameter("stepness2")
@onready var wave_length2 = water_material.get_shader_parameter("wavelength2")

@onready var wave_angle3 = water_material.get_shader_parameter("angle3")
@onready var wave_stepness3 = water_material.get_shader_parameter("stepness3")
@onready var wave_length3 = water_material.get_shader_parameter("wavelength3")

@onready var camera = $"../FloatingBoat/Yaw/Pitch/Camera3D"


func create_ocean_tiles():
	for i in TILE_INDICES:
		var spawn_location = spawn_point.spawn_points[i]
		var tile_subdivision = spawn_point.subdivision[i]
		var tile_scale = spawn_point.scale[i]
		var tile = OceanTile.instantiate()

		tiles[i] = tile
		add_child(tile)

		tile.position = Vector3(spawn_location.x, 0.0, spawn_location.y) * TILE_WIDTH
		var new_mesh = tile.mesh.duplicate()
		tile.mesh = new_mesh
		tile.mesh.set_subdivide_width(tile_subdivision)
		tile.mesh.set_subdivide_depth(tile_subdivision)
		tile.mesh.set_size(Vector2(TILE_WIDTH * tile_scale, TILE_WIDTH * tile_scale))


func _ready() -> void:
	create_ocean_tiles()


func _process(delta: float) -> void:
	time += delta
	water_material.set_shader_parameter("wave_time", time)
	var camera_scale = camera.position.z / 10
	water_material.set_shader_parameter("clamp_distance", camera_scale * TILE_WIDTH)
	if tiles.size() == TILE_INDICES.size():
		for i in TILE_INDICES:
			var tile = tiles[i]
			var spawn_location = spawn_point.spawn_points[i]
			var tile_scale = spawn_point.scale[i] * camera_scale
			tile.position = (
				Vector3(spawn_location.x, 0.0, spawn_location.y) * TILE_WIDTH * camera_scale
			)
			tile.mesh.set_size(Vector2(TILE_WIDTH * tile_scale, TILE_WIDTH * tile_scale))


func gerstner_wave_height(p: Vector2, angle: float, stepness: float, wavelength: float):
	var k = TAU / wavelength
	var c = sqrt(9.81 / k)
	var d = Vector2(cos(angle), sin(angle))
	var f = k * (d.dot(p) - c * time)
	var a = stepness / k
	return a * sin(f)


func get_height(world_position: Vector3) -> float:
	var p = Vector2(world_position.x, world_position.z)
	var height = 0
	height += gerstner_wave_height(p, wave_angle1, wave_stepness1, wave_length1)
	height += gerstner_wave_height(p, wave_angle2, wave_stepness2, wave_length2)
	height += gerstner_wave_height(p, wave_angle3, wave_stepness3, wave_length3)
	return height
