extends MeshInstance3D

@export_group("Textures")
@export var ghost_texture: Texture
@export var monster_texture: Texture
@export var player_texture: Texture
@export var other_player_texture: Texture
@export var unknown_texture: Texture
@export var tombstone_texture: Texture

@export_group("Random stuff")
@export var font: Font

@export_group("Nodes")
@export var hp_label: Label
@export var xp_label: Label
@export var level_label: Label
#@export var inventory_list: ItemList
@export var inventory_controller: InventoryController
@export var camera: Camera3D
@export var auto_kill_checkbox: CheckButton
@export var auto_mine_checkbox: CheckButton
@export var show_moves_checkbox: CheckButton
@export var exclude_players_checkbox: CheckButton
@export var exclude_ghosts_checkbox: CheckButton
@export var z_axis_up_checkbox: CheckButton
@export var render_distance_spinbox: SpinBox
@export var render_up_spinbox: SpinBox
@export var render_down_spinbox: SpinBox
@export var debug_move_label: Label
@export var render_rock_checkbox: CheckButton
@export var render_veilstone_checkbox: CheckButton
@export var auto_loot_checkbox: CheckButton

const Utils = preload("res://Scripts/Utils.gd")
var utils: Utils = Utils.new()

var strength_calculator = preload("res://Scripts/StrengthCalculator.cs").new()

var concrete_scene = preload("res://Prefabs/Concrete.tscn")
var rock_scene = preload("res://Prefabs/Rock.tscn")
var unknown_block_scene = preload("res://Prefabs/UnknownBlock.tscn")
var wood_scene = preload("res://Prefabs/Wood.tscn")
var dirt_scene = preload("res://Prefabs/Dirt.tscn")
var tombstone_scene = preload("res://Prefabs/Tombstone.tscn")
var leaves_scene = preload("res://Prefabs/Leaves.tscn")
var spawner_scene = preload("res://Prefabs/Spawner.tscn")
var amethyst_scene = preload("res://Prefabs/Amethyst.tscn")
var mystery_scene = preload("res://Prefabs/Mystery.tscn")
var air_scene = preload("res://Prefabs/Air.tscn")
var veilstone_scene = preload("res://Prefabs/Veilstone.tscn")

var player_scene = preload("res://Prefabs/Player.tscn")
var other_player_scene = preload("res://Prefabs/OtherPlayer.tscn")
var enemy_scene = preload("res://Prefabs/Enemy.tscn")
var ghost_scene = preload("res://Prefabs/Ghost.tscn")
var unknown_entity_scene = preload("res://Prefabs/UnknownEntity.tscn")

var websocket_url = "wss://daydun.com:666/"
var player_name = "blupper";

var socket = WebSocketPeer.new()

var map = {}
var entities = []
var last_entity_fetch = 0;

var hp = '0'
var next_moves = []

var cursor_material: Material
var selected_square: Vector2

@onready var render_distance = render_distance_spinbox.value
@onready var render_up = render_up_spinbox.value
@onready var render_down = render_down_spinbox.value

func _ready():
	update_look_offsets()
	
	inventory_controller.connect("move", move_slot_handler)
	inventory_controller.connect("swap", swap_slots_handler)
	
	cursor_material = StandardMaterial3D.new()
	cursor_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cursor_material.albedo_color = 'ffffff20'
	
	var mesh_material = StandardMaterial3D.new()
	mesh_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_material.albedo_color = 'ffffff08'
	var grid_instance = MeshInstance3D.new()
	var grid_mesh = BoxMesh.new()
	grid_mesh.size = Vector3(13, 0.1, 13)
	grid_mesh.material = mesh_material
	grid_instance.mesh = grid_mesh
	add_child(grid_instance)
	grid_instance.translate(Vector3(0, -0.5, 0))
	
	print("Connecting...")
	socket.connect_to_url(websocket_url)
	socket.inbound_buffer_size = 1024*1024*8
	socket.outbound_buffer_size = 1024*1024*8
	socket.max_queued_packets = 1024*16
	
