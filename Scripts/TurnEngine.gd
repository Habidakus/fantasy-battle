class_name TurnEngine extends StateMachine

var _armies : Array[Army]
var _turn_order : Array[Squad]

func Config(armies : Array[Army]) -> void:
    _armies = armies
    for army : Army in _armies:
        army.RegisterSquads(self)
        army.GetController().RegisterTurnEngine(self)
    find_child("State_DetermineWhoGoesNext").connect("state_enter", Callable(self, "_OnStateEnter_DetermineWhoGoesNext"))
    switch_state("State_DetermineWhoGoesNext")

func Add(squad : Squad) -> void:
    _turn_order.append(squad)

func GenerateGameState(squad : Squad) -> GameState:
    return GameState.Create(squad, _armies)

func _OnStateEnter_DetermineWhoGoesNext() -> void:
    _turn_order.sort_custom(Callable(self, "_order_squads"))
    while _turn_order.back().IsDead():
        _turn_order.pop_back()
    var controller : ArmyController = _turn_order.front().GetArmy().GetController()
    controller.RequestOrders(_turn_order.front())

func _order_squads(left : Squad, right : Squad) -> bool:
    var leftIsDead : bool = left.IsDead()
    var rightIsDead : bool = right.IsDead()
    if leftIsDead != rightIsDead:
        return rightIsDead
    
    var leftNextMove : float = left.GetNextMove()
    var rightNextMove : float = right.GetNextMove()
    if leftNextMove != rightNextMove:
        return leftNextMove < rightNextMove

    return left._turn_order_tie_breaker < right._turn_order_tie_breaker
