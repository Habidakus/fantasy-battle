class_name Unit extends Object

var _is_alive : bool = true
var _default_die_sides : int = 6

static func CreateInfantry() -> Unit:
    var unit : Unit = Unit.new()
    return unit
