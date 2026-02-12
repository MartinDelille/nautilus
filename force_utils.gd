static var debug = OS.is_debug_build()

static var font_size = 18

static func set_font_size(size):
	font_size=size
	
static func _display_vector(
	target: Node3D,
	v: Vector3,
	where := Vector3.ZERO,
	color := Color(1., 1., 1.),
	text: String = "",
	factor:=1.
):
	if debug and factor>0.:
		var p = target.global_position
		DebugDraw3D.draw_arrow(p + where, p + where + v*factor , color, 0.1)
		DebugDraw3D.draw_text(p + where + v*factor * 0.5, "%s x%.2f" % [text, factor], font_size, color)

static func _display_quaternion(q: Quaternion, where := Vector3.ZERO, color := Color(1., 1., 0.)):
	var v := Vector3(q.x, q.y, q.z) * q.get_angle() * 100
	#_display_vector(v, where, color)


static func _apply_and_display_force(
	target: Node3D,
	force: Vector3,
	where := Vector3.ZERO,
	color := Color(1., 0., 1.),
	text := "",
	factor := 1.,
):
	target.apply_force(force,  where)
	_display_vector(target, force ,  where, color, text, factor)
