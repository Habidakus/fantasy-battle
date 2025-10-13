class_name Squad extends Node2D

static var s_NEXT_ID : int = 0

enum DamageType { MELEE, CHARGE, MISSLE, ARTILLERY }
enum SquadType { INFANTRY, CAVALRY, ARTILLERY }
enum Formation { LINE, DOUBLELINE, TRIPLELINE, SQUARE, SKIRMISH, COLUMN }
# Line - maximum damage dealt, maximum damage taken from melee and missile
# Double line - slightly increased missile & artillery taken
# Triple line - increased missile & artillery taken
# Square - no flanking vulnerability, extra damage from missile and artillery
# Skirmish - increased melee damage taken, reduced missile and artillery damage taken
# Column - Extra movement, reduced damage dealt from melee and missile, extra damage from artillery

var id : int
var _turn_order_tie_breaker : float
var _next_move : float
var _army : Army
var _speed : float = 30
var _units_healthy : int
var _units_wounded : int
var initial_size : float
var shape : ColorRect
var icons : Node2D
var _formation : Formation = Formation.DOUBLELINE
var _squad_type : SquadType = SquadType.INFANTRY

func Clone() -> Squad:
    var ret_val : Squad = Squad.new()
    ret_val._turn_order_tie_breaker = _turn_order_tie_breaker
    ret_val._next_move = _next_move
    ret_val._army = _army
    ret_val._speed = _speed
    ret_val._units_healthy = _units_healthy
    ret_val._units_wounded = _units_wounded
    ret_val._formation = _formation
    ret_val._squad_type = _squad_type
    ret_val.id = id
    return ret_val

func GetArmy() -> Army:
    return _army

func GetUnits() -> int:
    return _units_healthy + _units_wounded

func IsDead() -> bool:
    return _units_healthy + _units_wounded == 0

func GetChargeDistance() -> float:
    # TODO: Charge distance should change by formation & squad type
    return _speed

func CanCharge(enemy : Squad) -> bool:
    # TODO: Add cost to turn towards closest spot on enemy
    return enemy.position.distance_to(position) < GetChargeDistance()

func GetSortedMoves(game_state : GameState) -> Array[MMCAction]:
    # ArmyControllerAction
    var ret_val : Array[MMCAction]
    if game_state.IsInCombat(self):
        ret_val.append(ArmyControllerAction.CreateMelee(self))
    else:
        ret_val.append(ArmyControllerAction.CreatePass(self))
        for enemy : Squad in game_state.GetAllChargableEnemy(self):
            ret_val.append(ArmyControllerAction.CreateCharge(self, enemy))
    return ret_val

static func CalculateDieMods(attacker : Formation, defender : Formation, damageType : DamageType) -> Vector2i:
    match damageType:
        DamageType.MELEE:
            return Vector2i(CalculateDieMods_AttackerIsMelee(attacker), CalculateDieMods_DefenderAgainstMelee(defender))
        DamageType.CHARGE:
            return Vector2i(CalculateDieMods_AttackerIsCharge(attacker), CalculateDieMods_DefenderAgainstCharge(defender))
        DamageType.MISSLE:
            return Vector2i(CalculateDieMods_AttackerIsMissile(attacker), CalculateDieMods_DefenderAgainstMissile(defender))
        DamageType.ARTILLERY:
            return Vector2i(CalculateDieMods_AttackerIsArtillery(attacker), CalculateDieMods_DefenderAgainstArtillery(defender))
        _:
            assert(false, "Unknown Damage Type: " + str(damageType))
            return Vector2i(0, 0)

func GetDieCountInAttack(damageType : DamageType) -> int:
    match damageType:
        DamageType.MELEE:
            return GetDieCountInAttack_Melee()
        DamageType.CHARGE:
            return GetDieCountInAttack_Charge()
        DamageType.MISSLE:
            return GetDieCountInAttack_Missile()
        DamageType.ARTILLERY:
            return GetDieCountInAttack_Artillery()
        _:
            assert(false)
            return 0

func GetDieCountInAttack_Melee() -> int:
    var widthAndRanks : Vector2i = GetWidthAndRanks()
    match _formation:
        Formation.LINE:
            return widthAndRanks.x
        Formation.DOUBLELINE:
            return int(ceil(min(float(GetUnits()), widthAndRanks.x * 1.5)))
        Formation.TRIPLELINE:
            return min(GetUnits(), widthAndRanks.x * 2)
        Formation.SQUARE:
            return widthAndRanks.x
        Formation.SKIRMISH:
            return widthAndRanks.x
        Formation.COLUMN:
            return widthAndRanks.x
        _:
            assert(false)
            return 0

