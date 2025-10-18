class_name Army extends RefCounted

var _squads : Array[Squad]
var _color : Color = Color.WHITE
var _controller : ArmyController
var _jcounter : JCounter = JCounter.Create("Army")

func Clone() -> Army:
    var ret_val : Army = Army.new()
    ret_val.SetColor(_color)
    ret_val.SetController(_controller)
    for s : Squad in _squads:
        ret_val.Add(s.Clone())
    return ret_val

func GetPrimaryColor() -> Color:
    return _color

func GetSecondaryColor() -> Color:
    var h : float = _color.h + 0.5
    if h > 1.0:
        h -= 1.0
    var s : float = _color.s
    if s > 0.9:
        s = 0.5
    else:
        s = 1.0
    var v : float = _color.v
    if v > 0.9:
        v = 0.5
    else:
        v = 1.0
    return Color.from_hsv(h, s, v)

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
