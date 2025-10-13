class_name ArmyControllerAction extends MMCAction

enum Action { PASS, MELEE, CHARGE, MOVE }

var _squad : Squad
var _action : Action
var _target : Squad

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
