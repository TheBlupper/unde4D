import json
import os
import pickle

def load_blocks() -> set:
    blocks = set()
    for i in range(1, 33):
        fn = f'{i}.json'
        layer = []
        with open('data/' + fn, 'r') as f:
            min_x, min_y, min_w = float('inf'), float('inf'), float('inf')
            max_x, max_y, max_w = float('-inf'), float('-inf'), float('-inf')
            for block in json.load(f):
                pos = [*eval(block['pos'])]
                pos[0] += 16
                pos[1] -= 1
                pos[2] = i - 1
                pos[3] += 16

                if any(x<0 or x>=32 for x in pos): continue
                #if block['type'] != 'veilstone': continue
                if block['type'] == 'air': continue
                if block['type'] == 'goal': continue
                if 'timeout' in block: continue

                x, y, _, w = pos
                if x < min_x: min_x = x
                if y < min_y: min_y = y
                if w < min_w: min_w = w

                if x > max_x: max_x = x
                if y > max_y: max_y = y
                if w > max_w: max_w = w

                blocks.add(tuple(pos))
        print(i, len(layer), min_x, max_x, min_y, max_y, min_w, max_w)
    return blocks

if False:
    blocks = load_blocks()
    with open('blocks.pkl', 'wb') as f:
        pickle.dump(blocks, f)
else:
    blocks = pickle.load(open('blocks.pkl', 'rb'))
print(len(blocks))
paths = []
# Find the shortest path through the maze from the origin to the end
# without passing through any blocks.

origin = (3, 31-4, 3, 16)
target = (16, 16, 16, 16)
assert origin not in blocks
assert target not in blocks

# Find the shortest path from origin to target without passing through any blocks
# using dijkstras algorithm

# The graph is a 4d grid of nodes, where each node is a 4d box.
# The edges are between adjacent boxes.
# The weight of each edge is the number of blocks that the edge passes through.


def neighbors(node):
    x, y, z, w = node
    for dx, dy, dz, dw in [(1, 0, 0, 0), (-1, 0, 0, 0),
                           (0, 1, 0, 0), (0, -1, 0, 0),
                           (0, 0, 1, 0), (0, 0, -1, 0),
                           (0, 0, 0, 1), (0, 0, 0, -1)]:
        yield (x + dx, y + dy, z + dz, w + dw)

def is_valid(node):
    if node in blocks: return False
    if any(x < 0 or x >= 32 for x in node): return False
    return True
    
def dist(a, b):
    return sum(abs(x - y) for x, y in zip(a, b))

def heuristic(a, b):
    return dist(a, b)

def recover_path(came_from, current):
    path = [current]
    while current in came_from:
        current = came_from[current]
        path.append(current)
    path.reverse()
    return path

from collections import deque
def dijkstra(start, end):
    # The set of currently discovered nodes that are not evaluated yet.
    # Initially, only the start node is known.
    queue = deque([start])

    # For each node, which node it can most efficiently be reached from.
    # If a node can be reached from many nodes, came_from will eventually contain the
    # most efficient previous step.
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
path = dijkstra(origin, target)
deltas = []
prev = path[0]
for node in path[1:]:
    deltas.append(tuple(x - y for x, y in zip(node, prev)))
    prev = node

import numpy as np
path = np.array(path)
X, Y, Z, _ = path.T
import matplotlib.pyplot as plt
fig = plt.figure()
ax = fig.add_subplot(projection='3d')
ax.plot(X, Y, Z)

def to_str(delta):
    x, y, z, w = delta
    moves = []
    if x == 1: moves.append('right')
    if x == -1: moves.append('left')
    if y == -1: moves.append('up')
    if y == 1: moves.append('down')
    if z == -1: moves.append('a')
    if z == 1: moves.append('d')
    if w == 1: moves.append('w')
    if w == -1: moves.append('s')
    return ' '.join(moves)

for i, delta in enumerate(deltas[:100]):
    print(i, to_str(delta))
print('shortest path:', len(deltas))
plt.show()