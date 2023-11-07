extends Node

# Whether we are on a poor persons screen or not
var small = true

var cnum_re = RegEx.new()

func _init():
	small = DisplayServer.screen_get_size().x <= 1920
	
	# https://stackoverflow.com/a/50428157/11239740
	cnum_re.compile("^(?=[iI.\\d+-])(?<real>[+-]?(?:\\d+(?:\\.\\d*)?|\\.\\d+)(?:[eE][+-]?\\d+)?(?![iI.\\d]))?(?<imag>[+-]?(?:(?:\\d+(?:\\.\\d*)?|\\.\\d+)(?:[eE][+-]?\\d+)?)?[iI])?$")

func complex_to_vec(s: String) -> Vector2:
	var m = cnum_re.search(s)
	var imag = m.get_string("imag")
	if imag == '+i' or imag == '-i' or imag == 'i': imag = imag.replace('i', '1')
	return Vector2(int(m.get_string("real")), int(imag))


# This is for comparing if two items/blocks are the same,
# to check if the stack for example
var meta_keys = ["count", "mesh_instance", "slot"]
func simplify_block(block: Dictionary):
	var new_block = {}
	for key in block:
		if key in meta_keys: continue
		new_block[key] = block[key]
	return new_block
	
func compare_blocks(block1, block2):
	return simplify_block(block1) == simplify_block(block2)


const offsets = [
	Vector2(1, 0),
	Vector2(-1, 0),
	Vector2(0, 1),
	Vector2(0, -1)
]
const conductors = ['soul', 'artery', 'multiplier']

func parse_inventory(inv: Dictionary):
	# Returns a dictionary with the keys:
	# shield: Vector2
	# max_hp: Vector2
	# regen: int
	
	var grid = {}
	for slot in inv.keys():
		var item = inv[slot]
		item['slot'] = complex_to_vec(slot)
		grid[item['slot']] = item
	
	var shield = Vector2.ZERO
	var max_hp = Vector2(8, 0)
	var regen = 0
	
	# we use this dictionary as a hash set
	for soul in grid.values():
		if soul['type'] != 'soul': continue
		
		# stored in pairs of (slot_position, multiplier)
		var visited = {}
		var queue = [[soul['slot'], 1]]
		while len(queue):
			var v = queue.pop_front()
			var pos = v[0]
			var mult = v[1]
			for off in offsets:
				var new_pos = pos + off
				if new_pos in visited: continue
				visited[new_pos] = null
				if new_pos not in grid: continue
				var item = grid[new_pos]
				var ty = item['type']
				var count = int(item['count'])
				if ty == 'multiplier':
					mult += 0.1*count
					
				elif ty == 'shield':
					shield += Vector2(count, 0) * mult
				elif ty == 'sheld':
					shield += Vector2(0, count) * mult
					
				elif ty == 'ventricle':
					max_hp += Vector2(count, 0) * mult
				elif ty == 'ventrcle':
					max_hp += Vector2(0, count) * mult
				
				elif ty == 'bone_marrow':
					regen += count * mult
				if ty not in conductors: continue
				queue.push_front([new_pos, mult])
	return {
		'shield': Vector2(floor(shield.x), floor(shield.y)),
		'max_hp': Vector2(floor(max_hp.x), floor(max_hp.y)),
		'regen': floor(regen)
	}
