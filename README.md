# unde4D

An entry into [Kodsport's](https://www.kodsport.se/) Halloween competition 2023. The goal was to build a client for a server we were not the given source code of. The game is 4-dimensional, hence the name. For the code, viewer discretion is advised.

[labyrinth_analysis](./labyrinth_analysis/) contains a Python script for calculating the solution to the final maze, `moves.json` can then be loaded and executed by the client.

## Controls

### General keys

Up, down, left, right - Movement in XY

WASD - Movement in ZW

ESC - Toggle interact mode

F - Save current map

H - Help

R - Reset map and pushed moves (do this if unable to move)

### Interact mode

Direction + M - Push move

Direction + Enter - Interact with selected slot

0-9 - Select a slot

Space - Clear selected slot (break block)

### Inventory

Left click - Select slot

Right click - Swap/move/merge selected stack

Middle click - Move a single item
