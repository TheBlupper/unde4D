extends GridContainer

class_name InventoryController

@export var rows: int = 10

var item_slot_scene = preload('res://Prefabs/ItemSlot.tscn')

var slots = []
var selected_idx = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	for row in range(rows):
		for col in range(columns):
			var instance = item_slot_scene.instantiate()
			add_child(instance)
			instance.connect('selected', handler)
			slots.append(instance)

func handler(sender):
	selected_idx = slots.find(sender)
	print(selected_idx)
	for slot in slots:
		if not slot.is_selected: continue
		if slot == sender: continue
		slot.deselect()
		
func set_items(items: Array):
	for i in range(len(slots)):
		if i < len(items):
			if slots[i].item == items[i]: continue
			slots[i].set_item(items[i])
			continue
		slots[i].clear_item()

		
func get_selected_item():
	return slots[selected_idx].item
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
