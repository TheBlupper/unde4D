extends Node2D

const color: = Color(0.8, 0.8, 0.8, 0.1)

var camera: Camera2D
var viewport: Viewport
var grid_size: Vector2 = Vector2(120, 120)
var selected_pos: Vector2 = Vector2(0, 0)

func _ready():
	viewport = get_viewport()
	camera = viewport.get_camera_2d()
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		selected_pos = (floor(get_global_mouse_position()/grid_size)*grid_size)*camera.zoom
	
func _process(delta):
	queue_redraw()

func _draw():
	var center = camera.get_screen_center_position()
	var vp_size = camera.get_viewport_rect().size
	var topleft = center - vp_size/2/camera.zoom
	var bottomright = center + vp_size/2/camera.zoom
	var w = bottomright.x - topleft.x
	var h = bottomright.y - topleft.y
	var x_count = w / grid_size.x
	var y_count = h / grid_size.y

	var left = floor(topleft.x / grid_size.x) * grid_size.x
	for _x in range(x_count):
		draw_line(Vector2(left, topleft.y), Vector2(left, bottomright.y), color)
		left += grid_size.x
		
	var top = floor(topleft.y / grid_size.y) * grid_size.y
	for _y in range(y_count):
		draw_line(Vector2(topleft.x, top), Vector2(bottomright.x, top), color)
		top += grid_size.y
	
	draw_rect(Rect2(
		-6*grid_size,
		13*grid_size
	), '6b6b6b10')
	draw_rect(Rect2(selected_pos/camera.zoom, grid_size), '6b6b6b7f')
