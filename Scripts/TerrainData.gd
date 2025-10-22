class_name TerrainData extends RefCounted

var _rocks : Array[Rock]

func Setup(rnd : RandomNumberGenerator, squadsAndRadiiSquared : Array, parent : Control) -> void:
	var poss : Array = []
	for r : int in range(25):
		var loc : Vector2i
		var close_to_squad : bool = true
		while close_to_squad:
			loc = Vector2i(rnd.randi() % 1150, rnd.randi() % 600)
			close_to_squad = false
			for sar : Array in squadsAndRadiiSquared:
				if sar[0].distance_squared_to(loc) < sar[1]:
					close_to_squad = true
		poss.append([loc, -1])
	for r1 : int in range(25):
		var p1 : Vector2i = poss[r1][0]
		var mind : int = 1135 * 1135 * 2
		for r2 : int in range(25):
			if r1 == r2:
				continue
			var p2 : Vector2i = poss[r2][0]
			var d : int = p1.distance_squared_to(p2)
			if d < mind:
				mind = d
		poss[r1][1] = mind
		
	poss.sort_custom(func(a,b) : return a[1] < b[1])
	for r : int in range(8):
		var rock : Rock = Rock.Create(rnd, poss[r][0])
		_rocks.append(rock)
		parent.add_child(rock)

func CheckForCollision(points : Array[Vector2], dest_points : Array[Vector2]) -> float:
	var shortened_length : float = 1130 * 1130 + 600 * 600
	var point_count : int = points.size()
	for rock : Rock in _rocks:
		var rock_point_count : int = rock._points.size()
		for rock_point_index : int in range(rock_point_count):
			var rp1 : Vector2 = rock._points[rock_point_index] + rock.position
			var rp2 : Vector2 = rock._points[(rock_point_index + 1) % rock_point_count] + rock.position
			for point_index in range(point_count):
				var hit_point = Geometry2D.segment_intersects_segment(points[point_index], dest_points[point_index], rp1, rp2)
				if hit_point != null:
					var new_length : float = (hit_point - points[point_index]).length()
					if new_length < shortened_length:
						shortened_length = new_length
	return shortened_length
