extends Camera2D

const ZOOM_FACTOR = 1.1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_MASK_MIDDLE:
			position -= event.relative / zoom
	if event is InputEventMouseButton:
		var pre = get_global_mouse_position()
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom /= ZOOM_FACTOR
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom *= ZOOM_FACTOR
		var post = get_global_mouse_position()
		global_position -= (post-pre)
