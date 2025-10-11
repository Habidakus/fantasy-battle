class_name Squad extends Node2D

enum SquadType { INFANTRY, CAVALRY, ARTILLERY }
enum Formation { LINE, DOUBLELINE, TRIPLELINE, SQUARE, SKIRMISH, COLUMN }

var initial_size : float
var shape : Control
var icons : Node2D
var units : Array[Unit]
var formation : Formation = Formation.DOUBLELINE
var squadType : SquadType = SquadType.INFANTRY

static func CreateInfantry(count : int) -> Squad:
    var squad : Squad = Squad.new()
    squad.Initialize(count, SquadType.INFANTRY)
    return squad

func Initialize(count : int, st : SquadType) -> void:
    SetSquadType(st)
    for i in range(count):
        units.append(Unit.CreateInfantry())

func _ready() -> void:
    shape = find_child("ColorRect") as Control
    icons = find_child("Icons") as Node2D
    initial_size = shape.size.x

func _process(delta: float) -> void:
    if shape != null:
        shape.size = GetDim()
        shape.position = -shape.size / 2.0
        if icons != null:
            var icons_pos : float = min(-shape.position.x, -shape.position.y)
            icons.position = Vector2(-icons_pos, -icons_pos)
            var icons_scale : float = 2 * icons_pos / initial_size
            icons.scale = Vector2(icons_scale, icons_scale)

static func GetUnitDim(st : SquadType) -> Vector2:
    match st:
        SquadType.CAVALRY:
            return Vector2(10, 20)
        SquadType.INFANTRY:
            return Vector2(10, 10)
        SquadType.ARTILLERY:
            return Vector2(40, 40)
        _:
            assert(false, "GetUnitDim(" + str(st) + ")")
            return Vector2(10,10)

func GetDim() -> Vector2:
    var unit_dim : Vector2 = GetUnitDim(squadType)
    var unit_count : int = units.size()
    match formation:
        Formation.LINE:
            return Vector2(unit_dim.x * unit_count, unit_dim.y)
        Formation.DOUBLELINE:
            var ranks : int = 2
            var width : int = ceil(float(unit_count) / float(ranks))
            if ranks > width:
                var t = ranks
                ranks = width
                width = t
            return Vector2(unit_dim.x * width, unit_dim.y * ranks)
        Formation.TRIPLELINE:
            var ranks : int = 3
            var width : int = ceil(float(unit_count) / float(ranks))
            if ranks > width:
                var t = ranks
                ranks = width
                width = t
            return Vector2(unit_dim.x * width, unit_dim.y * ranks)
        Formation.SQUARE:
            var s : float = sqrt(unit_count)
            var ranks : int = floor(s)
            var width : int = ceil(s)
            if ranks * width < unit_count:
                ranks += 1
            return Vector2(unit_dim.x * width, unit_dim.y * ranks)
        Formation.SKIRMISH:
            var s : float = ceil(sqrt(unit_count))
            return Vector2(unit_dim.x * s * 1.5, unit_dim.y * s * 1.5)
        Formation.COLUMN:
            var width : int = ceil(pow(unit_count, 0.333))
            var ranks : int = ceil(unit_count / float(width))
            return Vector2(unit_dim.x * width, unit_dim.y * ranks)
        _:
            assert(false, "GetDim() with unknown formation: " + str(formation))
            return unit_dim * sqrt(unit_count)

func SetSquadType(st : SquadType) -> void:
    squadType = st
    var cavalryIcon = find_child("Cavalry") as Line2D
    var artilleryIcon = find_child("Artillery") as Line2D
    var infantryIcon = find_child("Infantry") as Line2D
    match squadType:
        SquadType.CAVALRY:
            cavalryIcon.show()
            infantryIcon.hide()
            artilleryIcon.hide()
        SquadType.INFANTRY:
            cavalryIcon.show()
            infantryIcon.show()
            artilleryIcon.hide()
        SquadType.ARTILLERY:
            cavalryIcon.hide()
            infantryIcon.hide()
            artilleryIcon.show()
            
