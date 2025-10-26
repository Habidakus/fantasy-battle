class_name Rock extends Node2D

const rock_scene : PackedScene = preload("res://Scenes/rock.tscn")

var _visual_points : PackedVector2Array
var _collision_points : PackedVector2Array
#var _jcounter : JCounter = JCounter.Create("Rock")

const POINT_COUNT : int = 6
const VISUAL_RADIUS : float = 40
const COLLISION_RADIUS_ADDITION : float = 30

static func Create(rnd : RandomNumberGenerator, loc : Vector2i) -> Rock:
    var ret_val : Rock = rock_scene.instantiate() as Rock
    ret_val._initialize(rnd, loc)
    return ret_val

static func CreateFromPolygon(points : PackedVector2Array, rnd : RandomNumberGenerator) -> Rock:
    var total : Vector2 = Vector2.ZERO
    for p : Vector2 in points:
        total += p
    var center_point : Vector2 = total / float(points.size())
    var ret_val : Rock = rock_scene.instantiate() as Rock
    ret_val._points.clear()
    for p : Vector2 in points:
        ret_val._points.append(p - center_point)
    ret_val.position = center_point
    ret_val._assign_points_to_polygon(rnd)
    return ret_val

const MAX_RADII : float = VISUAL_RADIUS * 1.5 + COLLISION_RADIUS_ADDITION
const MAX_RADII_SQUARED : float = MAX_RADII * MAX_RADII
func GetCollisionRadiiSquared() -> float:
    return MAX_RADII_SQUARED

func GetMapPoints_Visual() -> PackedVector2Array:
    var ret_val : PackedVector2Array
    for p : Vector2 in _visual_points:
        ret_val.append(position + p)
    return ret_val

func GetMapPoints_Collision() -> PackedVector2Array:
    var ret_val : PackedVector2Array
    for p : Vector2 in _collision_points:
        ret_val.append(position + p)
    return ret_val

func _initialize(rnd : RandomNumberGenerator, loc : Vector2i):
    for i in range(POINT_COUNT):
        var angle : float = float(i) * 2 * PI / float(POINT_COUNT) + rnd.randf() * 2 * PI / float(3 * POINT_COUNT)
        var dist : float = (rnd.randf() + 0.5) * VISUAL_RADIUS
        _visual_points.append(dist * Vector2.from_angle(angle))
        _collision_points.append((dist + COLLISION_RADIUS_ADDITION) * Vector2.from_angle(angle))
    _assign_points_to_polygon(rnd)
    position = loc

func _assign_points_to_polygon(rnd : RandomNumberGenerator) -> void:
    var poly : Polygon2D = find_child("Polygon2D") as Polygon2D
    poly.polygon = _visual_points
    _assign_color(poly, rnd)

func _assign_color(poly : Polygon2D, rnd : RandomNumberGenerator) -> void:
    var mod_color : Color = poly.color
    mod_color.h += (rnd.randf() * 0.1 - 0.05)
    mod_color.s += (rnd.randf() * 0.1 - 0.05)
    mod_color.v += (rnd.randf() * 0.1 - 0.05)
    poly.color = mod_color
