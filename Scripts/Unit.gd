class_name Unit extends Object

var _is_alive : bool = true
var _is_wounded : bool = false
var _default_die_sides : int = 6

# Combat idea
#  - Each unit gets one roll
#    - some situations can increase/decrease the number of sides on the die being rolled
#      - being wounded removes one side
#      - being in a bad formation to recieve damage type removes one side
#      - being caught on the flank removes on side
#      - being in a good formation to deliver damage adds one side
#    - some extreme situations can roll twice and chose the best/worst value
#      - being caught behind choses worst value of two rolls
#  - the die rolls for each side are paired off for every unit that could roll a die on each side. 
#    - If one side has more rolls, then it's possible to have multiple dice vs a single die
#    - Compare the highest roll on side A to the highest roll on side B
#      - if they are equal remove those rolls from each side
#      - if they are not equal remove those rolls from each side and apply a wound to the lesser side

func RollAttack(rnd : RandomNumberGenerator, mods : int) -> int:
    var sides : int = _default_die_sides + mods
    assert(_is_alive)
    if _is_wounded:
        sides -= 1
    return rnd.randi() % sides

static func ApplyDamage(unitA : Unit, unitB : Unit, rollA: int, rollB: int) -> void:
    assert(unitA._is_alive)
    assert(unitB._is_alive)
    if rollA == rollB:
        return
    if rollA > rollB:
        unitB.ApplyWound()
    else:
        unitA.ApplyWound()