func get_air_positions():
	var air_positions = []
	for x in range(-1, 2):
		for y in range(-1, 2):
			for z in range(-1, 2):
				if x == 0 and y == 0 and z == 0: continue
				var pos = from_world(Vector3(x, y, z))
				if pos not in map: continue
				if map[pos].type != "air": continue
				air_positions.append(pos)
	return air_positions

# this assumes that target_slot is empty, it should only be called
# from the inventory_controller
func move_slot_handler(source_slot: String, target_slot: String, count: int):
	var air_positions = get_air_positions()
	if len(air_positions) < 1: return
	var pos = air_positions[0]
	for i in range(count):
		interact_4d(pos, source_slot)
		interact_4d(pos, target_slot)
	
func swap_slots_handler(
	slot1: String,
	slot2: String,
	temp_slot: String,
	count1: int, count2: int):
	var air_positions = get_air_positions()
	if len(air_positions) < 1: return
	var pos = air_positions[0]

	for i in range(count1):
		interact_4d(pos, slot1)
		interact_4d(pos, temp_slot)
		
	for i in range(count2):
		interact_4d(pos, slot2)
		interact_4d(pos, slot1)
		
	for i in range(count1):
		interact_4d(pos, temp_slot)
		interact_4d(pos, slot2)

func _process(_delta):
	socket.poll()
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			handle_packet(JSON.parse_string(socket.get_packet().get_string_from_utf8()))
	elif state == WebSocketPeer.STATE_CLOSING:
		print("websocket closing...")
	elif state == WebSocketPeer.STATE_CLOSED:
		print("websocket closed")
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		set_process(false) # Stop processing.
		get_tree().quit()
	
	var vec = get_keyboard_vec()
	debug_move_label.text = "%d%+di %d%+di" % [vec.x, vec.z, vec.y, vec.w]
	if interacting:
		debug_move_label.text += " (interacting, slot %s)" % interact_slot
		
var highlight_square = null
var interacting = false
var interact_slot = null
var num_map = {
	KEY_0: 0,
	KEY_1: 1,
	KEY_2: 2,
	KEY_3: 3,
	KEY_4: 4,
	KEY_5: 5,
	KEY_6: 6,
	KEY_7: 7,
	KEY_8: 8,
	KEY_9: 9
}


func get_selected_slot() -> String:
	var item = inventory_controller.get_selected_item()
	if item == null: return find_free_slot()
	return item.slot

func lookup_slot(idx: int) -> String:
	return inventory[idx].slot

