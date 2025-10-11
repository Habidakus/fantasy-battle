class_name MMCGameState extends RefCounted
## Base class that represents a game state for the [MinMaxCalculator]
##
## When using the [MinMaxCalculator] you should create your own class that derives from this class
## and provides it's own implementation of the three functions listed below.
##
## For example: [codeblock]
## class_name MyGameState extends MMCGameState
## 
## func apply_action(action : MMCAction) -> MMCGameState:
##     var ret_val : MyGameState = MyGameState.new()
##     # ... code that applys MyAction to the current game state
##     return ret_val
## [/codeblock]

## Returns a new game state object that represents what will happen, deterministically, to the
## current game state object if the given [MMCAction] is applied to it.
func apply_action(action : MMCAction) -> MMCGameState:
	assert(false, "The derived MMCGameState class must implement apply_action()")
	return null

## Returns the list of all legal moves that the current player could make in the current game state.
## Ideally you should sort the moves so that the best moves for the current player (indicated by the
## [for_computer_player] argument) are first, and the worst moves are last.
func get_sorted_moves(for_computer_player : bool) -> Array[MMCAction]:
	assert(false, "The derived MMCGameState class must implement get_sorted_moves()")
	return []

## Returns the current worth of the game state from the point of view of the player who provided
## the action that created this game state instance. For instance, if in chess and the black has
## just taken the opponent's queen, then this score would be very high as seen from the point of
## view of the black pieces.
func get_score() -> MMCScore:
	assert(false, "The derived MMCGameState class must implement get_score()")
	return null
