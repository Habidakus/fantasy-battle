class_name GameState extends MMCGameState

var _squad : Squad
var _armies : Array[Army]
var _invoking_controller : AIArmyController
var _current_controller : ArmyController
var _rnd : RandomNumberGenerator = RandomNumberGenerator.new() # We should implement something deterministic for negamax to use

static func Create(squad : Squad, armies : Array[Army]) -> GameState:
    var ret_val : GameState = GameState.new()
    ret_val._squad = squad
    ret_val._armies = armies
    ret_val._invoking_controller = squad.GetArmy().GetController()
    ret_val._current_controller = ret_val._invoking_controller
    assert(ret_val._invoking_controller is AIArmyController)
    return ret_val

func GetInvokingArmy() -> Army:
    assert(_armies.size() == 2)
    var aiArmy : Army = _armies[0] if _invoking_controller == _armies[0].GetController() else _armies[1]
    return aiArmy

func GetNonInvokingArmy() -> Army:
    assert(_armies.size() == 2)
    var otherArmy : Army = _armies[1] if _invoking_controller == _armies[0].GetController() else _armies[0]
    return otherArmy

func get_score() -> AIScore:
    return AIScore.Create(self)

func get_sorted_moves(_for_requesting_player : bool) -> Array[MMCAction]:
    if _current_controller == _squad.GetArmy().GetController():
        return _squad.GetSortedMoves(self)
    else:
        var ret_val : Array[MMCAction]
        ret_val.append(ArmyControllerAction.CreateSidePass(_current_controller))
        return ret_val

func AssignNextSquadToGo() -> void:
    _squad = null
    for army : Army in _armies:
        for squad : Squad in army._squads:
            if _squad == null:
                _squad = squad
            elif TurnEngine.OrderSquads(squad, _squad):
                _squad = squad

func GetSquadById(id : int) -> Squad:
    for army : Army in _armies:
        for squad : Squad in army._squads:
            if squad.id == id:
                return squad
    assert(false)
    return null
    
func DelaySquad(id : int, time : float) -> void:
    var squad : Squad = GetSquadById(id)
    squad._next_move += time

func MoveTowardsTarget(id : int, target_id : int) -> void:
    var squad : Squad = GetSquadById(id)
    var target : Squad = GetSquadById(target_id)
    squad.look_at(target.global_position)
    var forward_dir : Vector2 = Vector2(1,0).rotated(squad.rotation)
    var move_vec : Vector2 = squad._speed * forward_dir
    squad.position += move_vec

func MoveToLocation(id : int, location : Vector2, rot : float) -> void:
    var squad : Squad = GetSquadById(id)
    squad.position = location
    squad.rotation = rot

func RemoveSquadIfDead(id : int) -> bool:
    for army : Army in _armies:
        for squad : Squad in army._squads:
            if squad.id == id:
                if squad.IsDead():
                    army._squads.erase(squad)
                    return true
                else:
                    return false
    assert(false)
    return false

func InflictDamage(attacker_id : int, target_id : int, damage_type : Squad.DamageType) -> void:
    var attacker : Squad = GetSquadById(attacker_id)
    var defender : Squad = GetSquadById(target_id)
    var die_mods : Vector2i = attacker.CalculateDieMods(attacker._formation, defender._formation, damage_type)
    var attacker_dice : int = attacker.GetDieCountInAttack(damage_type)
    var defender_dice : int = defender.GetDieCountInDefense()
    var die_rolls : int = max(attacker_dice, defender_dice)
    var attacker_wounds : int = 0
    var defender_wounds : int = 0
    for i in range(die_rolls):
        var attacker_roll : int = attacker.GetRoll(_rnd, die_mods[0], i >= attacker_dice)
        var defender_roll : int = defender.GetRoll(_rnd, die_mods[1], i >= defender_dice)
        if attacker_roll > defender_roll:
            defender_wounds += 1
        elif defender_roll > attacker_roll:
            if damage_type == Squad.DamageType.MELEE || damage_type == Squad.DamageType.CHARGE:
                attacker_wounds += 1
    for i in range(attacker_wounds):
        attacker.InflictWound(_rnd)
    for i in range(defender_wounds):
        defender.InflictWound(_rnd)

func CreateClone() -> GameState:
    var clone_armies : Array[Army]
    for army : Army in _armies:
        clone_armies.append(army.Clone())      
    var ret_val : GameState = GameState.new()
    ret_val._invoking_controller = _invoking_controller
    ret_val._armies = clone_armies
    ret_val._squad = null
    ret_val._current_controller = _get_opposing_controller(_current_controller)
    return ret_val

func _get_opposing_controller(controller : AIArmyController) -> ArmyController:
    for army : Army in _armies:
        var army_controller : ArmyController = army.GetController()
        if army_controller != controller:
            return army_controller
    assert(false)
    return null
  
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
        if a.GetController() != army.GetController():
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
