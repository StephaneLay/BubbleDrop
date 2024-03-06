extends Node2D

var level_data_base = preload("res://Resources/levels_resource.tres")
var debug_level_button = preload("res://scenes/debug_level_button.tscn")
var bubble_prefab = preload("res://scenes/bubble.tscn")
var neighbors_coord : Array[Vector2] 

@export var cell_size : Vector2
var grid_data = {} #coord V2 : node bubble
var attempts : int
var treshold : float
var root_node_pos : Vector2
var astar = AStar2D.new()


@onready var sling = $Sling
@onready var debug_hud = $CanvasLayer/Label
@onready var canvas_layer = $CanvasLayer
@onready var buttons_container = $CanvasLayer/ButtonContainer
@onready var bubble_container = $BubbleContainer
@onready var camera : CameraController = $CameraSystem/Camera2D
const COLOR_ATLAS_RESOURCE = preload("res://Resources/ColorAtlas_Resource.tres")


func _ready():
	init_level_buttons()
	set_neighbors_coord(cell_size)


func add_bubble_to_grid(projectile : RigidBody2D , grid_bubble : RigidBody2D):
	var empty_cells = get_neighbors(grid_bubble,level_data.BubbleColor.Empty)
	var closest_empty_cell
	var magnitude
	for empty_cell in empty_cells :
		var l : Vector2 = projectile.position - empty_cell
		if magnitude == null or l.length_squared() < magnitude :
			magnitude = l.length_squared()
			closest_empty_cell = empty_cell
	projectile.position = closest_empty_cell
	grid_data[projectile.position] = projectile
	projectile.trail.enabled = false
	process_destruction(get_cells_to_destroy(projectile))
	sling.call_deferred("load_ball")

func process_destruction(cells):
	if cells.size()>= 3 :
		for cell in cells :
			grid_data[cell].OnDestroy()
			await grid_data[cell].animTrigger 
			grid_data[cell] = null


func get_cells_to_destroy(grid_bubble):
	var cells_to_destroy = {grid_bubble.position : grid_bubble }
	var cells_to_check : Array[Vector2] = []
	cells_to_check.append(grid_bubble.position)
	while cells_to_check.size() >0 :
		if get_neighbors(grid_data[cells_to_check[0]],grid_data[cells_to_check[0]].color).size() >0:
			var cell_neighbors = get_neighbors(grid_data[cells_to_check[0]],grid_data[cells_to_check[0]].color)
			for cell_neighbor in cell_neighbors :
				if cells_to_destroy.has(cell_neighbor):
					continue
				else : 
					cells_to_destroy[cell_neighbor] =  grid_data[cell_neighbor]
					cells_to_check.append(cell_neighbor)
		cells_to_check.remove_at(0)
	return cells_to_destroy


func get_neighbors(cell : RigidBody2D ,color : level_data.BubbleColor):
	var neighbors = {}
	for dir in neighbors_coord:
		var neighbor
		if grid_data.has(cell.position + dir):
			neighbor = grid_data[cell.position + dir]
		else : continue
		if color != level_data.BubbleColor.Empty and neighbor != null and neighbor.color == color or color == level_data.BubbleColor.Empty and neighbor == null :
			neighbors[cell.position + dir] = neighbor
	return neighbors

func init_level_buttons() :
	for level in level_data_base.levels :
		var button = debug_level_button.instantiate()
		buttons_container.add_child(button)
		button.init_button(level,self)

func load_level(_level):
	var levelres = level_data_base.levels[_level]
	attempts = levelres.attempts
	treshold = levelres.treshold
	root_node_pos = levelres.root_node_coord
	for i in range(levelres.coord.size()):
		if levelres.bubbles[i] == level_data.BubbleColor.Empty :
			grid_data[levelres.coord[i]] = null
		else :
			var bubbleInstance = bubble_prefab.instantiate()
			bubble_container.add_child(bubbleInstance)
			bubbleInstance.position = levelres.coord[i]
			bubbleInstance.color = levelres.bubbles[i]
			bubbleInstance.freeze= true
			debug_assign_color(bubbleInstance)
			grid_data[levelres.coord[i]] = bubbleInstance
	buttons_container.hide()
	sling.init_sling(attempts)
	camera.EnableControls(true)
	astar.clear()
	set_up_astar()

func set_up_astar():
	for coord in grid_data:
		if grid_data[coord] != null:
			astar.add_point(astar.get_available_point_id(),coord)
	for point in astar.get_point_ids() :
		var neighbors_c : Array[Vector2] = []
		var point_coord : Vector2 = astar.get_point_position(point)
		for dir in neighbors_coord:
			if grid_data[point_coord + dir] != null:
				neighbors_c.append(point_coord+dir)
		for n in neighbors_c:
			var n_index = astar.get_closest_point(n)
			if astar.are_points_connected(point,n_index) == false :
				astar.connect_points(point,n_index)


func debug_display_hud(a):
	debug_hud.text = "attempts : " + str(a)

func debug_assign_color(_bubble : Bubble):
	match(_bubble.color):
		level_data.BubbleColor.Empty: pass
		level_data.BubbleColor.Red: _bubble.sprite.frame = 1
		level_data.BubbleColor.Orange: _bubble.sprite.frame = 2
		level_data.BubbleColor.Yellow: _bubble.sprite.frame = 3
		level_data.BubbleColor.Green: _bubble.sprite.frame = 4
		level_data.BubbleColor.Cyan: _bubble.sprite.frame = 5
		level_data.BubbleColor.Blue: _bubble.sprite.frame = 6
		level_data.BubbleColor.Purple: _bubble.sprite.frame = 7
		_: print("Bubble " + _bubble.name + " does not have recognized color") 
	
	_bubble.particleSystem.Init(_bubble.color)
	_bubble.trail.material.set_shader_parameter ("TrailColor", COLOR_ATLAS_RESOURCE.GetColor(_bubble.color))

func set_neighbors_coord(v : Vector2):
	neighbors_coord.append(Vector2(v.x,0))
	neighbors_coord.append(Vector2(-v.x,0))
	var x = v.x / 2
	var y = v.y * 3 /4
	neighbors_coord.append(Vector2(x,y))
	neighbors_coord.append(Vector2(-x,y))
	neighbors_coord.append(Vector2(x,-y))
	neighbors_coord.append(Vector2(-x,-y))
