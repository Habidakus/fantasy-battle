class_name Squad extends RefCounted

static var s_NEXT_ID : int = 0

enum FlankType { Front, Side, Back}
enum DamageType { MELEE, CHARGE, MISSLE, ARTILLERY }
enum SquadType { INFANTRY, CAVALRY, ARTILLERY }
enum Formation { LINE, DOUBLELINE, TRIPLELINE, SQUARE, SKIRMISH, COLUMN }
# Line - maximum damage dealt, maximum damage taken from melee and missile
# Double line - slightly increased missile & artillery taken
# Triple line - increased missile & artillery taken
# Square - no flanking vulnerability, extra damage from missile and artillery
# Skirmish - increased melee damage taken, reduced missile and artillery damage taken
# Column - Extra movement, reduced damage dealt from melee and missile, extra damage from artillery

var id : int
var position : Vector2
var rotation : float
var _turn_order_tie_breaker : float
var _next_move : float
var _army : Army
var _speed : float = 60
var _units_healthy : int
var _units_wounded : int
var _default_die_sides : int = 6
var _formation : Formation = Formation.DOUBLELINE
var _squad_type : SquadType = SquadType.INFANTRY
var _target_id : int = -1
#var _jcounter : JCounter = JCounter.Create("Squad")

func _to_string() -> String:
	var health : String = "(%d)[%d]" % [_units_healthy, _next_move] if _units_wounded == 0 else "(%d/%d)[%d]" % [_units_healthy, _units_wounded, _next_move]
	match _squad_type:
		SquadType.INFANTRY:
			return "Infantry#%d%s" % [id, health]
		SquadType.CAVALRY:
			return "Cavalry#%d%s" % [id, health]
		SquadType.ARTILLERY:
			return "Cannon#%d%s" % [id, health]
		_:
			return "???#%d%s" % [id, health]

func Clone() -> Squad:
	var ret_val : Squad = Squad.new()
	ret_val._turn_order_tie_breaker = _turn_order_tie_breaker
	ret_val._next_move = _next_move
	ret_val._army = _army
	ret_val._speed = _speed
	ret_val._units_healthy = _units_healthy
	ret_val._units_wounded = _units_wounded
	ret_val._formation = _formation
	ret_val._squad_type = _squad_type
	ret_val._default_die_sides = _default_die_sides
	ret_val.position = position
	ret_val.rotation = rotation
	ret_val.id = id
	ret_val._target_id = _target_id
	return ret_val

func GetMeleeTime() -> float:
	return 3

func GetChargeTime() -> float:
	return 3 if _squad_type != SquadType.CAVALRY else 5
	
func GetMoveTime() -> float:
	return 3 if _squad_type != SquadType.CAVALRY else 5

func GetArmy() -> Army:
	return _army

func GetUnits() -> int:
	return _units_healthy + _units_wounded

func IsDead() -> bool:
	return _units_healthy + _units_wounded <= 0

func GetWoundLocation(rnd : RandomNumberGenerator) -> Vector2:
	var depthAndWidth : Vector2 = GetDepthAndWidth()
	var loc : Vector2 = Vector2(rnd.randf() * depthAndWidth.y, rnd.randf() * depthAndWidth.x) - (Vector2(depthAndWidth.y, depthAndWidth.x) / 2.0)
	return position + loc.rotated(rotation)

func TryAlignToEdge(edge : Array[Vector2]) -> void:
	# TODO: make sure we rotate towards them and close with them
	#       NOTE: we can only rotate if we can fit somehow. If not, we will continue to fight with bad flanking
	var mid_point : Vector2 = (edge[0] + edge[1]) / 2.0
	var edge_normal : Vector2 = (edge[0] - edge[1]).normalized()
	var edge_perp : Vector2 = Vector2(edge_normal.y, -edge_normal.x)
	var distance_to_our_front : float = GetDepthAndWidth().y / 2.0
	if (mid_point + edge_perp).distance_squared_to(position) < (mid_point - edge_perp).distance_squared_to(position):
		position = mid_point + edge_perp * distance_to_our_front
		rotation = (-edge_perp).angle()
	else:
		position = mid_point - edge_perp * distance_to_our_front
		rotation = edge_perp.angle()

