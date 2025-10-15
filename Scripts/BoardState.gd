class_name BoardState extends RefCounted

var _armies : Array[Army]
var _turn_order : Array[Squad]
var _jcounter : JCounter = JCounter.Create("BoardState")

func Clone() -> BoardState:
	var ret_val : BoardState = BoardState.new()
	for army : Army in _armies:
		ret_val._armies.append(army.Clone())
		for squad : Squad in army._squads:
			ret_val._turn_order.append(squad.Clone())
	return ret_val

func Config(armies : Array[Army]) -> void:
	_armies = armies
	for army : Army in _armies:
		assert(!army._squads.is_empty())
		for squad : Squad in army._squads:
			_turn_order.append(squad)

func GetAllEnemy(army : Army) -> Array[Squad]:
	for a : Army in _armies:
		if a.GetController() != army.GetController():
			return a._squads
	assert(false)
	return []

func GenerateGameState(squad : Squad) -> GameState:
	return GameState.Create(squad, _armies)

func GetOpposingController(controller : ArmyController) -> ArmyController:
	assert(_armies.size() == 2)
	if _armies[0].GetController() == controller:
		return _armies[1].GetController()
	elif _armies[1].GetController() == controller:
		return _armies[0].GetController()
	else:
		assert(false, "Controller not found")
		return null

func GetNextSquadToGo() -> Squad:
	var ret_val : Squad = null
	for army : Army in _armies:
		for squad : Squad in army._squads:
			if ret_val == null:
				ret_val = squad
			elif BoardState.IsFirstSquadSooner(squad, ret_val):
				ret_val = squad
	return ret_val

func HasSquad(id : int) -> bool:
	for army : Army in _armies:
		for squad : Squad in army._squads:
			if squad.id == id:
				return true
	return false

func GetSquadById(id : int) -> Squad:
	for army : Army in _armies:
		for squad : Squad in army._squads:
			if squad.id == id:
				return squad
	assert(false)
	return null
	
func DelaySquad(id : int, time : float) -> void:
	var squad : Squad = GetSquadById(id)
	squad._next_move += time

func MoveTowardsTarget(id : int, target_id : int) -> void:
	var squad : Squad = GetSquadById(id)
	var target : Squad = GetSquadById(target_id)
	squad.rotation = (target.position - squad.position).angle()
	var forward_dir : Vector2 = Vector2(1,0).rotated(squad.rotation)
	var move_vec : Vector2 = squad._speed * forward_dir
	squad.position += move_vec

func MoveToLocation(id : int, location : Vector2, rot : float) -> void:
	var squad : Squad = GetSquadById(id)
	squad.position = location
	squad.rotation = rot

func InflictDamage(attacker_id : int, target_id : int, damage_type : Squad.DamageType, rnd : RandomNumberGenerator) -> void:
	var attacker : Squad = GetSquadById(attacker_id)
	var defender : Squad = GetSquadById(target_id)
	var die_mods : Vector2i = Squad.CalculateDieMods(attacker._formation, defender._formation, damage_type)
	var attacker_dice : int = attacker.GetDieCountInAttack(damage_type)
	var defender_dice : int = defender.GetDieCountInDefense()
	var die_rolls : int = max(attacker_dice, defender_dice)
	var attacker_wounds : int = 0
	var defender_wounds : int = 0
	for i in range(die_rolls):
		var attacker_roll : int = attacker.GetRoll(rnd, die_mods[0], i >= attacker_dice)
		var defender_roll : int = defender.GetRoll(rnd, die_mods[1], i >= defender_dice)
		if attacker_roll > defender_roll:
			defender_wounds += 1
		elif defender_roll > attacker_roll:
			if damage_type == Squad.DamageType.MELEE || damage_type == Squad.DamageType.CHARGE:
				attacker_wounds += 1
	for i in range(attacker_wounds):
		attacker.InflictWound(rnd)
	for i in range(defender_wounds):
		defender.InflictWound(rnd)

func RemoveSquadIfDead(id : int) -> bool:
	for army : Army in _armies:
		for squad : Squad in army._squads:
			if squad.id == id:
				if squad.IsDead():
					army._squads.erase(squad)
					return true
				else:
					return false
	assert(false)
	return false

func GetControllersArmy(controller : ArmyController) -> Army:
	assert(_armies.size() == 2)
	var aiArmy : Army = _armies[0] if controller == _armies[0].GetController() else _armies[1]
	return aiArmy

func CurrentSquad() -> Squad:
	var ret_val : Squad = _turn_order.front()
	return ret_val

func OrderSquads() -> void:
	_turn_order.sort_custom(Callable(self, "IsFirstSquadSooner"))
	while _turn_order.back().IsDead():
		_turn_order.pop_back()

static func IsFirstSquadSooner(left : Squad, right : Squad) -> bool:
	var leftIsDead : bool = left.IsDead()
	var rightIsDead : bool = right.IsDead()
	if leftIsDead != rightIsDead:
		return rightIsDead
	
	var leftNextMove : float = left.GetNextMove()
	var rightNextMove : float = right.GetNextMove()
	if leftNextMove != rightNextMove:
		return leftNextMove < rightNextMove

	return left._turn_order_tie_breaker < right._turn_order_tie_breaker
