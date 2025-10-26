class_name ArmyControllerAction extends MMCAction

enum Action { PASS, MELEE, CHARGE, MOVE }

var _squad : Squad
var _action : Action
var _target : Squad
var _position : Vector2
#var _rotation : float
#var _jcounter : JCounter = JCounter.Create("ArmyControllerAction")

func _to_string() -> String:
    if _squad == null:
        assert(_action == Action.PASS)
        return "Controller passes"
    var squad_name : String = "%s's %s" % [_squad.GetArmy().GetController(), _squad]
    match _action:
        Action.PASS:
            return "%s will wait" % [squad_name]
        Action.MELEE:
            var target_name : String = str(_target)
            return "%s will melee %s" % [squad_name, target_name]
        Action.CHARGE:
            var target_name : String = str(_target)
            return "%s will charge %s" % [squad_name, target_name]
        Action.MOVE:
            if _target != null:
                var target_name : String = str(_target)
                return "%s will move towards %s" % [squad_name, target_name]
            else:
                return "%s will move to location" % [squad_name]
        _:
            return "%s will perform unknown action: %s" % [squad_name, Action.keys()[_action]]

func ApplyPredictionToBoardState(board_state : BoardState, rnd : RandomNumberGenerator) -> void:
    match _action:
        Action.PASS:
            _apply_pass(board_state)
        Action.MELEE:
            _apply_melee(false, board_state, rnd)
        Action.CHARGE:
            _apply_charge(false, board_state, rnd)
        Action.MOVE:
            _apply_move(board_state)
        _:
            assert(false, "Unknown action type: " + Action.keys()[_action])

func ApplyActualToBoardState(board_state : BoardState, rnd : RandomNumberGenerator) -> void:
    match _action:
        Action.PASS:
            _apply_pass(board_state)
        Action.MELEE:
            _apply_melee(true, board_state, rnd)
        Action.CHARGE:
            _apply_charge(true, board_state, rnd)
        Action.MOVE:
            _apply_move(board_state)
        _:
            assert(false, "Unknown action type: " + Action.keys()[_action])

func _apply_pass(board_state : BoardState) -> void:
    if _squad != null:
        board_state.DelaySquad(_squad.id, 2)

func _apply_melee(actual : bool, board_state : BoardState, rnd : RandomNumberGenerator) -> void:
    # TODO: make sure we rotate towards them and close with them
    #       NOTE: we can only rotate if we can fit somehow. If not, we will continue to fight with bad flanking
    if actual:
        board_state.InflictActualDamage(_squad.id, _target.id, Squad.DamageType.MELEE, rnd)
    else:
        board_state.InflictPredictedDamage(_squad.id, _target.id, Squad.DamageType.MELEE, rnd)
    var both_alive : bool = true
    if board_state.RemoveSquadIfDead(_target.id):
        both_alive = false
    if board_state.RemoveSquadIfDead(_squad.id):
        both_alive = false
    else:
        board_state.DelaySquad(_squad.id, _squad.GetMeleeTime())
    if both_alive:
        board_state.MarkInCombat(_squad.id, _target.id)

func _apply_charge(actual : bool, board_state : BoardState, rnd : RandomNumberGenerator) -> void:
    board_state.MoveTowardsTarget(_squad.id, _target.id)
    if actual:
        board_state.InflictActualDamage(_squad.id, _target.id, Squad.DamageType.CHARGE, rnd)
    else:
        board_state.InflictPredictedDamage(_squad.id, _target.id, Squad.DamageType.CHARGE, rnd)
    var both_alive : bool = true
    if board_state.RemoveSquadIfDead(_target.id):
        both_alive = false
    if board_state.RemoveSquadIfDead(_squad.id):
        both_alive = false
    else:
        board_state.DelaySquad(_squad.id, _squad.GetChargeTime())
    if both_alive:
        board_state.MarkInCombat(_squad.id, _target.id)

func _apply_move(board_state : BoardState) -> void:
    if _target != null:
        board_state.MoveTowardsTarget(_squad.id, _target.id)
    else:
        board_state.MoveTowardsLocation(_squad.id, _position)
    board_state.DelaySquad(_squad.id, _squad.GetMoveTime())

static func _create(squad : Squad, action : Action) -> ArmyControllerAction:
    var ret_val :ArmyControllerAction = ArmyControllerAction.new()
    ret_val._action = action
    ret_val._squad = squad
    return ret_val

static func CreateSidePass(_controller : ArmyController) -> ArmyControllerAction:
    return ArmyControllerAction.new()

static func CreateMelee(squad : Squad, target : Squad) -> ArmyControllerAction:
    assert(squad.GetArmy() != target.GetArmy())
    var ret_val : ArmyControllerAction = ArmyControllerAction._create(squad, Action.MELEE)
    ret_val._target = target
    return ret_val

static func CreatePass(squad : Squad) -> ArmyControllerAction:
    return ArmyControllerAction._create(squad, Action.PASS)

static func CreateMoveAt(squad : Squad, target : Squad) -> ArmyControllerAction:
    assert(squad.GetArmy() != target.GetArmy())
    var ret_val : ArmyControllerAction = ArmyControllerAction._create(squad, Action.MOVE)
    ret_val._target = target
    return ret_val

static func CreateMoveTowards(squad : Squad, loc : Vector2) -> ArmyControllerAction:
    var ret_val : ArmyControllerAction = ArmyControllerAction._create(squad, Action.MOVE)
    ret_val._position = loc
    #ret_val._rotation = squad.position.angle_to(loc)
    return ret_val

static func CreateCharge(squad : Squad, target : Squad) -> ArmyControllerAction:
    assert(squad.GetArmy() != target.GetArmy())
    var ret_val : ArmyControllerAction = ArmyControllerAction._create(squad, Action.CHARGE)
    ret_val._target = target
    return ret_val
