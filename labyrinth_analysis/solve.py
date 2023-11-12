import json
import os
import pickle
import numpy as np
from tqdm import tqdm
from collections import deque
import matplotlib.pyplot as plt

def load_blocks() -> set:
    blocks = set()
    for z, fn in enumerate(tqdm(sorted(os.listdir('./data/')))):
        with open('data/' + fn, 'r') as f:
            for block in json.load(f):
                # I did some stupid stuff and replaced all hypercubes
                # with veilstone, but the real "old" veilstone have a timeout
                # so we filter those out
                if 'timeout' in block: continue
                
                if block['type'] != 'veilstone': continue

                pos = [*eval(block['pos'])]
                pos[0] += 16
                pos[1] -= 1
                pos[2] = z
                pos[3] += 16

                if any(v<0 or v>=32 for v in pos): continue

                blocks.add(tuple(pos))
    return blocks

if False:
    blocks = load_blocks()
    with open('blocks.pkl', 'wb') as f:
        pickle.dump(blocks, f)
else:
    blocks = pickle.load(open('blocks.pkl', 'rb'))

paths = []

start = (0, 30, 1, 1)
target = (16, 16, 16, 16)
assert start not in blocks
assert target not in blocks


def neighbors(node):
    x, y, z, w = node
    for dx, dy, dz, dw in [(1, 0, 0, 0), (-1, 0, 0, 0),
                           (0, 1, 0, 0), (0, -1, 0, 0),
                           (0, 0, 1, 0), (0, 0, -1, 0),
                           (0, 0, 0, 1), (0, 0, 0, -1)]:
        yield (x + dx, y + dy, z + dz, w + dw)

def recover_path(came_from, current):
    path = [current]
    while current in came_from:
        current = came_from[current]
        path.append(current)
    path.reverse()
    return path

def is_valid(node):
    if node in blocks: return False
    if any(x < 0 or x >= 32 for x in node): return False
    return True

def find_best_path(start, end):
    queue = deque([start])
    came_from = {}
    dists = {start: 0}

    while queue:
        current = queue.popleft()

        for neighbor in neighbors(current):
            if not is_valid(neighbor):
                continue

            if dists.get(neighbor, float('inf')) <= dists[current] + 1:
                continue
            dists[neighbor] = dists[current] + 1
            came_from[neighbor] = current
            queue.append(neighbor)

    return recover_path(came_from, end)

path = find_best_path(start, target)
deltas = []
prev = path[0]
for node in path[1:]:
    deltas.append(tuple(x - y for x, y in zip(node, prev)))
    prev = node

path = np.array(path)

# Inaccurate path ofc since we discard w,
# but works as a sanity check
X, Y, Z, W = path.T
fig = plt.figure()
ax = fig.add_subplot(projection='3d')
ax.plot(X, Y, Z)
plt.show()

def to_str(delta):
    x, y, z, w = delta
    out = ''
    out += ['left', '', 'right'][x + 1]
    out += ['up', '', 'down'][y + 1]
    out += ['a', '', 'd'][z + 1]
    out += ['s', '', 'w'][w + 1]
    return out

# Show the first couple of moves
# to verify that the beginning makes sense
for i, delta in enumerate(deltas[:10]):
    print(i, to_str(delta))

print(f'{len(path)=}')

with open('moves.json', 'w') as f:
    json.dump(deltas, f)