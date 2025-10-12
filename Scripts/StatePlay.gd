class_name StatePlay extends StateMachineState

@export var squad_scene : PackedScene = preload("res://Scenes/squad.tscn")

var _mist_parallax_layer : ParallaxLayer
var _mist_direction : float
var _mist_speed : float
const _mist_min_speed : float = 2.5
const _mist_max_speed : float = 15
var rnd : RandomNumberGenerator = RandomNumberGenerator.new()

# screen x: 20 to 1130
# screen y: 23 to 627

func _ready() -> void:
    _mist_parallax_layer = find_child("Parallax_Mist") as ParallaxLayer
    _mist_direction = rnd.randf() * 360.0
    _mist_speed = rnd.randf() * (_mist_max_speed - _mist_min_speed) + _mist_min_speed
    const total : int = 6
    var squads : Array[Squad]
    for i in range(total):
        var s : Squad = squad_scene.instantiate()
        s.Initialize(15, Squad.SquadType.INFANTRY)
        s.position.x = 20 + (1 + i) * (1130 - 20) / float(total + 2)
        s.position.y = 23 + (1 + i) * (627 - 23) / float(total + 2)
        match i:
            0:
                s.formation = Squad.Formation.LINE
            1:
                s.formation = Squad.Formation.DOUBLELINE
            2:
                s.formation = Squad.Formation.TRIPLELINE
            3:
                s.formation = Squad.Formation.SQUARE
            4:
                s.formation = Squad.Formation.SKIRMISH
            5:
                s.formation = Squad.Formation.COLUMN
        add_child(s)
        squads.append(s)
    for dt in [Squad.DamageType.MELEE, Squad.DamageType.CHARGE, Squad.DamageType.MISSLE, Squad.DamageType.ARTILLERY]:
        for i in range(total):
            for j in range(total):
                var dice_attack : int = squads[i].GetDieCountInAttack(dt)
                var dice_defense : int = squads[j].GetDieCountInAttack(dt)
                var mods : Vector2i = Squad.CalculateDieMods(squads[i].formation, squads[j].formation, dt)
                var dice : int = max(dice_attack, dice_defense)
                var attack_damage : int = 0
                var defense_damage : int = 0
                for times in range(100):
                    for d in range(dice):
                        var attack_roll : int = rnd.randi() % (6 + mods.x)
                        var defense_roll : int = rnd.randi() % (6 + mods.y)
                        if d >= dice_attack:
                            var second_roll : int = rnd.randi() % (6 + mods.x)
                            attack_roll = min(second_roll, attack_roll)
                        if d >= dice_defense:
                            var second_roll : int = rnd.randi() % (6 + mods.x)
                            defense_roll = min(second_roll, defense_roll)
                        if attack_roll > defense_roll:
                            attack_damage += 1
                        elif attack_roll < defense_roll:
                            if dt == Squad.DamageType.MELEE || dt == Squad.DamageType.CHARGE:
                                defense_damage += 1
                print(Squad.Formation.keys()[squads[i].formation], "(", Squad.DamageType.keys()[dt], ")", Squad.Formation.keys()[squads[j].formation], "=", float(attack_damage) / 100.0, " ", float(defense_damage) / 100.0)
    
func _process(delta: float) -> void:
    _mist_direction += delta * ((rnd.randf() * 1) - 0.5)
    _mist_speed = clampf(_mist_speed + delta * ((rnd.randf() * 0.5)), _mist_min_speed, _mist_max_speed)
    _mist_parallax_layer.motion_offset.x += delta * _mist_speed * sin(_mist_direction)
    _mist_parallax_layer.motion_offset.y += delta * _mist_speed * cos(_mist_direction)
    pass
