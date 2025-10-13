class_name TurnEngine extends StateMachine

var _armies : Array[Army]
var _turn_order : Array[Squad]

func Config(armies : Array[Army]) -> void:
    _armies = armies
    for army : Army in _armies:
        army.RegisterSquads(self)
    find_child("State_DetermineWhoGoesNext").connect("state_enter", Callable(self, "_OnStateEnter_DetermineWhoGoesNext"))
    switch_state("State_DetermineWhoGoesNext")

func Add(squad : Squad) -> void:
    _turn_order.append(squad)

func _OnStateEnter_DetermineWhoGoesNext() -> void:
    print("DETERMINE WHO GOES NEXT")
    pass
