class_name AIScore extends MMCScore

var _get_close : float = 0
var _die_supremacy : float = 0
var _jcounter : JCounter = JCounter.Create("AIScore")

func _to_string() -> String:
    return "score=(%s, %s)" % [_die_supremacy, _get_close]

static func Create(game_state : GameState) -> AIScore:
    var aiArmy : Army = game_state.GetInvokingArmy()
    var otherArmy : Army = game_state.GetNonInvokingArmy()

    var ret_val : AIScore = AIScore.new()
    for squad : Squad in aiArmy._squads:
        var base_score : float = squad.GetBaseScore()
        ret_val._die_supremacy += base_score
        for enemy : Squad in otherArmy._squads:
            var enemy_base_score : float = enemy.GetBaseScore()
            ret_val._get_close += squad.GetClosenessScore(base_score, enemy_base_score, squad.position.distance_squared_to(enemy.position))
    for enemy : Squad in otherArmy._squads:
        var enemy_base_score : float = enemy.GetBaseScore()
        ret_val._die_supremacy -= enemy_base_score
    return ret_val

## Return the inverse of the current score. If the score is being kept in a simple numeric value, this
## can be as simple a returning [score] * -1.  However if the score is more complex you might need to
## provide more extensive logic here.
func reversed() -> MMCScore:
    var ret_val : AIScore = AIScore.new()
    ret_val._get_close = 0 - _get_close
    ret_val._die_supremacy = 0 - _die_supremacy
    return ret_val

## Returns true only if the current score is better for the Computer Player (the one we're doing all this
## computation for) than it would be for the human opponent.
func is_better_than(other : MMCScore) -> bool:
    if other is AIScore:
        var other_ai_score : AIScore = other as AIScore
        if _die_supremacy != other_ai_score._die_supremacy:
            return _die_supremacy > other_ai_score._die_supremacy
        return _get_close > other_ai_score._get_close
    assert(false)
    return false
