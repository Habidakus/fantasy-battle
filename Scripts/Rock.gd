class_name Rock extends Node2D

const rock_scene : PackedScene = preload("res://Scenes/rock.tscn")

var _points : PackedVector2Array
var _jcounter : JCounter = JCounter.Create("Rock")

const POINT_COUNT : int = 6
const RADIUS : float = 40

static func Create(rnd : RandomNumberGenerator, loc : Vector2i) -> Rock:
	var ret_val : Rock = rock_scene.instantiate() as Rock
	ret_val._initialize(rnd, loc)
	return ret_val

func _initialize(rnd : RandomNumberGenerator, loc : Vector2i):
	for i in range(POINT_COUNT):
		var angle : float = float(i) * 2 * PI / float(POINT_COUNT) + rnd.randf() * 2 * PI / float(3 * POINT_COUNT)
		var dist : float = (rnd.randf() + 0.5) * RADIUS
		_points.append(dist * Vector2.from_angle(angle))
	var poly : Polygon2D = find_child("Polygon2D") as Polygon2D
	poly.polygon = _points
	var mod_color : Color = poly.color
	mod_color.h += (rnd.randf() * 0.1 - 0.05)
	mod_color.s += (rnd.randf() * 0.1 - 0.05)
	mod_color.v += (rnd.randf() * 0.1 - 0.05)
	poly.color = mod_color
	position = loc