func MakeFlushAgainst(edge : Array[Vector2], pointOnLine : Vector2) -> void:
	var edgeDir : Vector2 = (edge[0] - edge[1])
	var facingDir : Vector2 = Vector2(-edgeDir.y, edgeDir.x).normalized()
	
	var ourCurrentDirection : Vector2 = Vector2.from_angle(rotation)
	assert(ourCurrentDirection.is_normalized())
	
	# If the edge that was given to us is backwards, flip the facing dir
	var dot : float = ourCurrentDirection.dot(facingDir)
	if dot < 0:
		facingDir = Vector2.ZERO - facingDir
	
	var distance_to_our_front : float = GetDepthAndWidth().y / 2.0
	rotation = facingDir.angle()
	position = pointOnLine - (distance_to_our_front * facingDir )

func GetInterestingPointsNearMe(distance : float) -> Array[Vector2]:
	var dims : Vector2 = GetDepthAndWidth() / 2.0
	var points : Array[Vector2] = [ Vector2(dims.y, dims.x), Vector2(-dims.y, dims.x), Vector2(-dims.y, -dims.x), Vector2(dims.y, -dims.x) ]
	for i in range(points.size()):
		points[i] = position + points[i].rotated(rotation)
	var ret_val : Array[Vector2]
	for i in range(points.size()):
		var mid_edge : Vector2 = (points[i] + points[(i + 1) % 4]) / 2.0
		var dir : Vector2 = (mid_edge - position).normalized()
		ret_val.append(dir * distance + mid_edge)
	return ret_val

func GetRadiiSquared() -> float:
	var daw : Vector2 = GetDepthAndWidth() / 2.0
	return daw.x * daw.x + daw.y * daw.y

func GetLeadingEdgeAtRotation(angle : float) -> Array[Vector2]:
	var dims : Vector2 = GetDepthAndWidth() / 2.0
	var pointA : Vector2 = Vector2(dims.y, -dims.x).rotated(angle) + position
	var pointB : Vector2 = Vector2(dims.y, dims.x).rotated(angle) + position
	var pointC : Vector2 = (pointA + pointB) / 2.0
	return [pointA, pointC, pointB]

func _get_outline_at_rotation(rot : float) -> Array:
	var dims : Vector2 = GetDepthAndWidth() / 2.0
	var points : Array[Vector2]
	for point : Vector2 in [Vector2(dims.y, dims.x), Vector2(-dims.y, dims.x), Vector2(-dims.y, -dims.x), Vector2(dims.y, -dims.x)]:
		points.append(position + point.rotated(rot))
	var ret_val : Array
	ret_val.append([points[0], points[1], Color.BLUE]) # Flank
	ret_val.append([points[1], points[2], Color.BLACK]) # Back
	ret_val.append([points[2], points[3], Color.BLUE]) # Flank
	ret_val.append([points[3], points[0], Color.GREEN]) # Front
	return ret_val

func GetOutline() -> Array:
	return _get_outline_at_rotation(rotation)

func GetPresentingFlank(attack_loc : Vector2) -> FlankType:
	assert(attack_loc != position)
	# Back up in case attack_loc is actually inside our squad
	attack_loc = attack_loc + (attack_loc - position).normalized() * 100.0
	var dims : Vector2 = GetDepthAndWidth() / 2.0
	var points : Array[Vector2] = [Vector2(dims.y, dims.x), Vector2(-dims.y, dims.x), Vector2(-dims.y, -dims.x), Vector2(dims.y, -dims.x)]
	for i in range(points.size()):
		points[i] = position + points[i].rotated(rotation)
	for i in range(points.size()):
		var hit_point = Geometry2D.segment_intersects_segment(position, attack_loc, points[i], points[(i + 3) % 4])
		if hit_point != null:
			match i:
				0: return FlankType.Front
				1: return FlankType.Side
				2: return FlankType.Back
				3: return FlankType.Side
	assert(not Geometry2D.is_point_in_polygon(attack_loc, points))
	assert(null != Geometry2D.segment_intersects_segment(position, attack_loc, points[0], points[3]))
	return FlankType.Front

