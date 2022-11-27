import os
import time

tests_number = int(input())
number = int(input())

for i in range(tests_number + 1, tests_number + number + 1):
    open(f'tests/test{i}.txt', 'a').close()
    open(f'results/c/test{i}', 'a').close()
    os.system(f'../code tests/test{i}.txt results/c/test{i} --rand')
    time.sleep(1)