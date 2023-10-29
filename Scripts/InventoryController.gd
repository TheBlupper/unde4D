extends GridContainer

class_name InventoryController

signal swap
signal move

@export var rows: int = 10

const Utils = preload("res://Scripts/Utils.gd")
var utils = Utils.new()

var item_slot_scene = preload('res://Prefabs/ItemSlot.tscn')

var slot_grid: Array[Array] = []
var slot_arr: Array = []
var selected_idx = 0
var selected_slot: String = ""

var cnum_re = RegEx.new()

func _ready():
	# https://stackoverflow.com/a/50428157/11239740
	cnum_re.compile("^(?=[iI.\\d+-])(?<real>[+-]?(?:\\d+(?:\\.\\d*)?|\\.\\d+)(?:[eE][+-]?\\d+)?(?![iI.\\d]))?(?<imag>[+-]?(?:(?:\\d+(?:\\.\\d*)?|\\.\\d+)(?:[eE][+-]?\\d+)?)?[iI])?$")
	
	var small = false
	if get_viewport().get_visible_rect().size.x <= 1920:
		small = true
		
	for im in range(rows):
		var row = []
		for re in range(columns):
			var instance: Panel = item_slot_scene.instantiate()
			instance.slot = Vector2(re, im)
			add_child(instance)
			if small: instance.make_small()
			instance.connect('split', split_handler)
			instance.connect('selected', selected_handler)
			instance.connect('move', move_handler)
			row.append(instance)
			slot_arr.append(instance)
		slot_grid.append(row)

func vec_to_string(v: Vector2):
	return "%d%+di" % [v.x, v.y]

func find_free_slot() -> String:
	for slot in slot_arr:
		if slot.item == null:
			return vec_to_string(slot.slot)
	return "0"

func split_handler(target):
	if selected_idx == null: return
	var source = slot_arr[selected_idx]
	if source.slot == target.slot: return
	if source.item == null: return
	if not (target.item == null or utils.compare_blocks(source.item, target.item)):
		return
	emit_signal("move",
		vec_to_string(source.slot),
		vec_to_string(target.slot),
		1)

func move_handler(target):
	if selected_idx == null: return
	var source = slot_arr[selected_idx]
	if source.slot == target.slot: return
	if source.item == null: return
	
	source.deselect()
	target.select()
	if target.item == null or utils.compare_blocks(source.item, target.item):
		emit_signal("move",
			vec_to_string(source.slot),
			vec_to_string(target.slot),
			int(source.item.count))
		return
		
	emit_signal("swap",
		vec_to_string(source.slot),
		vec_to_string(target.slot),
		find_free_slot(),
		int(source.item.count),
		int(target.item.count))

func selected_handler(sender):
	selected_idx = slot_arr.find(sender)
	selected_slot = vec_to_string(sender.slot)
	for slot in slot_arr:
		if not slot.is_selected: continue
		if slot == sender: continue
		slot.deselect()
		
func set_items(items: Array):
	var item_map = {}
	for item in items:
		item_map[utils.complex_to_vec(item.slot)] = item
	for im in range(rows):
		for re in range(columns):
			var slot = Vector2(re, im)
			if slot in item_map:
				slot_grid[im][re].set_item(item_map[slot])
				continue
			slot_grid[im][re].clear_item()

func get_selected_item():
	return slot_arr[selected_idx].item