func _input(event: InputEvent) -> void:
	# Key Pressed
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_I:
			break_4d(Vector4(0, 0, 0, -1))
		if event.keycode == KEY_O:
			break_4d(Vector4(0, 0, 0, 1))
	
	# Key Released
	if event is InputEventKey and !event.pressed:
		if event.keycode == KEY_ESCAPE:
			if interacting:
				interacting = false
			else:
				interact_slot = inventory_controller.selected_slot
				interacting = true
		elif event.keycode == KEY_ENTER and interacting:
			if interact_slot == null:
				break_4d(get_keyboard_vec())
			else:
				interact_4d(get_keyboard_vec(), interact_slot)
		elif event.keycode == KEY_M and interacting:
			next_moves.push_back(get_keyboard_vec())
		elif interacting and event.keycode in num_map:
			var idx = num_map[event.keycode]
			if idx >= len(inventory): return
			interact_slot = idx
		elif event.keycode == KEY_SPACE and interacting:
			interact_slot = null
		elif event.keycode == KEY_J:
			next_moves.push_back(Vector4(0, 0, -1, 0))
		elif event.keycode == KEY_L:
			next_moves.push_back(Vector4(0, 0, 1, 0))
		elif event.keycode == KEY_H and interacting:
			var dir = get_keyboard_vec()
			var pos = Vector4(dir.x, dir.y, 0, 1)
			if pos in map:
				break_4d(pos)
				next_moves.push_back(pos)
			pass
			#var dir = get_keyboard_vec()
			#interact_4d(Vector4(dir.x, dir.y, dir.z, 0), lookup_slot(interact_slot_idx))
			#next_moves.push_front(Vector4(dir.x, dir.y, dir.z, 1))
			
		elif event.keycode == KEY_B and interacting:
			var dir = get_keyboard_vec()
			var pos = Vector4(dir.x, dir.y, 0, -1)
			if pos in map:
				break_4d(pos)
				next_moves.push_back(pos)
			#var dir = get_keyboard_vec()
			#interact_4d(Vector4(dir.x, dir.y, dir.z, -1), lookup_slot(interact_slot_idx))
			#next_moves.push_front(Vector4(dir.x, dir.y, dir.z, 0))
			break_4d(get_keyboard_vec())
				
		elif event.keycode == KEY_F and Input.is_key_pressed(KEY_CTRL):
			var fn = Time.get_datetime_string_from_system() + '.json'
			var file = FileAccess.open('user://' + fn, FileAccess.WRITE)
			
			var clean_map = []
			for key in map.keys():
				var block = map[key].duplicate()
				block.erase('mesh_instance')
				block['pos'] = key
				clean_map.append(block)
				
			file.store_string(JSON.stringify(clean_map))
		elif event.keycode == KEY_R:
			next_moves = []
			for pos in map:
				var block_mesh = map[pos].mesh_instance
				if block_mesh != null:
					block_mesh.queue_free()
			map = {}
	
		
	if event is InputEventMouseButton and \
	!event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			var slot = get_selected_slot()
			if slot == '': return
			interact_4d(Vector4(selected_square.x, selected_square.y, 0, 0), slot)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			break_4d(Vector4(selected_square.x, selected_square.y, 0, 0))
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			print(map.get(Vector4(selected_square.x, selected_square.y, 0, 0)))
			for ent in entities:
				if ent.pos.x == selected_square.x and ent.pos.y == selected_square.y:
					print(ent)
					if ent.type in ['player', 'monster']:
						print(utils.parse_inventory(ent.inventory))
			
		
	if event is InputEventMouseMotion:
		if highlight_square != null:
			highlight_square.queue_free()
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * camera.far
		
		var cursorPos = Plane(Vector3(0, 1, 0), -0.5).intersects_ray(from, to)
		if cursorPos == null:
			return
		
		cursorPos += Vector3(0, 1, 0)
		var inst = MeshInstance3D.new()
		var cursor_mesh = BoxMesh.new()
		cursor_mesh.material = cursor_material
		inst.mesh = cursor_mesh
		inst.translate(floor(cursorPos))
		selected_square = Vector2(floor(cursorPos.x), floor(cursorPos.z))
		add_child(inst)
		highlight_square = inst

func interact_4d(pos: Vector4, slot=-1) -> void:
	if typeof(slot) != TYPE_STRING:
		slot = str(slot)
	socket.send_text(JSON.stringify({
		"type": "interact",
		"x": "%d%+dj"%[pos[0], pos[2]],
		"y": "%d%+dj"%[-pos[1], pos[3]],
		"slot": slot
	}))


func get_items_of_type(type: String) -> Array:
	var out = []
	for item in inventory:
		if item.type != type: continue
		out.append(item)
	return out
	
	
func find_free_slot() -> String:
	return inventory_controller.find_free_slot()
	var slot = 0
	var failed = true
	while failed:
		slot += 1
		failed = false
		for item in inventory:
			if str(item.slot) == str(slot):
				failed = true
				break
	return str(slot)
	

func kill_4d(pos: Vector4, enemy_hp: Vector2, shield: Vector2 = Vector2.ZERO) -> bool:
	var swords = get_items_of_type("sword")
	swords.append({
		'strength': '1',
		'slot': find_free_slot()
	})
	
	var sword_vecs = []
	for sword in swords:
		var v = utils.complex_to_vec(sword.strength)
		v.x = max(v.x-shield.x, 0)
		v.y = max(v.y-shield.y, 0)
		sword_vecs.append(v)
	var solution = strength_calculator.Solve(sword_vecs, enemy_hp)
	
	print('killing, shield=%s hp=%s, swords=%s solution=%s'%[shield, enemy_hp, sword_vecs, solution])
	if solution == null or len(solution) != len(sword_vecs): return false
	
	for i in range(len(solution)):
		var count = solution[i]
		if count == 0: continue
		for j in range(count):
			interact_4d(pos, swords[i].slot)
	return true

