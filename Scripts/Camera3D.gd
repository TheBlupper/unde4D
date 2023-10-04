extends Camera3D

var width
var factor = 7
var scroll_factor = 1.1

@export var gimbal1: Node3D
@export var gimbal2: Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	transform.origin = Vector3(0, 0, 12)
	width = get_viewport().size.x
	gimbal2.rotate_x(deg_to_rad(-45))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass#gimbal1.position = origin

var panning = false
var panning_plane = null
var origin = Vector3.ZERO
func _input(event):
	if event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_MASK_MIDDLE and not panning:
			gimbal1.rotation.y -= factor*event.relative.x/width
			gimbal2.rotation.x -= factor*event.relative.y/width
			gimbal2.rotation.x = clamp(gimbal2.rotation.x, -PI/2, PI/2)
		if panning:
			#var p = panning_plane.normal * panning_plane.d
			var trans = global_transform
			trans.origin = Vector3.ZERO
			var up = trans*Vector3.UP
			var left = trans*Vector3.LEFT
			gimbal1.global_position += (left*event.relative.x + up*event.relative.y)*0.003*transform.origin.z
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE and !event.pressed and panning:
			panning = false
		if event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed and Input.is_key_pressed(KEY_CTRL):
			panning = true
		else:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				transform.origin.z /= scroll_factor
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				transform.origin.z *= scroll_factor
		#transform = transform.rotated(Vector3.RIGHT, factor*-event.relative.y/width)
		#transform = transform.rotated(Vector3.UP, factor*-event.relative.x/width)
		#transform = transform.rotated(Vector3.UP, event.relative.x)
