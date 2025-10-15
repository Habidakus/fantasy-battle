class_name VisibleSquad extends Node2D

func Config(squadType : Squad.SquadType, primaryColor : Color, secondaryColor : Color) -> void:
	var infantryNode : Node2D = find_child("Infantry") as Node2D
	var calvaryNode : Node2D = find_child("Calvary") as Node2D
	match squadType:
		Squad.SquadType.INFANTRY:
			infantryNode.show()
			calvaryNode.hide()
		Squad.SquadType.CAVALRY:
			infantryNode.hide()
			calvaryNode.show()
		_:
			assert(false, "Unknown squad type in VisibleSquad: " + Squad.SquadType.keys()[squadType])
			infantryNode.hide()
			calvaryNode.hide()
	_set_color(self, "Primary", primaryColor)
	_set_color(self, "Secondary", secondaryColor)

func _set_color(node : Node, prefix : String, color : Color) -> void:
	var len : int = prefix.length()
	for child : Node in node.get_children():
		if child.name.substr(0, len) == prefix:
			var p : Polygon2D = child as Polygon2D
			if p != null:
				p.color = color
				#print("Updating %s to use color %s (%s)" % [p, color, p.color])
		_set_color(child, prefix, color)
