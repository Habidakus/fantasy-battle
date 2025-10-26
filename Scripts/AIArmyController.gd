class_name AIArmyController extends ArmyController

static var s_NEXT_ID : int = 0
static var s_LOOK_AHEAD : int = 6

var _name : String
var _turn_engine : TurnEngine
var _negamax_engine : MinMaxCalculator = MinMaxCalculator.new()

func _to_string() -> String:
    return _name

func RequestOrders(squad : Squad) -> void:
    var game_state : GameState = _turn_engine.GenerateGameState(squad)
    var action : ArmyControllerAction = _negamax_engine.get_best_action(game_state, s_LOOK_AHEAD)
    if action != null:
        _turn_engine.SubmitAction(action)

func RegisterTurnEngine(turn_engine : TurnEngine) -> void:
    _turn_engine = turn_engine
    s_NEXT_ID += 1
    assert(s_NEXT_ID < 5)
    _name = "AI#%d" % [s_NEXT_ID]
