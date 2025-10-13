class_name StatePlay extends StateMachineState

@export var squad_scene : PackedScene = preload("res://Scenes/squad.tscn")
@export var turn_engine_scene : PackedScene = preload("res://Scenes/TurnEngine.tscn")

var _turn_engine : TurnEngine
var _mist_parallax_layer : ParallaxLayer
var _mist_direction : float
var _mist_speed : float
const _mist_min_speed : float = 2.5
const _mist_max_speed : float = 15
var rnd : RandomNumberGenerator = RandomNumberGenerator.new()
var _armies : Array[Army]
# screen x: 20 to 1130
# screen y: 23 to 627

func _ready() -> void:
    _mist_parallax_layer = find_child("Parallax_Mist") as ParallaxLayer
    _mist_direction = rnd.randf() * 360.0
    _mist_speed = rnd.randf() * (_mist_max_speed - _mist_min_speed) + _mist_min_speed
    _turn_engine = turn_engine_scene.instantiate() as TurnEngine
    add_child(_turn_engine)

func enter_state() -> void:
    super.enter_state()

    _armies.append(Army.new())
    _armies[0].SetColor(Color.LIGHT_CYAN)
    _armies.append(Army.new())
    _armies[1].SetColor(Color.LIGHT_GOLDENROD)
    
    const squads_per_army : int = 3
    for army : Army in _armies:
        army.SetController(AIArmyController.new())
        var dy = 1 if army == _armies[0] else 7
        var rot : float = PI if army == _armies[0] else 0.0
        for i in range(squads_per_army):
            var s : Squad = squad_scene.instantiate()
            add_child(s)
            army.Add(s)
            var st : Squad.SquadType = Squad.SquadType.INFANTRY if i != 1 else Squad.SquadType.CAVALRY
            s.Initialize(army, 15, st, Squad.Formation.TRIPLELINE, rnd) # DOUBLELINE)
            s.position.x = 20 + (1 + i) * (1130 - 20) / float(squads_per_army + 1)
            s.position.y = 23 + (0 + dy) * (627 - 23) / 8.0
            s.rotation = rot
    _turn_engine.Config(_armies)
    
func _process(delta: float) -> void:
    _mist_direction += delta * ((rnd.randf() * 1) - 0.5)
    _mist_speed = clampf(_mist_speed + delta * ((rnd.randf() * 0.5)), _mist_min_speed, _mist_max_speed)
    _mist_parallax_layer.motion_offset.x += delta * _mist_speed * sin(_mist_direction)
    _mist_parallax_layer.motion_offset.y += delta * _mist_speed * cos(_mist_direction)
    pass