func GetFacingEdge(loc : Vector2) -> Array[Vector2]:
	var dims : Vector2 = GetDepthAndWidth() / 2.0
	var points : Array[Vector2] = [Vector2(dims.y, dims.x), Vector2(-dims.y, dims.x), Vector2(-dims.y, -dims.x), Vector2(dims.y, -dims.x)]
	for i in range(points.size()):
		points[i] = position + points[i].rotated(rotation)
	for i in range(points.size()):
		var hit_point = Geometry2D.segment_intersects_segment(position, loc, points[i], points[(i + 1) % 4])
		if hit_point != null:
			return [points[i], points[(i + 1) % 4]]
	return []
	
func GetChargeDistance() -> float:
	# TODO: Charge distance should change by formation & squad type
	return _speed

func GetMoveDistance() -> float:
	return _speed

func CanCharge(enemy : Squad) -> bool:
	# TODO: Add cost to turn towards closest spot on enemy
	var distance_to_our_front : float = GetDepthAndWidth().y / 2.0
	var facing_edge : Array[Vector2] = enemy.GetFacingEdge(position)
	if facing_edge.is_empty():
		return false
	var hit_point = Geometry2D.segment_intersects_segment(position, enemy.position, facing_edge[0], facing_edge[1])
	assert(hit_point != null)
	return hit_point.distance_to(position) < GetChargeDistance() + distance_to_our_front

func InflictActualWound(rnd : RandomNumberGenerator) -> void:
	if IsDead():
		return
	if _units_wounded > 0:
		if rnd.randi() % GetUnits() < _units_wounded:
			_units_wounded -= 1
			return
	_units_healthy -= 1
	_units_wounded += 1

const PREDICTED_WOUND_ITERATIONS : int = 25
func InflictPredictedWounds(rnd: RandomNumberGenerator, amount : int) -> void:
	var predictions : Array
	for i in range(PREDICTED_WOUND_ITERATIONS):
		predictions.append(_generate_virtual_damage(rnd, amount))
	#TODO: Replace sort with a version of nth_element() that grabs just the median value
	predictions.sort_custom(func(a, b) :return a[3] < b[3])
	var index : int = int(PREDICTED_WOUND_ITERATIONS / 2.0);
	_units_healthy -= predictions[index][0] + predictions[index][1] # healthy->dead + healthy->wounded
	_units_wounded -= predictions[index][2] - predictions[index][1] # wounded->dead - healthy->wounded

func _generate_virtual_damage(rnd: RandomNumberGenerator, amount : int) -> Array:
	var healthyToDead : int = 0
	var healthyToWounded : int = 0
	var woundedToDead : int = 0
	for i in range(amount):
		# as we apply our virtual damage, the number of healthy, wounded, and dead will shift
		var healthy = _units_healthy - (healthyToDead + healthyToWounded)
		var wounded = _units_wounded + healthyToWounded - woundedToDead
		var total = healthy + wounded
		if total == 0:
			# if we kill off the entire squad mid vitual damage application, just stop
			break
		assert(total > 0)
		var roll : int = rnd.randi() % total
		if roll < wounded:
			# we need to keep track of whether this is someone who was healthy at the start of
			# this damage application, or just some lingering wounded person we killed off.
			if roll < healthyToWounded:
				healthyToDead += 1
			else:
				woundedToDead += 1
		else:
			healthyToWounded += 1
	return [healthyToDead,healthyToWounded,woundedToDead,_calculate_damage_worth(healthyToDead, healthyToWounded, woundedToDead)]

