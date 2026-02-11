static var debug = OS.is_debug_build()


static func _display_vector(
	target: Node3D,
	v: Vector3,
	where := Vector3.ZERO,
	color := Color(1., 1., 1.),
	text: String = "",
):
	if debug:
		var p = target.position
		DebugDraw3D.draw_arrow(p + where, p + where + v * 0.2, color, 0.1)
		DebugDraw3D.draw_text(p + where + v * 0.1, text, 128, color)


static func _display_quaternion(q: Quaternion, where := Vector3.ZERO, color := Color(1., 1., 0.)):
	var v := Vector3(q.x, q.y, q.z) * q.get_angle() * 100
	#_display_vector(v, where, color)


static func _apply_and_display_force(
	target: Node3D,
	force: Vector3,
	where := Vector3.ZERO,
	color := Color(1., 0., 1.),
	text := "",
	display_vector := true,
):
	target.apply_force(force, target.global_position + where)
	if display_vector:
		_display_vector(target, force, target.global_position + where, color, text)
