class_name Army extends Object

var units : Array[Squad]
var _color : Color = Color.WHITE

func Add(squad : Squad) -> void:
    units.append(squad)

func SetColor(color : Color) -> void:
    _color = color

func GetColor() -> Color:
    return _color
