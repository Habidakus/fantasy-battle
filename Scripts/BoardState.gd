class_name BoardState extends RefCounted

var _armies : Array[Army]
var _turn_order : Array[Squad]
var _jcounter : JCounter = JCounter.Create("BoardState")
var _in_combat : Array[int] = []

func Clone() -> BoardState:
	var ret_val : BoardState = BoardState.new()
	for army : Army in _armies:
		ret_val._armies.append(army.Clone())
		for squad : Squad in army._squads:
			ret_val._turn_order.append(squad.Clone())
	for entry in _in_combat:
		ret_val._in_combat.append(entry)
	return ret_val

func Config(armies : Array[Army], in_combat : Array[int]) -> void:
	_armies = armies
	for army : Army in _armies:
		assert(!army._squads.is_empty())
		for squad : Squad in army._squads:
			_turn_order.append(squad)
	for entry : int in in_combat:
		_in_combat.append(entry)

func MarkInCombat(left_id : int, right_id : int) -> void:
	var left_index : int = left_id * 100 + right_id
	var right_index : int = right_id * 100 + left_id
	if not _in_combat.has(left_index):
		assert(!_in_combat.has(right_index))
		_in_combat.append(left_index)
		_in_combat.append(right_index)
	else:
		assert(_in_combat.has(right_index))

func RemoveCombatPairs(id : int) -> void:
	var new_list : Array[int]
	for entry : int in _in_combat:
		var low : int = entry % 100
		if (low != id) and (entry - low != id * 100):
			new_list.append(entry)
	assert(new_list.size() % 2 == 0)
	_in_combat = new_list

func IsInCombat(id : int) -> bool:
	for entry : int in _in_combat:
		var low : int = entry % 100
		if (low == id) or (entry - low == id * 100):
			return true
	return false

func LockedInCombat(left : int, right : int) -> bool:
	return _in_combat.has(left * 100 + right)

func GetAllEnemy(army : Army) -> Array[Squad]:
	for a : Army in _armies:
		if a.GetController() != army.GetController():
			return a._squads
	assert(false)
	return []

func GenerateGameState(squad : Squad) -> GameState:
	return GameState.Create(squad, _armies, _in_combat)

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
	var vec_to_target : Vector2 = target.position - squad.position
	
	squad.rotation = vec_to_target.angle()
	var forward_dir : Vector2 = Vector2(1,0).rotated(squad.rotation)
	var dist_to_target : float = vec_to_target.length()
	var thrust : float = squad._speed if dist_to_target > squad._speed else dist_to_target
	var move_vec : Vector2 = thrust * forward_dir
	var distance_to_our_front : float = squad.GetDim().y / 2.0
	var projection_vec : Vector2 = distance_to_our_front * forward_dir
	
	var facing_edge : Array[Vector2] = target.GetFacingEdge(squad.position)
	if facing_edge.is_empty():
		print("TODO: Are %s and %s overlapping?" % [squad, target])
		squad.position = squad.position + move_vec
		return
		
	#var final_pos : Vector2 = squad.position + move_vec
	var hit_point = Geometry2D.segment_intersects_segment(squad.position, squad.position + move_vec + projection_vec, facing_edge[0], facing_edge[1])
	if hit_point == null:
		squad.position = squad.position + move_vec
	else:
		squad.position = hit_point - projection_vec

func MoveToLocation(id : int, location : Vector2, rot : float) -> void:
	var squad : Squad = GetSquadById(id)
	squad.position = location
	squad.rotation = rot

func InflictDamage(print: bool, attacker_id : int, target_id : int, damage_type : Squad.DamageType, rnd : RandomNumberGenerator) -> void:
	var attacker : Squad = GetSquadById(attacker_id)
	var defender : Squad = GetSquadById(target_id)
	var flank : Squad.FlankType = defender.GetPresentingFlank(attacker.position)
	var die_mods : Vector2i = Squad.CalculateDieMods(attacker._formation, defender._formation, damage_type, flank)
	var attacker_dice : int = attacker.GetDieCountInAttack(damage_type)
	var defender_dice : int = defender.GetDieCountInDefense(flank)
	var die_rolls : int = max(attacker_dice, defender_dice)
	var attacker_wounds : int = 0
	var defender_wounds : int = 0
	var dice_text : String = "%s %s:" % [attacker_dice, defender_dice]
	for i in range(die_rolls):
		var attacker_roll : int = attacker.GetRoll(rnd, die_mods[0], i >= attacker_dice)
		var defender_roll : int = defender.GetRoll(rnd, die_mods[1], i >= defender_dice)
		if attacker_roll > defender_roll:
			dice_text += " %s>%s" % [attacker_roll, defender_roll]
			defender_wounds += 1
		elif defender_roll > attacker_roll:
			dice_text += " %s<%s" % [attacker_roll, defender_roll]
			if damage_type == Squad.DamageType.MELEE || damage_type == Squad.DamageType.CHARGE:
				attacker_wounds += 1
		else:
			dice_text += " %s=%s" % [attacker_roll, defender_roll]
	if print:
		var damage : String = "wounds(%s/%s)" % [attacker_wounds, defender_wounds]
		print("%s %ss %s in the %s: [%s ] %s" % [attacker, Squad.DamageType.keys()[damage_type], defender, Squad.FlankType.keys()[flank], dice_text, damage])
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
					RemoveCombatPairs(id)
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
	_turn_order.clear()
	for army : Army in _armies:
		for squad : Squad in army._squads:
			if !squad.IsDead():
				_turn_order.append(squad)
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
