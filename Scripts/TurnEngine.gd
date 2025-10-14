class_name TurnEngine extends StateMachine

var _board_state : BoardState = BoardState.new()
var _pending_action : ArmyControllerAction

func Config(armies : Array[Army]) -> void:
	_board_state.Config(armies)
	for army : Army in armies:
		army.GetController().RegisterTurnEngine(self)
	find_child("State_DetermineWhoGoesNext").connect("state_enter", Callable(self, "_OnStateEnter_DetermineWhoGoesNext"))
	switch_state("State_DetermineWhoGoesNext")

func SubmitAction(action : ArmyControllerAction) -> void:
	_pending_action = action
	switch_state("State_ProcessOrders")

func GenerateGameState(squad : Squad) -> GameState:
	return _board_state.GenerateGameState(squad)

func _OnStateEnter_DetermineWhoGoesNext() -> void:
	_board_state.OrderSquads()
	var current_squad : Squad = _board_state.CurrentSquad()
	var controller : ArmyController = current_squad.GetArmy().GetController()
	controller.RequestOrders(current_squad)
