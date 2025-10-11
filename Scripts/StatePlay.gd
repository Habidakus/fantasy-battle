class_name StatePlay extends StateMachineState

@export var squad_scene : PackedScene = preload("res://Scenes/squad.tscn")

var _mist_parallax_layer : ParallaxLayer
var _mist_direction : float
var _mist_speed : float
const _mist_min_speed : float = 2.5
const _mist_max_speed : float = 15
var rnd : RandomNumberGenerator = RandomNumberGenerator.new()

# screen x: 20 to 1130
# screen y: 23 to 627

func _ready() -> void:
    _mist_parallax_layer = find_child("Parallax_Mist") as ParallaxLayer
    _mist_direction = rnd.randf() * 360.0
    _mist_speed = rnd.randf() * (_mist_max_speed - _mist_min_speed) + _mist_min_speed
    const total : int = 6
    for i in range(total):
        var s : Squad = squad_scene.instantiate()
        s.Initialize(15, Squad.SquadType.INFANTRY)
        s.position.x = 20 + (1 + i) * (1130 - 20) / float(total + 2)
        s.position.y = 23 + (1 + i) * (627 - 23) / float(total + 2)
        match i:
            0:
                s.formation = Squad.Formation.LINE
            1:
                s.formation = Squad.Formation.DOUBLELINE
            2:
                s.formation = Squad.Formation.TRIPLELINE
            3:
                s.formation = Squad.Formation.SQUARE
            4:
                s.formation = Squad.Formation.SKIRMISH
            5:
                s.formation = Squad.Formation.COLUMN
        add_child(s)
    
func _process(delta: float) -> void:
    _mist_direction += delta * ((rnd.randf() * 1) - 0.5)
    _mist_speed = clampf(_mist_speed + delta * ((rnd.randf() * 0.5)), _mist_min_speed, _mist_max_speed)
    _mist_parallax_layer.motion_offset.x += delta * _mist_speed * sin(_mist_direction)
    _mist_parallax_layer.motion_offset.y += delta * _mist_speed * cos(_mist_direction)
    pass