func GetRoll(rnd : RandomNumberGenerator, mods : int, disadvantage : bool) -> int:
	if _units_wounded > 0:
		if rnd.randi() % GetUnits() < _units_wounded:
			mods -= 1
	var sides : int = max(1, _default_die_sides + mods)
	var roll : int = rnd.randi() % sides
	if disadvantage:
		roll = min(roll, rnd.randi() % sides)
	return roll

func _get_destination_based_on_possible_rotation_limitations(loc : Vector2, board_state : BoardState) -> Vector2:
	var delta_vector : Vector2 = loc - position
	var delta_vector_length : float = delta_vector.length()
	if delta_vector_length < 0.1:
		return Vector2.INF
	#var desired_angle_alt : float = position.angle_to(loc)
	var desired_angle : float = delta_vector.angle()
	#assert(desired_angle == desired_angle_alt)
	var delta_vector_angle : float = wrapf(desired_angle - rotation, -PI, PI)
	for army : Army in board_state._armies:
		for other : Squad in army._squads:
			if other.id == id:
				continue
			delta_vector_angle = _determine_max_angle_change(delta_vector_angle, func(angle) : return _does_overlap_other_squad_at_new_rotation(angle, other))
			if delta_vector_angle == 0:
				return Vector2.INF
	for rock : Rock in board_state._terrain_data._rocks:
		delta_vector_angle = _determine_max_angle_change(delta_vector_angle, func(angle) : return _does_overlap_rock_at_new_rotation(angle, rock))
		if delta_vector_angle == 0:
			return Vector2.INF
	var final_angle : float = rotation + delta_vector_angle
	var final_loc : Vector2 = position + Vector2.RIGHT.rotated(final_angle) * delta_vector_length
	if final_angle == desired_angle:
		assert((final_loc - loc).length_squared() < 0.1)
	return final_loc

func _determine_max_angle_change(delta_rotation : float, callable : Callable) -> float:
	if callable.call(rotation + delta_rotation):
		return _determine_max_angle_change_recursize(5, delta_rotation, 0, callable)
	else:
		return delta_rotation

func _determine_max_angle_change_recursize(attempts : int, max_known_failure : float, min_known_success : float, callable : Callable) -> float:
	var mid : float = (max_known_failure + min_known_success) / 2.0
	if callable.call(rotation + mid):
		if attempts == 0:
			return min_known_success
		return _determine_max_angle_change_recursize(attempts - 1, mid, min_known_success, callable)   
	else:
		if attempts == 0:
			return mid
		return _determine_max_angle_change_recursize(attempts - 1, max_known_failure, mid, callable)    

func _does_overlap_other_squad_at_new_rotation(desired_angle : float, other : Squad) -> bool:
	if (other.position - position).length_squared() > other.GetRadiiSquared() + GetRadiiSquared():
		return false
	for line : Array in _get_outline_at_rotation(desired_angle): # point1, point2, facing color
		for other_line : Array in other.GetOutline(): # point1, point2, facing color
			if null != Geometry2D.line_intersects_line(line[0], line[1], other_line[0], other_line[1]):
				return true
	return false

func _does_overlap_rock_at_new_rotation(desired_angle : float, rock : Rock) -> bool:
	if (rock.position - position).length_squared() > rock.GetCollisionRadiiSquared() + GetRadiiSquared():
		return false
	for line : Array in _get_outline_at_rotation(desired_angle): # point1, point2, facing color
		var rock_points : PackedVector2Array = rock.GetMapPoints_Collision()
		var rock_size : int = rock_points.size()
		for rock_index : int in range(rock_size):
			if null != Geometry2D.line_intersects_line(line[0], line[1], rock_points[rock_index], rock_points[(rock_index + 1) % rock_size]):
				return true
	return false