func break_4d(pos: Vector4) -> void:
	var slot = find_free_slot()
	if pos in map:
		if map[pos].type == "rock" and map[pos].get('strength') != null:
			var pickaxes = get_items_of_type("pickaxe")
			pickaxes.append({
				'strength': '1',
				'slot': slot
			})
			var pickaxe_vecs = []
			for pickaxe in pickaxes:
				pickaxe_vecs.append(utils.complex_to_vec(pickaxe.strength))
			var solution = strength_calculator.Solve(pickaxe_vecs, utils.complex_to_vec(map[pos].strength))
			print('breaking, strength=%s, pickaxes=%s solution=%s'%[map[pos].strength,pickaxe_vecs,solution])

			if solution == null or len(solution) != len(pickaxes): return
			
			for j in range(len(solution)):
				var count = solution[j]
				if count == 0: continue
				for k in range(count):
					interact_4d(pos, pickaxes[j].slot)
			return
			
		for item in inventory:
			if utils.compare_blocks(item, map[pos]):
				slot = item.slot
	interact_4d(pos, slot)
	
	
func move_4d(pos: Vector4) -> void:
	var x = "%d%+dj"%[pos[0], pos[2]]
	var y = "%d%+dj"%[-pos[1], pos[3]]
	socket.send_text(JSON.stringify({
		"type": "move",
		"x": x,
		"y": y
	}))


var loot_blocks = [
	'sword',
	'pickaxe',
	'artery',
	'ventricle',
	'bone_marrow',
	'health_potion',
	'shield',
	'soul',
	'ventrcle',
	'sheld',
	'spider_legs',
	'compass',
	'multiplier'
]
	
func update_map(new_map: Array, offset: Vector4 = Vector4.ZERO) -> void:
	for y in range(6, -7, -1):
		for x in range(6, -7, -1):
			var block = new_map[14-(y+7)][x+7]
			var pos = Vector4(x, y, 0, 0) + offset
			
			
			if pos in map:
				var prev_block = map[pos].duplicate()
				# v stupid?
				prev_block.erase('mesh_instance')
				if prev_block == block:
					continue
			
			var instance = null
			if block.type == "hypercube":
				block.type = "veilstone"
			if block.type == "air":
				instance = air_scene.instantiate()
				instance.visible = (!render_rock_checkbox.button_pressed) or (!render_veilstone_checkbox.button_pressed)
			elif block.type == "rock":
				instance = rock_scene.instantiate()
				instance.visible = render_rock_checkbox.button_pressed
			elif block.type == 'concrete':
				instance = concrete_scene.instantiate()
			elif block.type == "wood":
				instance = wood_scene.instantiate()
			elif block.type == "dirt":
				instance = dirt_scene.instantiate()
			elif block.type == "leaves":
				instance = leaves_scene.instantiate()
			elif block.type == "spawner":
				instance = spawner_scene.instantiate()
			elif block.type == "amethyst":
				instance = amethyst_scene.instantiate()
			elif block.type == "hypercube":
				instance = veilstone_scene.instantiate()
			elif block.type == "veilstone":
				instance = veilstone_scene.instantiate()
				instance.visible = render_veilstone_checkbox.button_pressed
			elif block.type == "mystery":
				instance = mystery_scene.instantiate()
			elif block.type == "tombstone":
				instance = tombstone_scene.instantiate()
				#instance.set_text(block.text.left(32))
				instance.set_font_size(40)
			else:
				instance = unknown_block_scene.instantiate()
				instance.set_text(block.type)
				instance.set_font_size(32)
			
			if instance != null:
				instance.translate(to_world(pos))
				add_child(instance)
			block.mesh_instance = instance
			if pos in map and map[pos].mesh_instance != null:
				map[pos].mesh_instance.queue_free()
			map[pos] = block
			
			
			if abs(pos.x) <= 1 and abs(pos.y) <= 1 and abs(pos.w) <= 1 and pos.z == 0\
			and (pos.x != 0 or pos.y != 0 or pos.w != 0):
				if auto_mine_checkbox.button_pressed and block.type != "air":
					break_4d(Vector4(pos.x, pos.y, 0, pos.w))
				elif auto_loot_checkbox.button_pressed and block.type in loot_blocks:
					break_4d(Vector4(pos.x, pos.y, 0, pos.w))

