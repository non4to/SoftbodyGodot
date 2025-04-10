def re_dict(dictio: dict) -> dict:
    re_dict = {}
    for key in dictio.keys():
        re_dict[key] = dictio[key]
    return re_dict








A = {0: "R1",
     1: "R2"}

print(f"A:{A}")
F = re_dict(A)


B = A
A[2] = "R3"

print(f"B:{B}")
print(f"F:{F}")



