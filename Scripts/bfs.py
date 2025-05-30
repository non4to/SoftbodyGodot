import numpy as np
    
Bank = np.array(([
                [0,1,1,0,0,0,0],
                [1,0,0,0,0,0,1],
                [1,0,0,1,1,0,0],
                [0,0,1,0,0,1,0],
                [0,0,1,0,0,0,0],
                [0,0,0,1,0,0,1],
                [0,1,0,0,0,1,0],
]))

test_dict = { 0: [], 
             1: { "Bot2": ["Bot3"], "Bot3": ["Bot2"] }, 
             2: { "Bot4": ["Bot5"], "Bot5": ["Bot4", "Bot6"], "Bot6": ["Bot5"] } }

def check_dict_entry(Dict: dict, new_key:str) -> dict:
    if not(new_key in Dict): Dict[new_key] = []
    return Dict

def are_bank_connected(Dict: dict, botA:str, botB:str) -> tuple[bool, dict, dict]:
    dictA = {}
    qA = []
    vA = []

    dictB = {}
    qB = []
    vB = []


    if botA in Dict:
        qA = []
    if botB in Dict:
        qB = []

    while qA or qB:
            if qA:
                currentA = qA.pop(0)
                vA.append(currentA)
                if not(currentA in dictA):dictA[currentA] = []
                aNeighbors = Dict[currentA]
                if aNeighbors:
                    for neighbor in aNeighbors:
                        if (neighbor in vB) or (neighbor in qB): return True,{},{}
                        if not(neighbor in vA) and not(neighbor in qA):
                            qA.append(neighbor)
                            if not(neighbor in dictA): dictA[neighbor] = []
                            dictA[currentA].append(neighbor)
                            dictA[neighbor].append(currentA)
            ####
            if qB:
                currentB = qB.pop(0)
                vB.append(currentB)
                if not(currentB in dictB):dictB[currentB] = []
                aNeighbors = Dict[currentB]
                if aNeighbors:
                    for neighbor in aNeighbors:
                        if (neighbor in vA) or (neighbor in qA): return True,{},{}
                        if not(neighbor in vB) and not(neighbor in qB):
                            qB.append(neighbor)
                            if not(neighbor in dictB): dictB[neighbor] = []
                            dictB[currentB].append(neighbor)
                            dictB[neighbor].append(currentB)

    return False, dictA, dictB


print(are_bank_connected(test_dict[1],"Bot1","Bot3"))






def break_joint(bank:np.array,indexA:int,indexB:int) -> np.array:
    bank[indexA][indexB] = 0
    bank[indexB][indexA] = 0
    return bank

def is_connected(bank:np.array,botAIndex:int,botBIndex:int) -> list[bool, list, list]:
    qA = [botAIndex]
    vA = []
    qB = [botBIndex]
    vB = []

    while qA or qB:
        if qA:
            # print(f"qA: {qA}, vA:{vA}")
            currentA = qA.pop(0)
            vA.append(currentA)
            # print(f"qA: {qA}, vA:{vA}")
            aNeighbors = get_neighbors(bank[currentA])
            if aNeighbors:
                for neighbor in aNeighbors:
                    if (neighbor in qB) or (neighbor in vB): return True, vA,vB
                    elif (neighbor not in vA) and (neighbor not in qA):
                        qA.append(neighbor)
                        # print(f"qA: {qA}, vA:{vA}")
                        # print()

        
        if qB:
            # print(f"qB: {qB}, vB:{vB}")
            currentB = qB.pop(0)
            vB.append(currentB)
            # print(f"qB: {qB}, vB:{vB}")
            bNeighbors = get_neighbors(bank[currentB])
            if bNeighbors:
                for neighbor in bNeighbors:
                    if (neighbor in qA) or (neighbor in vA): return True, vA,vB
                    elif (neighbor not in vB) and (neighbor not in qB):
                        qB.append(neighbor)
                        # print(f"qB: {qB}, vB:{vB}")
                        # print()
    return False, vA,vB

                

def get_neighbors(line:np.array) -> list:
    #returns indexes where the content of the position is 1.
    neighbors = []
    for index,content in enumerate(line):
        if content > 0:
            neighbors.append(index)
    return neighbors



# bankPreBreak = break_joint(Bank,0,1)

# i1 = 3
# i2 = 5
# bankBreak = break_joint(bankPreBreak,i1,i2)
# isConected, b1, b2 = is_connected(bankBreak,i1,i2)
# if not isConected:
#     print(b1,b2)
#     newBank1 = np.array(np.zeros((len(b1),len(b1))))
#     print(bankBreak)
#     for index1,lineIndex in enumerate(b1):
#         for index2,columnIndex in enumerate(b1):
#             newBank1[index1][index2] = bankBreak[lineIndex][columnIndex]
#     print(newBank1)


