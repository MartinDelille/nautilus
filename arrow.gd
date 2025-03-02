extends Node3D

@export var arrow_color: Color = Color(1, 1, 1, 1):
	set(value):
		arrow_color = value
		update_materials()


func _ready():
	update_materials()


func update_materials():
	for mesh in [$ShaftMesh, $HeadMesh]:
		var mesh_material: StandardMaterial3D = null
		if mesh.material_override:
			mesh_material = mesh.material_override as StandardMaterial3D
		else:
			mesh_material = StandardMaterial3D.new()
			mesh.material_override = mesh_material
		mesh_material.albedo_color = arrow_color
