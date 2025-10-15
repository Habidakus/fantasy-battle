class_name StatePlay extends StateMachineState

@export var visible_squad_scene : PackedScene = preload("res://Scenes/visible_squad.tscn")
@export var turn_engine_scene : PackedScene = preload("res://Scenes/TurnEngine.tscn")

var _turn_engine : TurnEngine
var _mist_parallax_layer : ParallaxLayer
var _mist_direction : float
var _mist_speed : float
const _mist_min_speed : float = 2.5
const _mist_max_speed : float = 15
var rnd : RandomNumberGenerator = RandomNumberGenerator.new()
var _armies : Array[Army]
var _visible_squads : Dictionary = {}
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
	_armies[0].SetColor(Color.RED)
	_armies.append(Army.new())
	_armies[1].SetColor(Color.BLUE)
	
	const squads_per_army : int = 3
	for army : Army in _armies:
		army.SetController(AIArmyController.new())
		var dy = 1 if army == _armies[0] else 7
		var rot : float = PI / 2.0 if army == _armies[0] else 3.0 * PI / 2.0
		for i in range(squads_per_army):
			var s : Squad = Squad.new()
			army.Add(s)
			var st : Squad.SquadType = Squad.SquadType.INFANTRY if i != 1 else Squad.SquadType.CAVALRY
			s.Initialize(army, 15, st, Squad.Formation.TRIPLELINE, rnd) # DOUBLELINE)
			s.position.x = 20 + (1 + i) * (1130 - 20) / float(squads_per_army + 1)
			s.position.y = 23 + (0 + dy) * (627 - 23) / 8.0
			s.rotation = rot
			var vs : VisibleSquad = visible_squad_scene.instantiate() as VisibleSquad
			_visible_squads[s.id] = vs
			add_child(vs)
			vs.Config(s._squad_type, army.GetPrimaryColor(), army.GetSecondaryColor())
			#print("%d: %s %s" % [ s.id, army.GetPrimaryColor(), army.GetSecondaryColor()])
			UpdateSquad(s)
	_turn_engine.Config(_armies, self)

func UpdateSquad(squad : Squad) -> void:
	if not _visible_squads.has(squad.id):
		assert(false, str(squad) + " has no visible component")
		return
	_visible_squads[squad.id].Update(squad)
	
func _process(delta: float) -> void:
	_mist_direction += delta * ((rnd.randf() * 1) - 0.5)
	_mist_speed = clampf(_mist_speed + delta * ((rnd.randf() * 0.5)), _mist_min_speed, _mist_max_speed)
	_mist_parallax_layer.motion_offset.x += delta * _mist_speed * sin(_mist_direction)
	_mist_parallax_layer.motion_offset.y += delta * _mist_speed * cos(_mist_direction)
	pass
