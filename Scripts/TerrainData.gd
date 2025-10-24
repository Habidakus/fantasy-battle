class_name TerrainData extends RefCounted

const WORLD_SIZE : Vector2i = Vector2i(1130, 600)

var _rocks : Array[Rock]
#var _nav_agent : NavigationAgent2D = NavigationAgent2D.new()
#var _nav_region : NavigationRegion2D = NavigationRegion2D.new()
var _map_rid : RID
#var _region_rid : RID
var _nav_poly : NavigationPolygon
var _source_geom_data : NavigationMeshSourceGeometryData2D

# TODO: We should define all the unit's friendly allies as Navigation Obstacles that move about the map, so that we can path around them
#	var nav_obs : NavigationObstacle2D = NavigationObstacle2D.new()
#	nav_obs.affect_navigation_mesh = true
#	nav_obs.vertices = polygon_points

func Setup(rnd : RandomNumberGenerator, squadsAndRadiiSquared : Array, parent : Control, region : NavigationRegion2D) -> void:
    _map_rid = parent.get_world_2d().get_navigation_map()
    # TODO: Create multiple regions for different unit widths, and then when an agent is attempting to plot a course it would use the smallest region's RID and call it's set_navigation_map(region_rid)
    #var region_rid : RID = NavigationServer2D.region_create()
    NavigationServer2D.region_set_map(region.get_rid(), _map_rid)
    
    _nav_poly = region.navigation_polygon
    _nav_poly.agent_radius = 40
    var open_map : PackedVector2Array = PackedVector2Array([
        Vector2.ZERO - (WORLD_SIZE / 2.0),
        Vector2(WORLD_SIZE.x * 1.5, 0),
        WORLD_SIZE * 1.5, 
        Vector2(0, WORLD_SIZE.y * 1.5)])
    _nav_poly.add_outline(open_map)
    
    var poss : Array = []
    for r : int in range(25):
        var loc : Vector2i
        var close_to_squad : bool = true
        while close_to_squad:
            loc = Vector2i(rnd.randi() % WORLD_SIZE.x, rnd.randi() % WORLD_SIZE.y)
            close_to_squad = false
            for sar : Array in squadsAndRadiiSquared:
                if sar[0].distance_squared_to(loc) < sar[1]:
                    close_to_squad = true
        poss.append([loc, -1])
    for r1 : int in range(25):
        var p1 : Vector2i = poss[r1][0]
        var mind : int = WORLD_SIZE.x * WORLD_SIZE.x * 2
        for r2 : int in range(25):
            if r1 == r2:
                continue
            var p2 : Vector2i = poss[r2][0]
            var d : int = p1.distance_squared_to(p2)
            if d < mind:
                mind = d
        poss[r1][1] = mind
        
    _source_geom_data = NavigationMeshSourceGeometryData2D.new()
        
    poss.sort_custom(func(a,b) : return a[1] < b[1])
    #var set_of_polygons : Array[PackedVector2Array]
    for r : int in range(12):
        var rock : Rock = Rock.Create(rnd, poss[r][0])
        _rocks.append(rock)
        parent.add_child(rock)
        _source_geom_data.add_projected_obstruction(rock.GetMapPoints_Collision(), true)
        # TODO: Rather than create a rock, just create the points
        #set_of_polygons.append(rock.GetMapPoints())
        #rock.queue_free()

    #for polygon_points : PackedVector2Array in merge_multiple_polygons(set_of_polygons):
        #_source_geom_data.add_projected_obstruction(polygon_points, true)
        #var rock : Rock = Rock.CreateFromPolygon(polygon_points, rnd)
        #_rocks.append(rock)
        #parent.add_child(rock)

    NavigationServer2D.bake_from_source_geometry_data_async(_nav_poly, _source_geom_data, Callable(self, "_on_baking_completed").bind(parent.get_tree(), region.get_rid()))

func _on_baking_completed(tree : SceneTree, region_rid : RID) -> void:
    NavigationServer2D.region_set_navigation_polygon(region_rid, _nav_poly)
    NavigationServer2D.map_set_active(_map_rid, true)
    await tree.physics_frame

func GetPath(p1 : Vector2, p2 : Vector2) -> PackedVector2Array:
    if not _map_rid.is_valid():
        return []
    if not _nav_poly:
        return []
    var ret_val : PackedVector2Array = NavigationServer2D.map_get_path(_map_rid, p1, p2, true)
    return ret_val

func CheckForCollision(points : Array[Vector2], dest_points : Array[Vector2]) -> float:
    var shortened_length : float = WORLD_SIZE.length_squared()
    var point_count : int = points.size()
    for rock : Rock in _rocks:
        var rock_point_count : int = rock._collision_points.size()
        for rock_point_index : int in range(rock_point_count):
            var rp1 : Vector2 = rock._collision_points[rock_point_index] + rock.position
            var rp2 : Vector2 = rock._collision_points[(rock_point_index + 1) % rock_point_count] + rock.position
            for point_index in range(point_count):
                var hit_point = Geometry2D.segment_intersects_segment(points[point_index], dest_points[point_index], rp1, rp2)
                if hit_point != null:
                    var new_length : float = (hit_point - points[point_index]).length()
                    if new_length < shortened_length:
                        shortened_length = new_length
    return shortened_length

static func merge_multiple_polygons(polygons: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
    if polygons.is_empty():
        return []
    var ret_val : Array[PackedVector2Array] = [polygons[0]]
    for i in range(1, polygons.size()):
        var current_polygon = polygons[i]
        var found_merge : bool = false
        for j in range(ret_val.size()):
            if found_merge:
                continue
            var new_polygons = Geometry2D.merge_polygons(ret_val[j], current_polygon)
            if new_polygons.size() == 1:
                ret_val[j] = new_polygons[0]
                found_merge = true
        if found_merge == false:
            ret_val.append(current_polygon)
    return ret_val
