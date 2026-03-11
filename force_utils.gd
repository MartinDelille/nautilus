static var debug = OS.is_debug_build()

static var font_size = 18


static func set_font_size(size_2d, size_3d):
	DebugDraw2D.config.text_default_size = size_2d
	font_size = size_3d


static func display_vector(
	target: Node3D,
	v: Vector3,
	where := Vector3.ZERO,
	color := Color(1., 1., 1.),
	text: String = "",
	factor := 1.
):
	if debug and factor > 0.:
		var p = target.global_position
		if (v * factor).length() > 0.:
			DebugDraw3D.draw_arrow(p + where, p + where + v * factor, color, 0.1)
		DebugDraw3D.draw_text(
			p + where + v * factor * 0.5,
			"%s = %.2f (x%.2f)" % [text, v.length(), factor],
			font_size,
			color
		)


static func display_quaternion(
	target: Node3D, q: Quaternion, where := Vector3.ZERO, color := Color(1., 1., 0.)
):
	var v := Vector3(q.x, q.y, q.z) * q.get_angle() * 100
	display_vector(target, v, where, color)


static func apply_and_display_force(
	target: Node3D,
	force: Vector3,
	where := Vector3.ZERO,
	color := Color(1., 0., 1.),
	text := "",
	factor := 1.,
):
	target.apply_force(force, where)
	display_vector(target, force, where, color, text, factor)
