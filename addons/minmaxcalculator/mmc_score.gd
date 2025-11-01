class_name MMCScore extends RefCounted
## Representation of worth that any given [INMAction] to the computer player (the [method CreateReverse]
## function will always return the value of any action from the point of view of the human opponent).
## 
## You must provide a derived class that extends [NMScore] and your own implementation of the
## [method reversed] and [method is_better_than] functions.

## Return the inverse of the current score. If the score is being kept in a simple numeric value, this
## can be as simple a returning [score] * -1.  However if the score is more complex you might need to
## provide more extensive logic here.
func reversed() -> MMCScore:
	assert(false, "The derived MMCScore class must implement reversed()")
	return null

## Returns true only if the current score is better for the Computer Player (the one we're doing all this
## computation for) than it would be for the human opponent.
func is_better_than(other : MMCScore) -> bool:
	assert(false, "The derived MMCScore class must implement is_better_than()")
	return false

static var _HIGHEST : MMCScore = MMCConstScore.create_highest()
static var _LOWEST : MMCScore = MMCConstScore.create_lowest()

static func _is_first_better_than_second(first : MMCScore, second : MMCScore) -> bool:
	if second == _HIGHEST:
		return false
	if first == _LOWEST:
		return false
	if first == _HIGHEST:
		return true
	if second == _LOWEST:
		return true
	return first.is_better_than(second)
	
static func _is_first_better_than_or_equal_to_second(first : MMCScore, second : MMCScore) -> bool:
	if first == _HIGHEST:
		return true
	if second == _LOWEST:
		return true
	if second == _HIGHEST:
		return false
	if first == _LOWEST:
		return false
	return !second.is_better_than(first)
