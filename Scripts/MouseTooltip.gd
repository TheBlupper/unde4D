extends Control

class_name MouseTooltip

@export var offset: Vector2 = Vector2(15, 15)
@onready var text_label: RichTextLabel = $PanelContainer/MarginContainer/RichTextLabel

func display_entity(entity: Dictionary):
	entity = entity.duplicate()
	var text = ''
	text += '[b][font_size=18]' + entity.type.capitalize() + '[/font_size][/b]\n'

	if entity.type in ['player', 'monster']:
		var stats = Utils.parse_inventory(entity.inventory)
		text += '[i]HP:[/i] %s/%s\n' % [entity.hp, entity.max_hp]
		text += '[i]Shield:[/i] %d%+di\n' % [stats.shield.x, stats.shield.y]
		text += '[i]Regeneration:[/i] %d\n' % stats.regen
		
		
		var inventory: Dictionary = entity.inventory
		var items = {}
		
		if len(inventory) > 0: text += '[i]Inventory:[/i]\n[ul]'
		for key in inventory.keys():
			var item = inventory[key].duplicate()
			var item_type = item.type
			var item_count = item.count
			if item_type not in items:
				items[item_type] = 0
			items[item_type] += int(item_count)
			continue
			item.erase('count')
			item.erase('type')
			var extra = ''
			if len(item) != 0:
				for prop in item:
					if extra: extra += ', '
					extra += '%s=%s' % [prop, item[prop]]
			if len(extra) > 0:
				text += '[i]%s[/i] x%s (%s)\n' % [item_type, item_count, extra]
			else:
				text += '[i]%s[/i] x%s\n' % [item_type, item_count]
			#print('[i]%s[/i] x%d\n')
			#print('[i]%s[/i] x%d\n' % [item_type, item_count])
		
		for item_type in items.keys():
			text += '[i]%s[/i] x%d\n' % [item_type, items[item_type]]
		if len(inventory) > 0: text += '[/ul]'
	text_label.text = text

func _ready():
	hide()

func _process(delta):
	set_position(get_global_mouse_position() + offset)
