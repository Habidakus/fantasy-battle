class_name ArmyControllerAction extends MMCAction

enum Action { PASS, MELEE, CHARGE, MOVE }

var _squad : Squad
var _action : Action
var _target : Squad
var _position : Vector2
var _rotation : float

func Apply(game_state : GameState) -> void:
    match _action:
        Action.PASS:
            _apply_pass(game_state)
        Action.MELEE:
            _apply_melee(game_state)
        Action.CHARGE:
            _apply_charge(game_state)
        Action.MOVE:
            _apply_move(game_state)
        _:
            assert(false, "Unknown action type: " + Action.keys()[_action])

func _apply_pass(game_state : GameState) -> void:
    game_state.DelaySquad(_squad.id, 2)

func _apply_melee(game_state : GameState) -> void:
    game_state.InflictDamage(_squad.id, _target.id, Squad.DamageType.MELEE)
    game_state.DelaySquad(_squad.id, 3)

func _apply_charge(game_state : GameState) -> void:
    game_state.InflictDamage(_squad.id, _target.id, Squad.DamageType.CHARGE)
    game_state.Move(_squad.id, _target.id)
    game_state.DelaySquad(_squad.id, 3)

func _apply_move(game_state : GameState) -> void:
    game_state.Move(_squad.id, _position, _rotation)
    game_state.DelaySquad(_squad.id, 3)

static func _create(squad : Squad, action : Action) -> ArmyControllerAction:
    var ret_val :ArmyControllerAction = ArmyControllerAction.new()
    ret_val._action = action
    ret_val._squad = squad
    return ret_val

static func CreateMelee(squad : Squad) -> ArmyControllerAction:
    return ArmyControllerAction._create(squad, Action.MELEE)

static func CreatePass(squad : Squad) -> ArmyControllerAction:
    return ArmyControllerAction._create(squad, Action.PASS)

static func CreateCharge(squad : Squad, target : Squad) -> ArmyControllerAction:
    var ret_val : ArmyControllerAction = ArmyControllerAction._create(squad, Action.CHARGE)
    ret_val._target = target
    return ret_val