func GetDieCountInAttack_Charge() -> int:
    var widthAndRanks : Vector2i = GetWidthAndRanks()
    match _formation:
        Formation.LINE:
            return widthAndRanks.x
        Formation.DOUBLELINE:
            return min(GetUnits(), widthAndRanks.x * 2)
        Formation.TRIPLELINE:
            return min(GetUnits(), widthAndRanks.x * 3)
        Formation.SQUARE:
            return widthAndRanks.x
        Formation.SKIRMISH:
            return widthAndRanks.x
        Formation.COLUMN:
            return min(GetUnits(), widthAndRanks.x * 3)
        _:
            assert(false)
            return 0

func GetDieCountInAttack_Missile() -> int:
    if _formation == Formation.COLUMN:
        return min(GetUnits(), GetWidthAndRanks().x * 3)
    else:
        return GetUnits()
        
func GetDieCountInAttack_Artillery() -> int:
    if _formation == Formation.LINE || _formation == Formation.SKIRMISH:
        return GetUnits()
    else:
        return GetWidthAndRanks().x

static func CalculateDieMods_AttackerIsMissile(attacker : Formation) -> int:
    match attacker:
        Formation.LINE:
            return 1
        Formation.DOUBLELINE:
            return 0
        Formation.TRIPLELINE:
            return 0
        Formation.SQUARE:
            return -1
        Formation.SKIRMISH:
            return 1
        Formation.COLUMN:
            return -1
        _:
            assert(false)
            return 0
static func CalculateDieMods_DefenderAgainstMissile(defender : Formation) -> int:
    match defender:
        Formation.LINE:
            return 0
        Formation.DOUBLELINE:
            return -1
        Formation.TRIPLELINE:
            return -1
        Formation.SQUARE:
            return -1
        Formation.SKIRMISH:
            return 2
        Formation.COLUMN:
            return -1
        _:
            assert(false)
            return 0
static func CalculateDieMods_AttackerIsArtillery(attacker : Formation) -> int:
    match attacker:
        Formation.LINE:
            return 1
        Formation.DOUBLELINE:
            return -1
        Formation.TRIPLELINE:
            return -2
        Formation.SQUARE:
            return -2
        Formation.SKIRMISH:
            return 1
        Formation.COLUMN:
            return -2
        _:
            assert(false)
            return 0
static func CalculateDieMods_DefenderAgainstArtillery(defender : Formation) -> int:
    match defender:
        Formation.LINE:
            return 1
        Formation.DOUBLELINE:
            return 0
        Formation.TRIPLELINE:
            return 0
        Formation.SQUARE:
            return -1
        Formation.SKIRMISH:
            return 2
        Formation.COLUMN:
            return -2
        _:
            assert(false)
            return 0

static func CalculateDieMods_AttackerIsCharge(attacker : Formation) -> int:
    match attacker:
        Formation.LINE:
            return 1
        Formation.DOUBLELINE:
            return 1
        Formation.TRIPLELINE:
            return 1
        Formation.SQUARE:
            return -1
        Formation.SKIRMISH:
            return -1
        Formation.COLUMN:
            return 1
        _:
            assert(false)
            return 0
static func CalculateDieMods_DefenderAgainstCharge(defender : Formation) -> int:
    match defender:
        Formation.LINE:
            return -1
        Formation.DOUBLELINE:
            return 0
        Formation.TRIPLELINE:
            return 1
        Formation.SQUARE:
            return 1
        Formation.SKIRMISH:
            return -2
        Formation.COLUMN:
            return 1
        _:
            assert(false)
            return 0
static func CalculateDieMods_AttackerIsMelee(attacker : Formation) -> int:
    match attacker:
        Formation.LINE:
            return 1
        Formation.DOUBLELINE:
            return 0
        Formation.TRIPLELINE:
            return 0
        Formation.SQUARE:
            return -1
        Formation.SKIRMISH:
            return -1
        Formation.COLUMN:
            return -1
        _:
            assert(false)
            return 0
