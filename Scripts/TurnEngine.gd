class_name TurnEngine extends StateMachine

var _board_state : BoardState = BoardState.new()
var _pending_action : ArmyControllerAction
var _state_play : StatePlay
var _jcounter : JCounter = JCounter.Create("TurnEngine")

func Config(armies : Array[Army], rocks : Array[Rock], state_play : StatePlay, in_combat : Array[int]) -> void:
	_board_state.Config(armies, rocks, in_combat)
	_state_play = state_play
	for army : Army in armies:
		army.GetController().RegisterTurnEngine(self)
	find_child("State_DetermineWhoGoesNext").connect("state_enter", Callable(self, "_OnStateEnter_DetermineWhoGoesNext"))
	switch_state("State_DetermineWhoGoesNext")

func HideSquadBecauseTheyAreDead(id : int) -> void:
	_state_play.HideSquadBecauseTheyAreDead(id)
	
func UpdateSquadHealth(actual_squad : Squad, new_squad_stats : Squad) -> void:
	_state_play.UpdateSquadHealth(actual_squad, new_squad_stats)
	actual_squad._units_healthy = new_squad_stats._units_healthy
	actual_squad._units_wounded = new_squad_stats._units_wounded
	actual_squad._next_move = new_squad_stats._next_move

func UpdateArmies() -> void:
	for army : Army in _board_state._armies:
		for squad : Squad in army._squads:
			_state_play.UpdateSquad(squad)

func SubmitAction(action : ArmyControllerAction) -> void:
	_pending_action = action
	switch_state("State_ProcessOrders")

func GenerateGameState(squad : Squad) -> GameState:
	return _board_state.GenerateGameState(squad)

func _OnStateEnter_DetermineWhoGoesNext() -> void:
	_board_state.OrderSquads()
	var debug_order_string : String = "Turn order:"
	for s : Squad in _board_state._turn_order:
		debug_order_string += " %s" % [s]
	print(debug_order_string)
	var current_squad : Squad = _board_state.CurrentSquad()
	var controller : ArmyController = current_squad.GetArmy().GetController()
	controller.RequestOrders(current_squad)
