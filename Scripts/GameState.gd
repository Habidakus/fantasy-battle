class_name GameState extends MMCGameState

var _squad : Squad
var _armies : Array[Army]

static func Create(squad : Squad, armies : Array[Army]) -> GameState:
    var ret_val : GameState = GameState.new()
    ret_val._squad = squad
    ret_val._armies = armies
    return ret_val

func get_sorted_moves(_for_requesting_player : bool) -> Array[MMCAction]:
    return _squad.GetSortedMoves(self)
