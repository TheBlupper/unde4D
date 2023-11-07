extends Panel

signal selected
signal deselected
signal move
signal split

@export var default_color: Color = '4d4d4d67'
@export var hover_color: Color = 'ffffff'
@export var selected_color: Color = 'ffffff'
@export var small_min_size: Vector2 = Vector2(40, 40)

var is_hovered: bool = false
var is_selected: bool = false
var slot: Vector2

@onready var texture_rect: TextureRect = $MarginContainer/TextureRect
@onready var count_label: Label = $VBoxContainer/ItemCount

var unknown_item = preload("res://Icons/Unknown.png")
var empty = Texture2D.new()
var item
var icons = {
	"dirt": preload("res://Icons/Grass.png"),
	"wood": preload("res://Icons/Wood.png"),
	"concrete": preload("res://Icons/Concrete.png"),
	"amethyst": preload("res://Icons/Amethyst.png"),
	"leaver": preload("res://Icons/Leaves.png"),
	"spawner": preload("res://Icons/Spawner.png"),
	"sword": preload("res://Icons/Sword.png"),
	"pickaxe": preload("res://Icons/Pickaxe.png"),
	"air": empty,
	"artery": preload("res://Icons/Artery.png"),
	"ventricle": preload("res://Icons/Ventricle.png"),
	"bone_marrow": preload("res://Icons/BoneMarrow.png"),
	"shield": preload("res://Icons/Shield.png"),
	"spider_legs": preload("res://Icons/SpiderLegs.png"),
	"soul": preload("res://Icons/Soul.png"),
	"compass": preload("res://Icons/Compass.png"),
	"health_potion": preload("res://Icons/HealthPotion.png"),
	"veilstone": preload("res://Icons/Veilstone.png")
}

func _ready():
	var style_box: StyleBoxFlat = get_theme_stylebox('panel').duplicate()
	style_box.border_width_right = 3
	style_box.border_width_bottom = 3
	style_box.border_color = '1e1e1e41'
	style_box.set_corner_radius_all(5)
	style_box.bg_color = default_color
	add_theme_stylebox_override('panel', style_box)
	
func make_small():
	custom_minimum_size = small_min_size
	count_label.label_settings.font_size = 12
	
func update_tooltip():
	if item == null:
		tooltip_text = ""
		return
	var text = item.type + "\n"
	for key in item.keys():
		if key in ["slot", "type", "mesh_instance", "count"]: continue
		text += "%s = %s\n" % [key, item[key]]
	tooltip_text = text

func select():
	is_selected = true
	change_bg_color(selected_color)
	emit_signal('selected', self)

func deselect():
	is_selected = false
	change_bg_color(default_color)
	emit_signal('deselected', self)

func set_item(new_item):
	var icon = icons.get(new_item.type, unknown_item)
	item = new_item
	count_label.text = "x%s" % item.count
	texture_rect.texture = icon
	update_tooltip()
	
func clear_item():
	item = null
	count_label.text = ""
	texture_rect.texture = empty
	update_tooltip()

func _input(event):
	if event is InputEventMouseButton:
		if !event.pressed and is_hovered:
			if event.button_index == MOUSE_BUTTON_LEFT:
				select()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				emit_signal("move", self)
			elif event.button_index == MOUSE_BUTTON_MIDDLE:
				emit_signal("split", self)

func change_bg_color(color: Color):
	var style_box: StyleBoxFlat = get_theme_stylebox('panel').duplicate()
	style_box.bg_color = color
	add_theme_stylebox_override('panel', style_box)

func _on_mouse_entered():
	is_hovered = true
	if not is_selected: change_bg_color(hover_color)


func _on_mouse_exited():
	is_hovered = false
	if not is_selected: change_bg_color(default_color)