static func CalculateDieMods_DefenderAgainstMelee(defender : Formation) -> int:
    match defender:
        Formation.LINE:
            return -1
        Formation.DOUBLELINE:
            return 0
        Formation.TRIPLELINE:
            return 0
        Formation.SQUARE:
            return 0
        Formation.SKIRMISH:
            return -1
        Formation.COLUMN:
            return 0
        _:
            assert(false)
            return 0

# s.Initialize(army, 15, Squad.SquadType.INFANTRY, Squad.Formation.DOUBLELINE)
func Initialize(army : Army, count : int, st : SquadType, form : Formation, rnd : RandomNumberGenerator) -> void:
    _army = army
    SetSquadType(st)
    SetFormation(form)
    _turn_order_tie_breaker = rnd.randf()
    _next_move = 0
    shape.color = army.GetColor()
    _units_healthy = count
    _units_wounded = 0
    s_NEXT_ID += 1
    id = s_NEXT_ID

func GetNextMove() -> float:
    return _next_move

func _ready() -> void:
    shape = find_child("ColorRect") as ColorRect
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

func GetWidthAndRanks() -> Vector2i:
    var unit_dim : Vector2 = GetUnitDim(_squad_type)
    match _formation:
        Formation.LINE:
            return Vector2i(GetUnits(), 1)
        Formation.DOUBLELINE:
            var ranks : int = 2
            var width : int = ceil(float(GetUnits()) / float(ranks))
            if ranks > width:
                var t = ranks
                ranks = width
                width = t
            return Vector2i(width, ranks)
        Formation.TRIPLELINE:
            var ranks : int = 3
            var width : int = ceil(float(GetUnits()) / float(ranks))
            if ranks > width:
                var t = ranks
                ranks = width
                width = t
            return Vector2i(width, ranks)
        Formation.SQUARE:
            var s : float = sqrt(GetUnits())
            var ranks : int = floor(s)
            var width : int = ceil(s)
            if ranks * width < GetUnits():
                ranks += 1
            return Vector2i(width, ranks)
        Formation.SKIRMISH:
            var s : int = int(ceil(sqrt(GetUnits())))
            return Vector2i(s, s)
        Formation.COLUMN:
            var width : int = ceil(pow(GetUnits(), 0.333))
            var ranks : int = ceil(GetUnits() / float(width))
            return Vector2(width, ranks)
        _:
            assert(false, "GetWidthAndRanks() with unknown formation: " + str(_formation))
            var s : int = int(ceil(sqrt(GetUnits())))
            return Vector2i(s, s)

func GetDim() -> Vector2:
    var unit_dim : Vector2 = GetUnitDim(_squad_type)
    match _formation:
        Formation.LINE:
            return Vector2(unit_dim.x * GetUnits(), unit_dim.y)
        Formation.DOUBLELINE:
            var ranks : int = 2
            var width : int = ceil(float(GetUnits()) / float(ranks))
            if ranks > width:
                var t = ranks
                ranks = width
                width = t
            return Vector2(unit_dim.x * width, unit_dim.y * ranks)
        Formation.TRIPLELINE:
            var ranks : int = 3
            var width : int = ceil(float(GetUnits()) / float(ranks))
            if ranks > width:
                var t = ranks
                ranks = width
                width = t
            return Vector2(unit_dim.x * width, unit_dim.y * ranks)
        Formation.SQUARE:
            var s : float = sqrt(GetUnits())
            var ranks : int = floor(s)
            var width : int = ceil(s)
            if ranks * width < GetUnits():
                ranks += 1
            return Vector2(unit_dim.x * width, unit_dim.y * ranks)
        Formation.SKIRMISH:
            var s : float = ceil(sqrt(GetUnits()))
            return Vector2(unit_dim.x * s * 1.5, unit_dim.y * s * 1.5)
        Formation.COLUMN:
            var width : int = ceil(pow(GetUnits(), 0.333))
            var ranks : int = ceil(GetUnits() / float(width))
            return Vector2(unit_dim.x * width, unit_dim.y * ranks)
        _:
            assert(false, "GetDim() with unknown formation: " + str(_formation))
            return unit_dim * sqrt(GetUnits())

func SetSquadType(st : SquadType) -> void:
    _squad_type = st
    var cavalryIcon = find_child("Cavalry") as Line2D
    var artilleryIcon = find_child("Artillery") as Line2D
    var infantryIcon = find_child("Infantry") as Line2D
    match _squad_type:
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
            
func SetFormation(form : Formation) -> void:
    _formation = form
