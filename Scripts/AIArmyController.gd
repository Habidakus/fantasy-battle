class_name AIArmyController extends ArmyController

var _turn_engine : TurnEngine
var _negamax_engine : MinMaxCalculator = MinMaxCalculator.new()

func RequestOrders(squad : Squad) -> void:
    var game_state : GameState = _turn_engine.GenerateGameState(squad)
    var action : ArmyControllerAction = _negamax_engine.get_best_action(game_state, 4)
    _turn_engine.SubmitAction(action)

func RegisterTurnEngine(turn_engine : TurnEngine) -> void:
    _turn_engine = turn_engine