func GetSortedMoves(game_state : GameState) -> Array[MMCAction]:
	var ret_val : Array[MMCAction]
	if game_state.IsInCombat(self):
		for enemy : Squad in game_state.GetAllEnemy(self.GetArmy()):
			if game_state.LockedInCombat(self.id, enemy.id):
				ret_val.append(ArmyControllerAction.CreateMelee(self, enemy))
		assert(not ret_val.is_empty())
	else:
		var move_spots : Array
		for enemy : Squad in game_state.GetAllEnemy(self.GetArmy()):
			if CanCharge(enemy):
				ret_val.append(ArmyControllerAction.CreateCharge(self, enemy))
			else:
				for point : Vector2 in enemy.GetInterestingPointsNearMe(self.GetMoveDistance() * 0.95):
					var path : PackedVector2Array = game_state._board_state._terrain_data.GetPath(position, point)
					var path_size : int = path.size()
					var current_index : int = 0
					var blocked : bool = false
					while blocked == false && current_index < path_size:
						if (path[current_index] - position).length_squared() < 1:
							current_index += 1
							continue
						var destination : Vector2 = _get_destination_based_on_possible_rotation_limitations(path[current_index], game_state._board_state)
						if destination == Vector2.INF:
							blocked = true
							continue
						var dest_and_collision : Array = game_state.CheckForCollisions(self, destination)
						if (dest_and_collision[0] - position).length_squared() < 1:
							current_index += 1
							continue
						dest_and_collision.append(enemy)
						move_spots.append(dest_and_collision)
						if dest_and_collision[1] != BoardState.CollisionType.NOTHING:
							blocked = true
						elif dest_and_collision[0] != destination:
							blocked = true
						else:
							current_index += 1
		if move_spots.size() < 4:
			for point in move_spots:
				ret_val.append(ArmyControllerAction.CreateMoveTowards(self, point[0], point[2]))
		else:
			move_spots.sort_custom(func(a, b) :
				if a[1] != b[1]:
					if a[1] == BoardState.CollisionType.TERRAIN:
						return false
					if b[1] == BoardState.CollisionType.TERRAIN:
						return true
					if b[1] == BoardState.CollisionType.NOTHING:
						return false
					if a[1] == BoardState.CollisionType.NOTHING:
						return true
				var l1 : float = (a[0] - position).length_squared()
				var l2 : float = (b[0] - position).length_squared()
				return l1 > l2
			)
			for i in range(3):
				ret_val.append(ArmyControllerAction.CreateMoveTowards(self, move_spots[i][0], move_spots[i][2]))
	if ret_val.is_empty():
		ret_val.append(ArmyControllerAction.CreatePass(self))
	#assert(!ret_val.is_empty())
	return ret_val

static func GetSumOfSquares(d : int) -> int:
	match d:
		1: return 1
		2: return 5
		3: return 14
		4: return 30
		5: return 55
		6: return 91
		7: return 140
		8: return 204
		9: return 285
		9: return 385
		_: return GetSumOfSquares(d - 1)

func _calculate_damage_worth(healthyToDead : int, healthyToWounded : int, woundedToDead : int ) -> float:
	var h2dw : float = healthyToDead * (1 + _default_die_sides) / 2.0
	var h2ww : float = healthyToWounded / 2.0
	var w2dw : float = woundedToDead * _default_die_sides / 2.0
	return h2dw + h2ww + w2dw

func GetBaseScore() -> float:
	var ret_val : float = _units_healthy * (1 + _default_die_sides) / 2.0
	if _units_wounded > 0:
		ret_val += _units_wounded * _default_die_sides / 2.0
		# this is the code to calculate when we have weakness
		# ret_val += _units_wounded * GetSumOfSquares(_default_die_sides) / float(_default_die_sides * _default_die_sides)
	return ret_val

func GetClosenessScore(our_score : float, enemy_score : float, dist_squared : float) -> float:
	var diff_score : float = our_score - enemy_score
	var turns_away : int = max(1, int(ceil(sqrt(dist_squared) / _speed)))
	return (our_score + enemy_score + diff_score) / (turns_away * turns_away)

