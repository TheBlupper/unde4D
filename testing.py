import tabulate

'''
notes:
ventricle increases max hp
bone marrow increases regen
artery conducts energy
soul gives power 
multiplier ?
shield gives defense

2 -> 3 1
3 -> 5 2
4 -> 6 2
5 -> 8 3
5 -> 9 4
7 -> 10 3
8 -> 13 5
9 -> 14 5
10 -> 15 5
11 -> 18

Arrangements:
v = ventricle
a = artery
m = multiplier
s = soul




va
ms -> 2

vm
as -> 1

ms
va -> 2

as
vm -> 1

sm
av -> 2

sa
mv -> 1

av
sm -> 2

mv
sa -> 1
--

vaaa
m  a
saaa -> 1

vmaa
a  a
saaa -> 2

  vmaa
  a  a
sassaa -> 6

  vaaa
  m  a
sassaa -> 3


v23
m
s -> 48

v23
s
s -> 46

v23
a
s -> 23

v9
m
s -> 18

v10
m
s -> 21

v19
m
s -> 39

v20
m
s -> 42
'''

org_inv =   { "1": { "count": "1", "type": "soul" }, "1+i": { "count": "2", "type": "artery" }, "1+2i": { "count": "2", "type": "multiplier" }, "1+3i": { "count": "1", "type": "artery" }, "1+4i": { "count": "1", "type": "sheld" }, "1-i": { "count": "3", "type": "artery" }, "1-2i": { "count": "2", "type": "artery" }, "2i": { "count": "1", "type": "artery" }, "-1+2i": { "count": "1", "type": "artery" }, "-2+2i": { "count": "1", "type": "artery" }, "-3+2i": { "count": "4", "type": "multiplier" }, "-3+3i": { "count": "1", "type": "artery" }, "-3+4i": { "count": "8", "type": "ventricle" }, "1-3i": { "count": "1", "type": "artery" }, "1-4i": { "count": "1", "type": "artery" }, "1-5i": { "count": "1", "type": "artery" }, "-5i": { "count": "1", "type": "artery" }, "-1-5i": { "count": "1", "type": "artery" }, "-2-5i": { "count": "1", "type": "artery" }, "-3-5i": { "count": "6", "type": "bone_marrow" }, "6-5i": { "count": "1", "type": "health_potion" }, "1+7i": { "count": "1", "type": "health_potion" }, "-5-8i": { "count": "1", "type": "health_potion" }, "-15+15i": { "count": "1", "type": "sword", "strength": "33+14i" }, "1-15i": { "count": "1", "type": "sword", "strength": "-23-26i" } }
inv = list(org_inv.values())

def get_item_count(item_type):
    res = 0 
    for item in inv:
        if item['type'] == item_type: res += int(item['count'])
    return res

def get_defense():
    return complex(get_item_count('shield'), get_item_count('sheld'))

def print_inv():
    items = []
    min_re, max_re = float('inf'), float('-inf')
    min_im, max_im = float('inf'), float('-inf')
    for slot, item in org_inv.items():
        slot = complex(slot.replace('i', 'j'))
        item['slot'] = slot
        items.append(item)
        if slot.real < min_re: min_re = slot.real
        if slot.real > max_re: max_re = slot.real
        if slot.imag < min_im: min_im = slot.imag
        if slot.imag > max_im: max_im = slot.imag
    A = []
    for im in range(int(min_im), int(max_im)+1):
        row = []
        for re in range(int(min_re), int(max_re)+1):
            slot = complex(re, im)
            item = next((i for i in items if i['slot'] == slot), None)
            ch = ''
            if item:
                ch = item['type'][0]
                if item['type'] == 'sword': ch = 'S'
                if item['type'] == 'shield': ch = 'C'
                if item['type'] == 'soul': ch = 'U'
                if item['type'] == 'ventrcle': ch = 'V'
                ch = f'{ch}'
                if item["count"] != '1': ch += f'{item["count"]}'
            row.append(ch)
        A.append(row)
    print(tabulate.tabulate(A))

print_inv()
print(set(a['type'] for a in inv))
defense = get_defense()
print(f'{defense=}')
print(f"{get_item_count('soul')=}")
print(f"{get_item_count('health_potion')=}")
print(f"{get_item_count('multiplier')=}")
print(f"{get_item_count('bone_marrow')=}")
print(f"{get_item_count('ventricle')=}")
print(f"{get_item_count('ventrcle')=}")
print(f"{get_item_count('shield')=}")
print(f"{get_item_count('sheld')=}")

sword = 34+14j
hp_before = 15
hp_after = 15-14j

damage_taken = hp_before - hp_after
actual_defense = sword - damage_taken
print(f'{damage_taken=}')
print(f'{actual_defense=}')

'''
sword: 34+14i
hp_before = -10-14i
hp_after = -28-28i
'''