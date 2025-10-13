class_name GameState extends MMCGameState

var _squad : Squad
var _armies : Array[Army]
var _invoking_controller : AIArmyController

static func Create(squad : Squad, armies : Array[Army]) -> GameState:
    var ret_val : GameState = GameState.new()
    ret_val._squad = squad
    ret_val._armies = armies
    ret_val._invoking_controller = squad.GetArmy().GetController()
    return ret_val

func get_score() -> AIScore:
    return null

func get_sorted_moves(_for_requesting_player : bool) -> Array[MMCAction]:
    return _squad.GetSortedMoves(self)

func _assign_next_squad_to_go() -> void:
    _squad = null
    for army : Army in _armies:
        for squad : Squad in army._squads:
            if _squad == null:
                _squad = squad
            elif TurnEngine.OrderSquads(squad, _squad):
                _squad = squad

func DelaySquad(id : int, time : float) -> void:
    for army : Army in _armies:
        for squad : Squad in army._squads:
            if squad.id == id:
                squad._next_move += time
                _assign_next_squad_to_go()
                return
    assert(false)

func CreateClone() -> GameState:
    var clone_armies : Array[Army]
    for army : Army in _armies:
        clone_armies.append(army.Clone())      
    var ret_val : GameState = GameState.new()
    ret_val._invoking_controller = _invoking_controller
    ret_val._armies = clone_armies
    ret_val._squad = null
    return ret_val
  
func apply_action(action : MMCAction) -> MMCGameState:
    var ret_val : GameState = CreateClone()
    action.Apply(ret_val)
    return ret_val

func IsInCombat(squad : Squad) -> bool:
    assert(!squad.IsDead())
    # TODO: We should track this
    return false

func GetAllEnemy(army : Army) -> Array[Squad]:
    for a : Army in _armies:
        if a != army:
            return a._squads
    assert(false)
    return []

func GetAllChargableEnemy(squad : Squad) -> Array[Squad]:
    assert(!squad.IsDead())
    var ret_val : Array[Squad]
    for e : Squad in GetAllEnemy(squad.GetArmy()):
        if squad.CanCharge(e):
            ret_val.append(e)
    return ret_val
