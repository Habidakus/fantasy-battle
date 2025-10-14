class_name Army extends RefCounted

var _squads : Array[Squad]
var _color : Color = Color.WHITE
var _controller : ArmyController

func Clone() -> Army:
	var ret_val : Army = Army.new()
	ret_val.SetColor(_color)
	ret_val.SetController(_controller)
	for s : Squad in _squads:
		ret_val.Add(s.Clone())
	return ret_val

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
