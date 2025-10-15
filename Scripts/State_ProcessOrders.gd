class_name StateProcessOrders extends StateMachineState

var _pending_board_state : BoardState = null
var _from : Dictionary = {}
var _lerp_val : float = 0
var _rnd : RandomNumberGenerator = RandomNumberGenerator.new()
var _jcounter : JCounter = JCounter.Create("StateProcessOrders")

func _process(delta: float) -> void:
	if _pending_board_state == null:
		return
		
	var old_board_state : BoardState = our_state_machine._board_state
	var did_work : bool = false
	for army : Army in old_board_state._armies:
		for squad : Squad in army._squads:
			if not _pending_board_state.HasSquad(squad.id):
				continue
			var pending_squad : Squad = _pending_board_state.GetSquadById(squad.id)
			if pending_squad != null:
				if not _from.has(int(pending_squad.id)):
					_from[int(pending_squad.id)] = [squad.position, squad.rotation]
					did_work = true
				else:
					var data = _from[int(pending_squad.id)]
					if pending_squad.position != squad.position:
						if _lerp_val >= 1:
							squad.position = pending_squad.position
						else:
							squad.position = data[0].lerp(pending_squad.position, _lerp_val)
							did_work = true
					if pending_squad.rotation != squad.rotation:
						if _lerp_val >= 1:
							squad.rotation = pending_squad.rotation
						else:
							squad.rotation = data[1] + lerp_angle(data[1], pending_squad.rotation, _lerp_val)
							did_work = true
	if did_work:
		_lerp_val += delta
		our_state_machine.UpdateArmies()
		return
	our_state_machine.switch_state("State_DetermineWhoGoesNext")

func enter_state() -> void:
	super.enter_state()
	print("Need to process order: %s" % [our_state_machine._pending_action])
	_pending_board_state = our_state_machine._board_state.Clone()
	our_state_machine._pending_action.ApplyToBoardState(_pending_board_state, _rnd)

func exit_state(_next_state: StateMachineState) -> void:
	our_state_machine._board_state = _pending_board_state
	_pending_board_state = null
	_from = {}
	_lerp_val = 0
	#print("Process complete: %s" % [our_state_machine._pending_action])
	super.exit_state(_next_state)
