class_name MMCAction extends RefCounted
## Reprentation of one valid move that a player could take from a given [MMCGameState]
##
## You must provide a derived class that extends [MMCAction] and implements the get_score() function
## that returns an instance of your own extension of the [MMCScore] class.

## Should return the worth of performing this action from the point of view of the player performing
## the action.
##
## For instance, if this action were to capture the queen in a game of chess, the score
## would probably be very high.
## 
## Note that if you've already filled out the code in your version of the game state's [method MMCGameState.get_score]
## then you could just implement calling something like [code]current_game_state.apply_action(self).get_score()[/code],
## although to speed things up, the score should be cached whenever possible so that for each game_state->action->game_state
## only one score is ever generated.
#func get_score() -> MMCScore:
#	# Should evaluate how good the current action leaves the game for the acting player
#	# For performance reasons this should be generated when the action was created, or JIT created and left in a quickly parsable format.
#	assert(false, "The derived MMCAction class must implement get_score()")
#	return null
