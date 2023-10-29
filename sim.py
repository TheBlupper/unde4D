
'''
left > up
left > down
right > down
right > up
right > left
down > up
'''

from collections import deque

offsets = [1+0j, -1+0j, 0+1j, 0-1j]


inv = { "-4+4i": { "count": "1", "type": "soul" }, "-4+5i": { "count": "2", "type": "artery" }, "-4+6i": { "count": "2", "type": "artery" }, "-4+7i": { "count": "2", "type": "artery" }, "-4+8i": { "count": "2", "type": "artery" }, "-4+9i": { "count": "1", "type": "artery" }, "-4+10i": { "count": "2", "type": "artery" }, "-4+11i": { "count": "2", "type": "artery" }, "-4+12i": { "count": "1", "type": "multiplier" }, "-5+12i": { "count": "1", "type": "artery" }, "-6+12i": { "count": "1", "type": "artery" }, "-7+12i": { "count": "1", "type": "ventricle" }, "-4+13i": { "count": "2", "type": "artery" }, "-4+14i": { "count": "7", "type": "multiplier" }, "-4+15i": { "count": "1", "type": "artery" }, "-4+16i": { "count": "1", "type": "artery" }, "-4+17i": { "count": "1", "type": "artery" }, "-4+18i": { "count": "1", "type": "artery" }, "-4+19i": { "count": "3", "type": "ventrcle" }, "-3+14i": { "count": "1", "type": "artery" }, "-2+14i": { "count": "1", "type": "artery" }, "-1+14i": { "count": "1", "type": "artery" }, "14i": { "count": "1", "type": "artery" }, "1+14i": { "count": "8", "type": "ventricle" }, "-3+9i": { "count": "1", "type": "artery" }, "-2+9i": { "count": "1", "type": "artery" }, "-1+9i": { "count": "6", "type": "bone_marrow" }, "-7i": { "count": "1", "type": "pickaxe", "strength": "i" }, "-16+i": { "count": "1", "type": "sword", "strength": "33+28i" }, "-13+6i": { "count": "1", "type": "sword", "strength": "-31-19i" }, "1+10i": { "count": "1", "type": "sword", "strength": "9-13i" } }


grid = {}
item_arr = []
for slot, item in inv.items():
    item['slot'] = complex(slot.replace('i', 'j'))
    item['count'] = int(item['count'])
    item_arr.append(item)
    grid[item['slot']] = item

visited = set()
conductors = ['soul', 'artery', 'multiplier']

max_hp = 8
shield = 0

for item in item_arr:
    if item['type'] != 'soul': continue
    pos = item['slot']
    queue = deque([(pos, 1)])

    while queue:
        pos, multiplier = queue.pop()
        for offset in offsets:
            new_pos = pos + offset
            if new_pos in visited: continue
            visited.add(new_pos)
            if new_pos not in grid: continue
            item = grid[new_pos]
            ty = item['type']
            if ty == 'multiplier':
                multiplier += item['count']

            if ty == 'ventricle':
                max_hp += item['count'] * multiplier
            elif ty == 'ventrcle':
                max_hp += item['count'] * multiplier * 1j

            if ty == 'shield':
                shield += item['count'] * multiplier
            elif ty == 'sheld':
                shield += item['count'] * multiplier * 1j
            if ty not in conductors: continue
            queue.appendleft((new_pos, multiplier))
print(max_hp)
print(shield)



