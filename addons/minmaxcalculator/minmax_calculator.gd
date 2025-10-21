class_name MinMaxCalculator extends RefCounted

## An generic alpha beta pruning tree to implement deterministic best move calculations.
##
## Every time you wish to have the artificial
## opponent take a turn, you'll need to supply the MinMaxCalculator's get_best_action() function
## with a representation of the current game state. To do this first create an extension of the
## [MMCGameState] class which can hold within it a flyweight representation of the current state of
## the game - your class will need to implement your own version of the three base functions of that
## class; apply_action(), get_moves(), and get_score(). Next you'll need to extend both the [MMCAction]
## and [MMCScore] classes. Once you have all three, you will be able to ask the MinMaxCalculator for
## an optimal move for the artificial opponent to take.
##
## This class is an implementation of https://en.wikipedia.org/wiki/Negamax

const _max_int : int = 9223372036854775807

## Given a game state, calculate which potential action is the optimal next move. For very simple
## game states with limited moves, the depth value can be omitted and the engine will attempt to
## calculate the entire game tree. However for most interesting games (eg, not tic-tac-toe) you will
## want to specify a maximum depth for the engine to consider, otherwise the search space will be
## far too large and the game will appear to stop. If you are having trouble figuring out what is
## going on with your implementation, you can hand in an optional MMCDebug object which you can
## then call the [method MMCDebug.dump] function on to get the entire tree that the function derived (you might need
## to implement the _to_string() function on your implementation of the Game State, Action, and Score
## classes to get understandable output).
func get_best_action(game_state : MMCGameState, depth : int = _max_int) -> MMCAction:
	var result : MMCResult = _get_best_action_internal(game_state, MMCScore._LOWEST, MMCScore._HIGHEST, depth, 1)
	if result == null:
		return null
	else:
		return result.action

func _get_best_action_internal(game_state : MMCGameState, actorsLowerBound: MMCScore, actorsUpperBound: MMCScore, depth : int, color : int) -> MMCResult:
	if depth == 0:
		if color > 0:
			return MMCResult.create_score_only(game_state.get_score())
		else:
			return MMCResult.create_score_only(game_state.get_score().reversed())

	var actions : Array[MMCAction] = game_state.get_sorted_moves(color > 0)
	#actions.sort_custom(func(a : MMCAction, b : MMCAction) : return b.get_score().is_better_than(a.get_score()))
	if actions.is_empty():
		if color > 0:
			return MMCResult.create_score_only(game_state.get_score())
		else:
			return MMCResult.create_score_only(game_state.get_score().reversed())

	var best : MMCResult = null
	for i : int in range(0, actions.size()):
		var action : MMCAction = actions[i]
		var post_action_state : MMCGameState = game_state.apply_action(action)
		var actorsUpperBoundReversed : MMCScore = actorsUpperBound.reversed()
		var actorsLowerBoundReversed : MMCScore = actorsLowerBound.reversed()

		var result : MMCResult = _get_best_action_internal(post_action_state, actorsUpperBoundReversed, actorsLowerBoundReversed, depth - 1, 0 - color)

		var reversed_score : MMCScore = result.score.reversed()
		if best == null:
			best = MMCResult.create(action, reversed_score)
		elif reversed_score.is_better_than(best.score):
			best = MMCResult.create(action, reversed_score)
			
		if MMCScore._is_first_better_than_second(best.score, actorsLowerBound):
			actorsLowerBound = best.score
		if MMCScore._is_first_better_than_or_equal_to_second(actorsLowerBound, actorsUpperBound):
			break
			
	return best
