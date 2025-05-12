import os
import json
import pandas as pd
from collections import defaultdict, Counter
import matplotlib.pyplot as plt
MAIN_LOG_FOLDER = "/home/non4to/Documentos/SoftBodyLogs"
PROB_THRESOLD = 0.2

class Experiment():
    def __init__(self, log_folder:str, experiment_name:str):
        self.mainFolder:str = log_folder
        self.experimentName:str = experiment_name
        # self.BotsLog = self.open_json("BotsLog")
        # self.BotStepLog = self.open_json("BotStepLog")
        # self.EventLog = self.open_json("EventLog")
        # self.GeneralLog = self.open_json("GeneralLog")

    def print_a_dict(self,dictToPrint:dict) -> None:
        for key in dictToPrint.keys():
            print(key)
            for key2 in dictToPrint[key]:
                print("--"+key2+": "+dictToPrint[key][key2])

    def open_json(self, address:str, complete_json:bool=False) -> list:
        """Returns the contents of [address], which is a json file.
        complete_json=true -> only one json in whole file
                    =false -> json in each line"""
        data:list = []
        with open(address,"r") as file:
            if complete_json:
                data=json.load(file)
            else:
                for line in file:
                    line = line.strip()
                    if line: data.append(json.loads(line))         
        return data
    
    def get_bots_df(self,simulation_adress:str) -> pd.DataFrame:
        """Returns a dictionary of Bots with Bots genes"""
        BotsDictionary = {}
        data = self.open_json(simulation_adress+"/BotsLog.json")
        for line in data:
            BotsDictionary[line[0]] = {}
            BotsDictionary[line[0]]["origin"] = line[1]
            BotsDictionary[line[0]]["bornIn"] = line[2]
            BotsDictionary[line[0]]["Gene_Movement"] = line[3][0]
            BotsDictionary[line[0]]["Gene_Attach"] = line[3][1]
            BotsDictionary[line[0]]["Gene_Dettach"] = line[3][2]
            BotsDictionary[line[0]]["Gene_Death"] = line[3][3]
            BotsDictionary[line[0]]["Gene_Replicate"] = line[3][4]
        df = pd.DataFrame.from_dict(BotsDictionary,"index")
        return df
    
    def get_simulation_step_df(self, simulation_adress:str) -> pd.DataFrame:
        """Returns a dataframe of simulation steps (BotStepLog.json)"""
        data = self.open_json(simulation_adress+"/BotStepLog.json")
        new_list = []

        for line in data:
            columns = ["Step","RobotID","Age","BornIn","MarkedForDeath","EnergyBankIndex","Position","MovementDirection","LinearVelocity","JointToBots","ReasonOfDeath"]
            line_dict = {}
            if len(line)==10:
                line.append("") 
                for i in range(0,len(columns)):
                    line_dict[columns[i]] = line[i]
            new_list.append(line_dict)

        df = pd.DataFrame(new_list)         
        return df
    
    def get_all_simulations_df(self) -> tuple:
        """Returns a tuple (a,b)
        a = dictionary of simulations addresses in main_folder and their endSImulation data
        b = dataframe of simulation steps with robots genes
        a keys:
        ["address"] = main adress of simulation \n
        ["bots_df"] = pandas dataframe of bots and their information ~see [get_bots_df] \n
        ["steps_df"] = pandas dataframe of simulation steps ~see[get_simulation_step_df] \n
        ["Duration(s)"] \n
        ["Extra"] = end simulation extra message \n
        ["FinalStep"] \n
        ["NumberOfBotsCreatedByReplication"] \n
        ["NumberOfBotsCreatedBySpawner"] \n
        ["Reason"] = reason of simulation end"""
        simulations = {}
        for folder in os.listdir(self.mainFolder):
            if "Simulation_" in folder:
                simulations[folder] = {}
                simulations[folder]["address"] = (self.mainFolder+"/"+folder)
                simulations[folder]["bots_df"] = self.get_bots_df(simulations[folder]["address"])
                simulations[folder]["steps_df"] = self.get_simulation_step_df(simulations[folder]["address"])
                data = self.open_json(simulations[folder]["address"]+"/EndSimulation.json",True)

                for key in data.keys():
                    simulations[folder][key] = data[key]     
                if simulations[folder]["Reason"]== "All bots died.":
                    merged_df = simulations[folder]["steps_df"].merge(simulations[folder]["bots_df"][["Gene_Movement","Gene_Attach","Gene_Dettach","Gene_Death","Gene_Replicate"]],
                                                left_on="RobotID",      
                                                right_index=True,       
                                                how="left" 
                                                )                    
        return (simulations,merged_df)

if __name__ == '__main__':
    Sim1 = Experiment(MAIN_LOG_FOLDER,"First")
    # Sim1.build_simulation_step_df("/home/non4to/Documentos/SoftBodyLogs/Simulation_2025-05-06_18-27-33__47.26s")
    Sim1.get_all_simulations_df()