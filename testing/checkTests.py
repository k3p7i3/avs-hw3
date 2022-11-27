import os
path = "tests/"
eps = 0.001

for file in os.listdir(path):
    with open(f"results/c/{file}", "r") as result:
        c_result = float(result.read())
    with open(f"results/asm/{file}", "r") as result:
        asm_result = float(result.read())
    with open(f"results/refactored/{file}", "r") as result:
        refactored_result = float(result.read())
    
    if abs(c_result - asm_result) > eps or abs(c_result - refactored_result) > eps:
        print(f"{file} is failed!")
    else:
        print(f"{file} OK")