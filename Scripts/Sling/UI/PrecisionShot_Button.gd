extends ConsumableMenu_Button

@onready var highlight = $Highlight


signal set_aim_mode(mode : TrajectoryPreview.MODE)

func _on_pressed():
	if control is RadialContainer :
		
		if activated : 
			activated = false
			highlight.modulate = Color(1,1,1,0)
			set_aim_mode.emit(TrajectoryPreview.MODE.VECTOR)

		else :
			activated = true
			highlight.modulate = Color(1,1,1,1)
			set_aim_mode.emit(TrajectoryPreview.MODE.NEWTON)
		
		

func _on_shoot():
	SaveData.inventory[name] -= 1
	set_aim_mode.emit(TrajectoryPreview.MODE.VECTOR)
	activated = false
	highlight.modulate = Color(1,1,1,0)