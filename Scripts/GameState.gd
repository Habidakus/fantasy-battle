class_name GameState extends MMCGameState

var _board_state : BoardState = BoardState.new()
var _squad : Squad
var _invoking_controller : AIArmyController
var _current_controller : ArmyController
var _rnd : RandomNumberGenerator = RandomNumberGenerator.new() # We should implement something deterministic for negamax to use
var _jcounter : JCounter = JCounter.Create("GameState")

static func Create(squad : Squad, armies : Array[Army]) -> GameState:
	var ret_val : GameState = GameState.new()
	ret_val._squad = squad
	ret_val._board_state.Config(armies)
	ret_val._invoking_controller = squad.GetArmy().GetController()
	ret_val._current_controller = ret_val._invoking_controller
	assert(ret_val._invoking_controller is AIArmyController)
	return ret_val

func GetInvokingArmy() -> Army:
	return _board_state.GetControllersArmy(_invoking_controller)

func GetNonInvokingArmy() -> Army:
	return _board_state.GetControllersArmy(_get_opposing_controller(_invoking_controller))

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
	_squad = _board_state.GetNextSquadToGo()

func GetSquadById(id : int) -> Squad:
	return _board_state.GetSquadById(id)

func RemoveSquadIfDead(id : int) -> bool:
	return _board_state.RemoveSquadIfDead(id)

func CreateClone() -> GameState:
	var ret_val : GameState = GameState.new()
	ret_val._board_state = _board_state.Clone()
	ret_val._invoking_controller = _invoking_controller
	ret_val._squad = null
	ret_val._current_controller = _get_opposing_controller(_current_controller)
	return ret_val

func _get_opposing_controller(controller : AIArmyController) -> ArmyController:
	return _board_state.GetOpposingController(controller)
  
func apply_action(action : MMCAction) -> MMCGameState:
	var ret_val : GameState = CreateClone()
	var aca : ArmyControllerAction = action as ArmyControllerAction
	aca.ApplyToBoardState(ret_val._board_state, ret_val._rnd)
	ret_val.AssignNextSquadToGo()
	return ret_val

func IsInCombat(squad : Squad) -> bool:
	assert(!squad.IsDead())
	# TODO: We should track this
	return false

func GetAllEnemy(army : Army) -> Array[Squad]:
	return _board_state.GetAllEnemy(army)

func GetAllChargableEnemy(squad : Squad) -> Array[Squad]:
	assert(!squad.IsDead())
	var ret_val : Array[Squad]
	for e : Squad in GetAllEnemy(squad.GetArmy()):
		if squad.CanCharge(e):
			ret_val.append(e)
	return ret_val
