nums = [
    10, 12, 14, 16, 18, 20,
    22, 24, 26, 29, 31, 33, 35,
    37, 39, 41, 43, 45, 47, 50,
    52, 54, 56, 58, 60, 62, 64, 66,
    68, 71, 73, 75, 77, 79, 83, 85, 87,
    89, 91, 94, 96, 98, 100, 102, 104, 106, 108,
    110, 112, 115, 117, 119, 121, 123, 125, 127, 129, 131,
    133, 136, 138, 140, 142, 144, 146, 148, 150
]
from matplotlib import pyplot as plt
import numpy as np
Y1 = []
Y2 = []
N = len(nums)
prev = 0
for i, n in enumerate(nums):
    Y1.append(n-8)
    Y2.append(2*(i+1))
    #print(n-8, 2*(i+1))
    if n-8 != prev + 2:
        print(prev, n - 8)
    prev = n-8
print(np.polyfit(range(1, N+1), Y1, 1))
plt.plot(range(1, N+1), Y1)
plt.plot(range(1, N+1), Y2)
plt.show()