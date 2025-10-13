class_name Army extends Object

var _squads : Array[Squad]
var _color : Color = Color.WHITE
var _controller : ArmyController

func Add(squad : Squad) -> void:
    _squads.append(squad)

func SetColor(color : Color) -> void:
    _color = color

func SetController(controller : ArmyController) -> void:
    _controller = controller

func GetColor() -> Color:
    return _color

func GetController() -> AIArmyController:
    return _controller

func RegisterSquads(turn_engine : TurnEngine) -> void:
    for squad : Squad in _squads:
        turn_engine.Add(squad)