static func CalculateDieMods(attacker : Formation, defender : Formation, damageType : DamageType, flank : Squad.FlankType) -> Vector2i:
	match damageType:
		DamageType.MELEE:
			return Vector2i(CalculateDieMods_AttackerIsMelee(attacker), CalculateDieMods_DefenderAgainstMelee(defender, flank))
		DamageType.CHARGE:
			return Vector2i(CalculateDieMods_AttackerIsCharge(attacker), CalculateDieMods_DefenderAgainstCharge(defender, flank))
		DamageType.MISSLE:
			return Vector2i(CalculateDieMods_AttackerIsMissile(attacker), CalculateDieMods_DefenderAgainstMissile(defender))
		DamageType.ARTILLERY:
			return Vector2i(CalculateDieMods_AttackerIsArtillery(attacker), CalculateDieMods_DefenderAgainstArtillery(defender))
		_:
			assert(false, "Unknown Damage Type: " + str(damageType))
			return Vector2i(0, 0)

func GetDieCountInDefense(flank : Squad.FlankType) -> int:
	if _formation == Formation.SKIRMISH || _formation == Formation.SQUARE:
		return GetWidthAndRanks().x
	match flank:
		Squad.FlankType.Front:
			return GetWidthAndRanks().x
		Squad.FlankType.Side:
			return GetWidthAndRanks().y
		Squad.FlankType.Back:
			var rear_row : int = GetUnits() % GetWidthAndRanks().x
			return rear_row
	assert(false, "GetDieCountInDefense(): unknown flank : %s" % Squad.FlankType.keys()[flank])
	return GetWidthAndRanks().x

func GetDieCountInAttack(damageType : DamageType) -> int:
	match damageType:
		DamageType.MELEE:
			return GetDieCountInAttack_Melee()
		DamageType.CHARGE:
			return GetDieCountInAttack_Charge()
		DamageType.MISSLE:
			return GetDieCountInAttack_Missile()
		DamageType.ARTILLERY:
			return GetDieCountInAttack_Artillery()
		_:
			assert(false)
			return 0

func GetDieCountInAttack_Melee() -> int:
	var widthAndRanks : Vector2i = GetWidthAndRanks()
	match _formation:
		Formation.LINE:
			return widthAndRanks.x
		Formation.DOUBLELINE:
			return int(ceil(min(float(GetUnits()), widthAndRanks.x * 1.5)))
		Formation.TRIPLELINE:
			return min(GetUnits(), widthAndRanks.x * 2)
		Formation.SQUARE:
			return widthAndRanks.x
		Formation.SKIRMISH:
			return widthAndRanks.x
		Formation.COLUMN:
			return widthAndRanks.x
		_:
			assert(false)
			return 0

func GetDieCountInAttack_Charge() -> int:
	var widthAndRanks : Vector2i = GetWidthAndRanks()
	match _formation:
		Formation.LINE:
			return widthAndRanks.x
		Formation.DOUBLELINE:
			return min(GetUnits(), widthAndRanks.x * 2)
		Formation.TRIPLELINE:
			return min(GetUnits(), widthAndRanks.x * 3)
		Formation.SQUARE:
			return widthAndRanks.x
		Formation.SKIRMISH:
			return widthAndRanks.x
		Formation.COLUMN:
			return min(GetUnits(), widthAndRanks.x * 3)
		_:
			assert(false)
			return 0

func GetDieCountInAttack_Missile() -> int:
	if _formation == Formation.COLUMN:
		return min(GetUnits(), GetWidthAndRanks().x * 3)
	else:
		return GetUnits()
		
func GetDieCountInAttack_Artillery() -> int:
	if _formation == Formation.LINE || _formation == Formation.SKIRMISH:
		return GetUnits()
	else:
		return GetWidthAndRanks().x

static func CalculateDieMods_AttackerIsMissile(attacker : Formation) -> int:
	match attacker:
		Formation.LINE:
			return 1
		Formation.DOUBLELINE:
			return 0
		Formation.TRIPLELINE:
			return 0
		Formation.SQUARE:
			return -1
		Formation.SKIRMISH:
			return 1
		Formation.COLUMN:
			return -1
		_:
			assert(false)
			return 0
