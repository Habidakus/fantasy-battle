class_name ChangeStateButton extends Button

@export var next_state : StateMachineState 
var _our_state_machine : StateMachine

func _ready() -> void:
    connect("button_up", Callable(self, "_switch_state"))
    var node = get_parent()
    while node != null:
        if node is StateMachine:
            _our_state_machine = node
            break
        else:
            node = node.get_parent()

func _switch_state() -> void:
    _our_state_machine.switch_state(next_state.name)
