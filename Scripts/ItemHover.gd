extends Panel

signal selected
signal deselected

@export var default_color: Color = '4d4d4d67'
@export var hover_color: Color = 'ffffff'
@export var selected_color: Color = 'ffffff'

var is_hovered: bool = false
var is_selected: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	var style_box: StyleBoxFlat = get_theme_stylebox('panel').duplicate()
	style_box.border_width_right = 3
	style_box.border_width_bottom = 3
	style_box.border_color = '1e1e1e41'
	style_box.set_corner_radius_all(5)
	style_box.bg_color = default_color
	add_theme_stylebox_override('panel', style_box)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func select():
	is_selected = true
	change_bg_color(selected_color)
	emit_signal('selected', self)

func deselect():
	is_selected = false
	change_bg_color(default_color)
	emit_signal('deselected', self)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and is_hovered:
			select()

func change_bg_color(color: Color):
	var style_box: StyleBoxFlat = get_theme_stylebox('panel').duplicate()
	style_box.bg_color = color
	add_theme_stylebox_override('panel', style_box)

func _on_mouse_entered():
	is_hovered = true
	if not selected: change_bg_color(hover_color)


func _on_mouse_exited():
	is_hovered = false
	if not selected: change_bg_color(default_color)
