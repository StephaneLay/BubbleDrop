extends Bubble

@export var angular_impulse : float
@export var effect_radius : int

func OnShoot():
	angular_velocity = angular_impulse


func OnHit():
	var radius_bubbles = game_scene.get_cells_in_radius(position, effect_radius)
	game_scene.paint_radius(radius_bubbles, color)
