class_name VisibleSquad extends Node2D

func Config(squadType : Squad.SquadType, primaryColor : Color, secondaryColor : Color) -> void:
	var infantryNode : Node2D = find_child("Infantry") as Node2D
	var calvaryNode : Node2D = find_child("Calvary") as Node2D
	var arrowNode : Node2D = find_child("Arrow") as Node2D
	_store_polygons(arrowNode)
	match squadType:
		Squad.SquadType.INFANTRY:
			infantryNode.show()
			calvaryNode.hide()
			_store_polygons(infantryNode)
		Squad.SquadType.CAVALRY:
			infantryNode.hide()
			calvaryNode.show()
			_store_polygons(calvaryNode)
		_:
			assert(false, "Unknown squad type in VisibleSquad: " + Squad.SquadType.keys()[squadType])
			infantryNode.hide()
			calvaryNode.hide()
	_set_color(self, "Primary", primaryColor)
	_set_color(self, "Secondary", secondaryColor)

func Update(squad : Squad) -> void:
	position = squad.position
	rotation = squad.rotation
	_set_size(squad.GetDim())
	
var _polygons : Dictionary = {}

func _store_polygons(node : Node) -> void:
	for child : Node in node.get_children():
		var p :Polygon2D = child as Polygon2D
		if p == null:
			continue
		var copy_poly : PackedVector2Array = PackedVector2Array(p.polygon)
		_polygons[p] = copy_poly

func _set_size(dim : Vector2) -> void:
	var x_mult = dim.y / 20.0
	var y_mult = dim.x / 20.0
	for p : Polygon2D in _polygons.keys():
		for i in range(_polygons[p].size()):
			p.polygon[i] = Vector2(x_mult * _polygons[p][i].x,y_mult * _polygons[p][i].y)

func _set_color(node : Node, prefix : String, color : Color) -> void:
	var _len : int = prefix.length()
	for child : Node in node.get_children():
		if child.name.substr(0, _len) == prefix:
			var p : Polygon2D = child as Polygon2D
			if p != null:
				p.color = color
				#print("Updating %s to use color %s (%s)" % [p, color, p.color])
		_set_color(child, prefix, color)
