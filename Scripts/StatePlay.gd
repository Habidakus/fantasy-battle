class_name StatePlay extends StateMachineState

@export var visible_squad_scene : PackedScene = preload("res://Scenes/visible_squad.tscn")
@export var turn_engine_scene : PackedScene = preload("res://Scenes/TurnEngine.tscn")

@export var wound_textures : Array[Texture2D]
@export var corpse_textures : Array[Texture2D]

var _turn_engine : TurnEngine
var _terrain_data : TerrainData = TerrainData.new()
var _ground_parallax_layer : ParallaxLayer
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

var _navigation_region : NavigationRegion2D

func _ready() -> void:
    _ground_parallax_layer = find_child("Parallax_Ground") as ParallaxLayer
    _mist_parallax_layer = find_child("Parallax_Mist") as ParallaxLayer
    _navigation_region = find_child("NavRegion") as NavigationRegion2D
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
    var squadsAndRadiiSquared : Array
    const rockRadiusSquared : float = Rock.VISUAL_RADIUS * Rock.VISUAL_RADIUS * 1.5 * 1.5
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
            var radiiSquared : float = s.GetRadiiSquared()
            squadsAndRadiiSquared.append([s.position, radiiSquared + rockRadiusSquared])
            var vs : VisibleSquad = visible_squad_scene.instantiate() as VisibleSquad
            _visible_squads[s.id] = vs
            add_child(vs)
            vs.Config(s._squad_type, army.GetPrimaryColor(), army.GetSecondaryColor())
            #print("%d: %s %s" % [ s.id, army.GetPrimaryColor(), army.GetSecondaryColor()])
            UpdateSquad(s)
    
    _terrain_data.Setup(rnd, squadsAndRadiiSquared, self, _navigation_region)
    _turn_engine.Config(_armies, _terrain_data, self, [])

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
        draw_line(entry[0], entry[1], entry[2], 3, true)
    _draw_queue.clear()
    #var nrnp : NavigationPolygon = _navigation_region.navigation_polygon
    #if nrnp != null:
        #var count : int = nrnp.get_polygon_count()
        #print("%s" % [count])

func _add_draw_line(p1 : Vector2, p2 : Vector2, color : Color) -> void:
    _draw_queue.append([p1, p2, color])
    queue_redraw()

func DrawEdge(id : int, edge : Array[Vector2], color : Color) -> void:
    if not _visible_squads.has(id):
        return
    var vs : VisibleSquad = _visible_squads[id]
    _add_draw_line(vs.position, (edge[0] + edge[1]) / 2.0, color)
    _add_draw_line(edge[0], edge[1], color)

func DrawPathLine(id1 : int, id2 : int, color : Color) -> void:
    if not _visible_squads.has(id1):
        return
    if not _visible_squads.has(id2):
        return
    var vs1 : VisibleSquad = _visible_squads[id1]
    var vs2 : VisibleSquad = _visible_squads[id2]
    var path : PackedVector2Array = _terrain_data.GetPath(vs1.position, vs2.position)
    for i in range(1, path.size()):
        _add_draw_line(path[i - 1], path[i], color)

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
