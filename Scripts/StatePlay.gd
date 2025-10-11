class_name StatePlay extends StateMachineState

var _mist_parallax_layer : ParallaxLayer
var _mist_direction : float
var _mist_speed : float
const _mist_min_speed : float = 2.5
const _mist_max_speed : float = 15
var rnd : RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
    _mist_parallax_layer = find_child("Parallax_Mist") as ParallaxLayer
    _mist_direction = rnd.randf() * 360.0
    _mist_speed = rnd.randf() * (_mist_max_speed - _mist_min_speed) + _mist_min_speed
    
func _process(delta: float) -> void:
    _mist_direction += delta * ((rnd.randf() * 1) - 0.5)
    _mist_speed = clampf(_mist_speed + delta * ((rnd.randf() * 0.5)), _mist_min_speed, _mist_max_speed)
    _mist_parallax_layer.motion_offset.x += delta * _mist_speed * sin(_mist_direction)
    _mist_parallax_layer.motion_offset.y += delta * _mist_speed * cos(_mist_direction)
    pass
