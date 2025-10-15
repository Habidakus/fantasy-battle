class_name ArmyControllerAction extends MMCAction

enum Action { PASS, MELEE, CHARGE, MOVE }

var _squad : Squad
var _action : Action
var _target : Squad
var _position : Vector2
var _rotation : float
var _jcounter : JCounter = JCounter.Create("ArmyControllerAction")

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
			return "%s will charge %s" % [squad_name, target_name]
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

func ApplyToBoardState(board_state : BoardState, rnd : RandomNumberGenerator) -> void:
	match _action:
		Action.PASS:
			_apply_pass(board_state)
		Action.MELEE:
			_apply_melee(board_state, rnd)
		Action.CHARGE:
			_apply_charge(board_state, rnd)
		Action.MOVE:
			_apply_move(board_state)
		_:
			assert(false, "Unknown action type: " + Action.keys()[_action])

func _apply_pass(board_state : BoardState) -> void:
	if _squad != null:
		board_state.DelaySquad(_squad.id, 2)
	#game_state.AssignNextSquadToGo()

func _apply_melee(board_state : BoardState, rnd : RandomNumberGenerator) -> void:
	board_state.InflictDamage(_squad.id, _target.id, Squad.DamageType.MELEE, rnd)
	board_state.RemoveSquadIfDead(_target.id)
	if not board_state.RemoveSquadIfDead(_squad.id):
		board_state.DelaySquad(_squad.id, 3)
	#game_state.AssignNextSquadToGo()

func _apply_charge(board_state : BoardState, rnd : RandomNumberGenerator) -> void:
	board_state.MoveTowardsTarget(_squad.id, _target.id)
	board_state.InflictDamage(_squad.id, _target.id, Squad.DamageType.CHARGE, rnd)
	board_state.RemoveSquadIfDead(_target.id)
	if not board_state.RemoveSquadIfDead(_squad.id):
		board_state.DelaySquad(_squad.id, _squad.GetChargeTime())
	#game_state.AssignNextSquadToGo()

func _apply_move(board_state : BoardState) -> void:
	if _target != null:
		board_state.MoveTowardsTarget(_squad.id, _target.id)
	else:
		board_state.MoveAtAngle(_squad.id, _position, _rotation)
	board_state.DelaySquad(_squad.id, _squad.GetMoveTime())
	#game_state.AssignNextSquadToGo()

static func _create(squad : Squad, action : Action) -> ArmyControllerAction:
	var ret_val :ArmyControllerAction = ArmyControllerAction.new()
	ret_val._action = action
	ret_val._squad = squad
	return ret_val

static func CreateSidePass(_controller : ArmyController) -> ArmyControllerAction:
	return ArmyControllerAction.new()

static func CreateMelee(squad : Squad) -> ArmyControllerAction:
	return ArmyControllerAction._create(squad, Action.MELEE)

static func CreatePass(squad : Squad) -> ArmyControllerAction:
	return ArmyControllerAction._create(squad, Action.PASS)

static func CreateMove(squad : Squad, target : Squad) -> ArmyControllerAction:
	assert(squad.GetArmy() != target.GetArmy())
	var ret_val : ArmyControllerAction = ArmyControllerAction._create(squad, Action.MOVE)
	ret_val._target = target
	return ret_val

static func CreateCharge(squad : Squad, target : Squad) -> ArmyControllerAction:
	assert(squad.GetArmy() != target.GetArmy())
	var ret_val : ArmyControllerAction = ArmyControllerAction._create(squad, Action.CHARGE)
	ret_val._target = target
	return ret_val
