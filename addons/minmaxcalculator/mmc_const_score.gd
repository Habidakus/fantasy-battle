class_name MMCConstScore extends MMCScore
## Helper class for MinMaxCalculator
##
## There's nothing you need to see here, unless you're just looking around

static func create_highest() -> MMCScore:
	return MMCConstScore.new()
static func create_lowest() -> MMCScore:
	return MMCConstScore.new()

func reversed() -> MMCScore:
	if self == MMCScore._HIGHEST:
		return MMCScore._LOWEST
	else:
		return MMCScore._HIGHEST
