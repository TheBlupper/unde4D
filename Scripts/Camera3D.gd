extends Camera3D

var width
var scroll_factor = 1.1

@export var rot_speed = 7
@export var pan_speed = 0.003
@export var gimbal1: Node3D
@export var gimbal2: Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	transform.origin = Vector3(0, 0, 12)
	width = get_viewport().size.x
	gimbal2.rotate_x(deg_to_rad(-45))

var panning = false
var pan_up = Vector3.UP
var pan_left = Vector3.LEFT
var panning_plane = null
var origin = Vector3.ZERO
func _input(event):
	if event is InputEventMouseMotion:
		if Input.is_key_pressed(KEY_SHIFT) and not panning:
			gimbal1.rotation.y -= rot_speed*event.relative.x/width
			gimbal2.rotation.x -= rot_speed*event.relative.y/width
			gimbal2.rotation.x = clamp(gimbal2.rotation.x, -PI/2, PI/2)
		if panning:
			gimbal1.global_position += (
				pan_left*event.relative.x + pan_up*event.relative.y
			)*transform.origin.z*pan_speed

	if event is InputEventKey:
		if event.keycode == KEY_CTRL and !event.pressed and panning:
			panning = false
		if event.keycode == KEY_CTRL and event.pressed:
			panning = true
			
			var trans = global_transform
			trans.origin = Vector3.ZERO
			pan_up = trans*Vector3.UP
			pan_left = trans*Vector3.LEFT
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			transform.origin.z /= scroll_factor
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			transform.origin.z *= scroll_factor