func lte(v1: Vector4, v2: Vector4):
	return (v1.x <= v2.x) and \
		(v1.y <= v2.y) and \
		(v1.z <= v2.z) and \
		(v1.w <= v2.w)
		
func gte(v1: Vector4, v2: Vector4):
	return (v1.x >= v2.x) and \
		(v1.y >= v2.y) and \
		(v1.z >= v2.z) and \
		(v1.w >= v2.w)

func clear_entities(lower_bound: Vector4, upper_bound: Vector4):
	var new_entities = []
	for old_entity in entities:
		if lte(old_entity.pos, upper_bound) and gte(old_entity.pos, lower_bound):
			if old_entity.instance != null:
				old_entity.instance.queue_free()
		else:
			new_entities.append(old_entity)
	entities = new_entities

var inventory = []
func update_entities(new_entities: Array, offset: Vector4 = Vector4.ZERO, ignore_player: bool = false) -> void:
	last_entity_fetch += 1
	for entity in new_entities:
		if entity.type == "player" and entity.name == player_name:
			if ignore_player: continue
			
			hp = entity.hp
			hp_label.text = "HP: %s/%s" % [entity.hp, entity.max_hp]
			xp_label.text = "XP: %s" % [entity.xp]
			level_label.text = "Level: %s" % [entity.level]
			inventory = []
			var keys = entity.inventory.keys()
			keys.sort()
			for key in keys:
				var item = entity.inventory[key].duplicate()
				item['slot'] = key
				inventory.append(item)
			inventory_controller.set_items(inventory)

		var pos = Vector4(int(entity['x']), -int(entity['y']), 0, 0) + offset
		var instance = null
		
		if auto_kill_checkbox.button_pressed and \
		(
			entity.type == "monster" or \
			(entity.type == "player" and entity.name != player_name and not exclude_players_checkbox.button_pressed) or \
			(entity.type == "ghost" and not exclude_ghosts_checkbox.button_pressed)
		) and \
		max(abs(pos.x), abs(pos.y)) <= 1 and \
		(pos.x != 0 or pos.y != 0):
			var enemy_hp = Vector2(4, 0)
			var shield = Vector2.ZERO
			var addend = 0
			if entity.type == "monster" or entity.type == "player":
				enemy_hp = utils.complex_to_vec(entity.hp)
				shield = utils.parse_inventory(entity.inventory)['shield']
				
			kill_4d(Vector4(pos.x, pos.y, 0, 0), enemy_hp, shield)
		
		if entity.type == "player":
			if entity.name == player_name:
				instance = player_scene.instantiate()
			else:
				instance = other_player_scene.instantiate()
			instance.set_text("%s %s/%s" % [entity.name, entity.hp, entity.max_hp])
			instance.set_constant_size(true)
			instance.set_font_size(64)
		elif entity.type == "monster":
			instance = enemy_scene.instantiate()
			instance.set_text("Monster %s/%s" % [entity.hp, entity.max_hp])
		elif entity.type == "ghost":
			instance = ghost_scene.instantiate()
			instance.set_text("Ghost")
		else:
			instance = unknown_entity_scene.instantiate()
			instance.set_text(entity.type)
			
		if instance != null:
			instance.translate(to_world(pos))
			add_child(instance)
		entity.instance = instance
		entity['pos'] = pos
		entities.append(entity)

func get_keyboard_vec() -> Vector4:
	var keyboard = Vector2(
		Input.get_axis("ui_left","ui_right"), 
		Input.get_axis("ui_up","ui_down"))
	var z = 0
	var w = 0
	
	if Input.is_key_pressed(KEY_W): w = 1
	elif Input.is_key_pressed(KEY_S): w = -1
	
	if Input.is_key_pressed(KEY_A): z = -1
	elif Input.is_key_pressed(KEY_D): z = 1
	if z_is_up:
		var tmp = w
		w = z
		z = tmp
	
	return Vector4(keyboard.x, keyboard.y, z, w)

