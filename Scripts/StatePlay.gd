class_name StatePlay extends StateMachineState

@export var visible_squad_scene : PackedScene = preload("res://Scenes/visible_squad.tscn")
@export var turn_engine_scene : PackedScene = preload("res://Scenes/TurnEngine.tscn")

@export var wound_textures : Array[Texture2D]
@export var corpse_textures : Array[Texture2D]

var _turn_engine : TurnEngine
var _ground_parallax_layer : ParallaxLayer
var _mist_parallax_layer : ParallaxLayer
var _mist_direction : float
var _mist_speed : float
const _mist_min_speed : float = 2.5
const _mist_max_speed : float = 15
var rnd : RandomNumberGenerator = RandomNumberGenerator.new()
var _armies : Array[Army]
var _visible_squads : Dictionary = {}
var _rocks : Array[Rock]
# screen x: 20 to 1130
# screen y: 23 to 627

func _ready() -> void:
	_ground_parallax_layer = find_child("Parallax_Ground") as ParallaxLayer
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
			s.Initialize(army, 15, st, Squad.Formation.DOUBLELINE, rnd)
			s.position.x = 20 + (1 + i) * (1130 - 20) / float(squads_per_army + 1)
			s.position.y = 23 + (0 + dy) * (627 - 23) / 8.0
			s.rotation = rot
			var vs : VisibleSquad = visible_squad_scene.instantiate() as VisibleSquad
			_visible_squads[s.id] = vs
			add_child(vs)
			vs.Config(s._squad_type, army.GetPrimaryColor(), army.GetSecondaryColor())
			#print("%d: %s %s" % [ s.id, army.GetPrimaryColor(), army.GetSecondaryColor()])
			UpdateSquad(s)
	
	_place_terrain()
	
	_turn_engine.Config(_armies, _rocks, self, [])

func _place_terrain() -> void:
	var poss : Array = []
	for r : int in range(25):
		var loc : Vector2i
		var close_to_squad : bool = true
		while close_to_squad:
			loc = Vector2i(rnd.randi() % 1150, rnd.randi() % 600)
			close_to_squad = false
			for army : Army in _armies:
				for squad : Squad in army._squads:
					if squad.position.distance_squared_to(loc) < (75 * 75):
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
		add_child(rock)
		_rocks.append(rock)

func UpdateSquad(squad : Squad) -> void:
	if not _visible_squads.has(squad.id):
		assert(false, str(squad) + " has no visible component")
		return
	_visible_squads[squad.id].Update(squad)
	#DebugDrawSquad(squad)

var _draw_queue : Array
func _draw() -> void:
	for entry : Array in _draw_queue:
		# point, point, color
		draw_line(entry[0], entry[1], entry[2], 10, true)
	_draw_queue.clear()

func DebugDrawSquad(squad : Squad) -> void:
	var outline : Array = squad.GetOutline()
	for entry in outline:
		_draw_queue.append(entry)
	queue_redraw()

func HideSquadBecauseTheyAreDead(id : int) -> void:
	if not _visible_squads.has(id):
		assert(false, "Squad#%s has no visible component" % [id])
		return
	var vs : VisibleSquad = _visible_squads[id]
	vs.hide()
	
func UpdateSquadHealth(old_squad_stats : Squad, new_squad_stats : Squad) -> void:
	var bodies_to_place : int = old_squad_stats._units_wounded - new_squad_stats._units_wounded
	var wounds_to_place : int = old_squad_stats._units_healthy - new_squad_stats._units_healthy 
	for i in range(wounds_to_place):
		var spot : Vector2 = new_squad_stats.GetWoundLocation(rnd)
		var wound_sprite : Sprite2D = Sprite2D.new()
		wound_sprite.texture = wound_textures[rnd.randi() % wound_textures.size()] 
		wound_sprite.position = spot
		wound_sprite.rotation = rnd.randf() * 2.0 * PI
		_ground_parallax_layer.add_child(wound_sprite)
	for i in range(bodies_to_place):
		var spot : Vector2 = new_squad_stats.GetWoundLocation(rnd)
		var corpse_sprite : Sprite2D = Sprite2D.new()
		corpse_sprite.texture = corpse_textures[rnd.randi() % corpse_textures.size()] 
		corpse_sprite.position = spot
		corpse_sprite.rotation = rnd.randf() - 0.5
		_ground_parallax_layer.add_child(corpse_sprite)

func _process(delta: float) -> void:
	_mist_direction += delta * ((rnd.randf() * 1) - 0.5)
	_mist_speed = clampf(_mist_speed + delta * ((rnd.randf() * 0.5)), _mist_min_speed, _mist_max_speed)
	_mist_parallax_layer.motion_offset.x += delta * _mist_speed * sin(_mist_direction)
	_mist_parallax_layer.motion_offset.y += delta * _mist_speed * cos(_mist_direction)
	pass
