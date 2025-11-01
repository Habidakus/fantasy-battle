class_name TurnEngine extends StateMachine

var _board_state : BoardState = BoardState.new()
var _pending_action : ArmyControllerAction
var _state_play : StatePlay
#var _jcounter : JCounter = JCounter.Create("TurnEngine")

func Config(armies : Array[Army], terrain_data : TerrainData, state_play : StatePlay, in_combat : Array[int]) -> void:
    _board_state.Config(armies, terrain_data, in_combat)
    _state_play = state_play
    for army : Army in armies:
        army.GetController().RegisterTurnEngine(self)
    find_child("State_DetermineWhoGoesNext").connect("state_enter", Callable(self, "_OnStateEnter_DetermineWhoGoesNext"))
    switch_state("State_DetermineWhoGoesNext")

func HideSquadBecauseTheyAreDead(id : int) -> void:
    _state_play.HideSquadBecauseTheyAreDead(id)

func _draw_closest_edge(squad : Squad) -> void:
    var closest_edge : Array[Vector2] = squad._find_closest_collision_edge(_board_state)
    if not closest_edge.is_empty():
        var rap : Array = squad._find_rotation_and_position_against_edge(closest_edge)
        if not rap.is_empty():
            var draw_edge : Array[Vector2] = [rap[1], (closest_edge[0] + closest_edge[1]) / 2.0]
            _state_play.DrawEdge(squad.id, draw_edge, Color.GREEN)
    
func UpdateSquadHealth(actual_squad : Squad, new_squad_stats : Squad) -> void:
    _state_play.UpdateSquadHealth(actual_squad, new_squad_stats)
    actual_squad._units_healthy = new_squad_stats._units_healthy
    actual_squad._units_wounded = new_squad_stats._units_wounded
    actual_squad._next_move = new_squad_stats._next_move
    actual_squad._target_id = new_squad_stats._target_id
    if _board_state.HasSquad(actual_squad.id):
        var squad : Squad = _board_state.GetSquadById(actual_squad.id)
        _draw_closest_edge(squad)
        if _board_state.HasSquad(actual_squad._target_id):
            var other_squad : Squad = _board_state.GetSquadById(actual_squad._target_id)
            _state_play.DrawPathLine(squad.id, other_squad.id, squad.GetArmy().GetColor())

func UpdateArmies() -> void:
    for army : Army in _board_state._armies:
        for squad : Squad in army._squads:
            _draw_closest_edge(squad)
            var other_id : int = squad._target_id
            if _board_state.HasSquad(other_id):
                var other_squad : Squad = _board_state.GetSquadById(other_id)
                if other_squad != null:
                    _state_play.DrawPathLine(squad.id, other_squad.id, army.GetColor())
            _state_play.UpdateSquad(squad)

func SubmitAction(action : ArmyControllerAction) -> void:
    _pending_action = action
    switch_state("State_ProcessOrders")

func GenerateGameState(squad : Squad) -> GameState:
    return _board_state.GenerateGameState(squad)

func _OnStateEnter_DetermineWhoGoesNext() -> void:
    for army : Army in _board_state._armies:
        if army._squads.is_empty():
            print("Game Over")
    _board_state.OrderSquads()
    var debug_order_string : String = "Turn order:"
    for s : Squad in _board_state._turn_order:
        debug_order_string += " %s" % [s]
    print(debug_order_string)
    var current_squad : Squad = _board_state.CurrentSquad()
    var controller : ArmyController = current_squad.GetArmy().GetController()
    controller.RequestOrders(current_squad)