static func CalculateDieMods_DefenderAgainstMissile(defender : Formation) -> int:
	match defender:
		Formation.LINE:
			return 0
		Formation.DOUBLELINE:
			return -1
		Formation.TRIPLELINE:
			return -1
		Formation.SQUARE:
			return -1
		Formation.SKIRMISH:
			return 2
		Formation.COLUMN:
			return -1
		_:
			assert(false)
			return 0
static func CalculateDieMods_AttackerIsArtillery(attacker : Formation) -> int:
	match attacker:
		Formation.LINE:
			return 1
		Formation.DOUBLELINE:
			return -1
		Formation.TRIPLELINE:
			return -2
		Formation.SQUARE:
			return -2
		Formation.SKIRMISH:
			return 1
		Formation.COLUMN:
			return -2
		_:
			assert(false)
			return 0
static func CalculateDieMods_DefenderAgainstArtillery(defender : Formation) -> int:
	match defender:
		Formation.LINE:
			return 1
		Formation.DOUBLELINE:
			return 0
		Formation.TRIPLELINE:
			return 0
		Formation.SQUARE:
			return -1
		Formation.SKIRMISH:
			return 2
		Formation.COLUMN:
			return -2
		_:
			assert(false)
			return 0

static func CalculateDieMods_AttackerIsCharge(attacker : Formation) -> int:
	match attacker:
		Formation.LINE:
			return 1
		Formation.DOUBLELINE:
			return 1
		Formation.TRIPLELINE:
			return 1
		Formation.SQUARE:
			return -1
		Formation.SKIRMISH:
			return -1
		Formation.COLUMN:
			return 1
		_:
			assert(false)
			return 0

static func CalculateDieMods_DefenderAgainstCharge(defender : Formation, flank : Squad.FlankType) -> int:
	var flank_mod : int = _calculate_flank_defense_mod(flank)
	match defender:
		Formation.LINE:
			return flank_mod - 1
		Formation.DOUBLELINE:
			return flank_mod
		Formation.TRIPLELINE:
			return flank_mod + 1
		Formation.SQUARE:
			return 1
		Formation.SKIRMISH:
			return -2
		Formation.COLUMN:
			return flank_mod + 1
		_:
			assert(false)
			return flank_mod

static func CalculateDieMods_AttackerIsMelee(attacker : Formation) -> int:
	match attacker:
		Formation.LINE:
			return 1
		Formation.DOUBLELINE:
			return 0
		Formation.TRIPLELINE:
			return 0
		Formation.SQUARE:
			return -1
		Formation.SKIRMISH:
			return -1
		Formation.COLUMN:
			return -1
		_:
			assert(false)
			return 0

static func CalculateDieMods_DefenderAgainstMelee(defender : Formation, flank : Squad.FlankType) -> int:
	var flank_mod : int = _calculate_flank_defense_mod(flank)
	match defender:
		Formation.LINE:
			return flank_mod - 1
		Formation.DOUBLELINE:
			return flank_mod
		Formation.TRIPLELINE:
			return flank_mod
		Formation.SQUARE:
			return 0 
		Formation.SKIRMISH:
			return -1
		Formation.COLUMN:
			return flank_mod 
		_:
			assert(false)
			return flank_mod 

static func _calculate_flank_defense_mod(flank : Squad.FlankType) -> int:
	match flank:
		Squad.FlankType.Front:
			return 0
		Squad.FlankType.Side:
			return -1
		Squad.FlankType.Back:
			return -2
	assert(false, "_calculate_flank_defense_mod() unknown flank type: %s" % [Squad.FlankType.keys()[flank]])
	return 0

func Initialize(army : Army, count : int, st : SquadType, form : Formation, rnd : RandomNumberGenerator) -> void:
	_army = army
	SetSquadType(st)
	SetFormation(form)
	_turn_order_tie_breaker = rnd.randf()
	_next_move = 0
	#shape.color = army.GetColor()
	_units_healthy = count
	_units_wounded = 0
	s_NEXT_ID += 1
	id = s_NEXT_ID