func handle_packet(data: Dictionary) -> void:
	if data['type'] == 'connect': handle_connect(data)
	elif data['type'] == 'tick': handle_tick(data)
	elif data['type'] == 'move':handle_move(data)
	elif data['type'] == 'error': print(data)


func handle_connect(data: Dictionary) -> void:
	assert(data["version"] == 1)
	socket.send_text(JSON.stringify({
		"type": "connect",
		"name": player_name
	}))
	print("Connected to server")
	move_4d(Vector4(0, 0, 0, 0))
	
	
func handle_tick(data: Dictionary) -> void:
	update_map(data['map'])
	clear_entities(Vector4(-7, -7, 0, 0), Vector4(7, 7, 0, 0))
	update_entities(data['entities'])


var z_is_up = false
func to_world(pos: Vector4) -> Vector3:
	if z_is_up:
		return Vector3(pos.x, pos.z, pos.y)
	else:
		return Vector3(pos.x, pos.w, pos.y)

func from_world(pos: Vector3):
	if z_is_up:
		return Vector4(pos.x, pos.z, pos.y, 0)
	else:
		return Vector4(pos.x, pos.z, 0, pos.y)
		
func update_look_offsets():
	var chunks = int(render_distance)
	for pos in map:
		if map[pos].mesh_instance != null:
			map[pos].mesh_instance.queue_free()
	map = {}
	for ent in entities:
		if ent.instance != null:
			ent.instance.queue_free()
	entities = []
	look_offsets = []
	
	for level in range(-int(render_down), int(render_up)+1):
		for i in range(-chunks, chunks+1):
			for j in range(-chunks, chunks+1):
				if i == 0 and j == 0 and level == 0: continue
				look_offsets.append(from_world(Vector3(i*13, level, j*13)))
	
	look_counter = len(look_offsets)

var look_offsets = []
var look_counter = len(look_offsets)
var last_move_manual = false

var last_move
func handle_move(data: Dictionary) -> void:
	var failed_move = true
	for entity in data.entities:
		if entity.type == "player" and entity.name == player_name:
			if entity.x == "0" and entity.y == "0":
				failed_move = false
				
	if look_counter < len(look_offsets):
		var off =  look_offsets[look_counter]
		var view_sz = Vector4(7, 7, 0, 0)
		clear_entities(off - view_sz, off + view_sz)
		update_map(data['map'], off)
		update_entities(data['entities'], off, true)
		look_counter += 1
		return
		
	if not failed_move and last_move != Vector4.ZERO:
		# Last move succeeded
		if len(next_moves) != 0:
			print('moves left: %d' % len(next_moves))
		next_moves.pop_at(0)
		update_map(data['map'])
		for off in look_offsets:
			move_4d(off)
		look_counter = 0

	last_move = null
	if interacting: last_move = Vector4.ZERO
	else: last_move = get_keyboard_vec()
	if len(next_moves) != 0:
		last_move = next_moves[0]
	move_4d(last_move)


func _on_z_is_up_toggled(button_pressed):
	z_is_up = button_pressed
	update_look_offsets()


func _on_render_distance_value_changed(value):
	render_distance = value
	update_look_offsets()
	render_distance_spinbox.get_line_edit().release_focus()


func _on_render_up_value_changed(value):
	render_up = value
	update_look_offsets()
	render_up_spinbox.get_line_edit().release_focus()


func _on_render_down_value_changed(value):
	render_down = value
	update_look_offsets()
	render_down_spinbox.get_line_edit().release_focus()


func _on_render_rock_toggled(button_pressed):
	for pos in map:
		var block = map[pos]
		if block.get('mesh_instance') == null: continue
		var instance: MeshInstance3D = block.mesh_instance
		if block.type == "rock":
			instance.visible = button_pressed
		elif block.type == "air":
			instance.visible = (!button_pressed) or (!render_veilstone_checkbox.button_pressed)
			
func _on_render_veilstone_toggled(button_pressed):
	for pos in map:
		var block = map[pos]
		if block.get('mesh_instance') == null: continue
		var instance: MeshInstance3D = block.mesh_instance
		if block.type == "veilstone":
			instance.visible = button_pressed
		elif block.type == "air":
			instance.visible = (!button_pressed) or (!render_rock_checkbox.button_pressed)