func GetNextMove() -> float:
	return _next_move

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

static func GetUnitDim(st : SquadType) -> Vector2:
	match st:
		SquadType.CAVALRY:
			return Vector2(10, 20)
		SquadType.INFANTRY:
			return Vector2(10, 10)
		SquadType.ARTILLERY:
			return Vector2(40, 40)
		_:
			assert(false, "GetUnitDim(" + str(st) + ")")
			return Vector2(10,10)

func GetWidthAndRanks() -> Vector2i:
	#var unit_dim : Vector2 = GetUnitDim(_squad_type)
	match _formation:
		Formation.LINE:
			return Vector2i(GetUnits(), 1)
		Formation.DOUBLELINE:
			var ranks : int = 2
			var width : int = ceil(float(GetUnits()) / float(ranks))
			if ranks > width:
				var t = ranks
				ranks = width
				width = t
			return Vector2i(width, ranks)
		Formation.TRIPLELINE:
			var ranks : int = 3
			var width : int = ceil(float(GetUnits()) / float(ranks))
			if ranks > width:
				var t = ranks
				ranks = width
				width = t
			return Vector2i(width, ranks)
		Formation.SQUARE:
			var s : float = sqrt(GetUnits())
			var ranks : int = floor(s)
			var width : int = ceil(s)
			if ranks * width < GetUnits():
				ranks += 1
			return Vector2i(width, ranks)
		Formation.SKIRMISH:
			var s : int = int(ceil(sqrt(GetUnits())))
			return Vector2i(s, s)
		Formation.COLUMN:
			var width : int = ceil(pow(GetUnits(), 0.333))
			var ranks : int = ceil(GetUnits() / float(width))
			return Vector2(width, ranks)
		_:
			assert(false, "GetWidthAndRanks() with unknown formation: " + str(_formation))
			var s : int = int(ceil(sqrt(GetUnits())))
			return Vector2i(s, s)

func GetDepthAndWidth() -> Vector2:
	var unit_dim : Vector2 = GetUnitDim(_squad_type)
	match _formation:
		Formation.LINE:
			return Vector2(unit_dim.x * GetUnits(), unit_dim.y)
		Formation.DOUBLELINE:
			var ranks : int = 2
			var width : int = ceil(float(GetUnits()) / float(ranks))
			if ranks > width:
				var t = ranks
				ranks = width
				width = t
			return Vector2(unit_dim.x * width, unit_dim.y * ranks)
		Formation.TRIPLELINE:
			var ranks : int = 3
			var width : int = ceil(float(GetUnits()) / float(ranks))
			if ranks > width:
				var t = ranks
				ranks = width
				width = t
			return Vector2(unit_dim.x * width, unit_dim.y * ranks)
		Formation.SQUARE:
			var s : float = sqrt(GetUnits())
			var ranks : int = floor(s)
			var width : int = ceil(s)
			if ranks * width < GetUnits():
				ranks += 1
			return Vector2(unit_dim.x * width, unit_dim.y * ranks)
		Formation.SKIRMISH:
			var s : float = ceil(sqrt(GetUnits()))
			return Vector2(unit_dim.x * s * 1.5, unit_dim.y * s * 1.5)
		Formation.COLUMN:
			var width : int = ceil(pow(GetUnits(), 0.333))
			var ranks : int = ceil(GetUnits() / float(width))
			return Vector2(unit_dim.x * width, unit_dim.y * ranks)
		_:
			assert(false, "GetDepthAndWidth() with unknown formation: " + str(_formation))
			return unit_dim * sqrt(GetUnits())

func SetSquadType(st : SquadType) -> void:
	_squad_type = st
	match _squad_type:
		SquadType.CAVALRY:
			_speed *= 2
		SquadType.INFANTRY:
			pass
		SquadType.ARTILLERY:
			pass
			
func SetFormation(form : Formation) -> void:
	_formation = form
