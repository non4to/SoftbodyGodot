import os
import json
import pandas as pd
import pickle
from collections import defaultdict, Counter
import matplotlib.pyplot as plt
MAIN_LOG_FOLDER = "/home/non4to/Documentos/OldLogsForAnalysis/LogsDepoisDaNovaReplicacao"
PROB_THRESOLD = 0.2

class Experiment():
    def __init__(self, log_folder:str, experiment_name:str):
        self.mainFolder:str = log_folder
        self.experimentName:str = experiment_name
        self.data = self.get_experiment_data()
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
    
    def get_all_simulations_df(self) -> dict:
        """Returns a dictionary of simulations addresses in main_folder and their data
        keys:
        ["address"] = main adress of simulation \n
        ["bots_df"] = pandas dataframe of bots and their information ~see [get_bots_df] \n
        ["steps_df"] = pandas dataframe of simulation steps ~see[get_simulation_step_df] but merged with bots_df to make GENE available in this df too \n
        ["Duration(s)"] \n
        ["Extra"] = end simulation extra message \n
        ["FinalStep"] \n
        ["NumberOfBotsCreatedByReplication"] \n
        ["NumberOfBotsCreatedBySpawner"] \n
        ["Reason"] = reason of simulation end"""
        simulations = {}
        for folder in os.listdir(self.mainFolder):
            if ("Simulation_" in folder):
                simulations[folder] = {}
                simulations[folder]["address"] = (self.mainFolder+"/"+folder)   
                simulations[folder]["bots_df"] = self.get_bots_df(simulations[folder]["address"])
                steps_df = self.get_simulation_step_df(simulations[folder]["address"])
                simulations[folder]["steps_df"] = steps_df.merge(simulations[folder]["bots_df"][["Gene_Movement","Gene_Attach","Gene_Dettach","Gene_Death","Gene_Replicate"]],
                                                left_on="RobotID",      
                                                right_index=True,       
                                                how="left" 
                                                )      
                data = self.open_json(simulations[folder]["address"]+"/EndSimulation.json",True)
                for key in data.keys():
                    simulations[folder][key] = data[key]  

        return simulations      
    
    def get_experiment_data(self) -> dict:
        if os.path.exists(f"{self.mainFolder}/{self.experimentName}.pkl"):
            with open(f"{self.mainFolder}/{self.experimentName}.pkl", "rb") as file:
                data = pickle.load(file)
        else:
            data = self.get_all_simulations_df()
            with open(f"{self.mainFolder}/{self.experimentName}.pkl", "wb") as file:
                pickle.dump(data, file)
        return data
    
    def direction_gene_dominance_analysis(self, GenesThreshold: float):
        # 1) Merge all simulation steps
        allSimulationSteps = []
        for folder, data in self.data.items():
            steps_df = data["steps_df"].copy()
            steps_df["Simulation"] = folder
            allSimulationSteps.append(steps_df)
        df = pd.concat(allSimulationSteps, ignore_index=True)

        # 2) Calcular contagens por direção
        directions = ["E", "N", "W", "S", "Z"]
        counts_per_direction = {}
        for direction in directions:
            df["tempColumn"] = df["Gene_Movement"].apply(
                lambda g: isinstance(g, dict) and g.get(direction, 0) > GenesThreshold
            )
            counts_per_direction[direction] = df.groupby("Step")["tempColumn"].sum()

        stack_data = pd.DataFrame(counts_per_direction).fillna(0)[directions]

        # 3) Normalizar para 0–1
        stack_norm = stack_data.div(stack_data.sum(axis=1), axis=0).fillna(0)

        # 4) Calcular quantas simulações estão vivas em cada step
        # Primeiro, para cada simulação, achar o último step
        last_steps = df.groupby("Simulation")["Step"].max()
        # Agora, para cada valor de step no índice, contar quantas sims têm last_step >= step
        steps = stack_norm.index.values
        active_sims = [ (last_steps >= s).sum() for s in steps ]

        # 5) Plot
        fig, ax1 = plt.subplots(figsize=(12,6))

        # 5a) Stackplot no eixo principal
        ax1.stackplot(steps, stack_norm.T.values, labels=directions, alpha=0.8)
        ax1.set_xlabel("Step")
        ax1.set_ylabel("Proporção de Bots", color="black")
        ax1.set_yticks([i/10 for i in range(0,11)])
        ax1.set_xticks(range(0, int(steps.max())+1, 5000))
        ax1.tick_params(axis='y', labelcolor="black")

        # 5b) Eixo secundário para simulações ativas
        ax2 = ax1.twinx()
        ax2.plot(steps, active_sims, color="k", linestyle="--", 
                label="Simulações ativas")
        ax2.set_ylabel("Simulações ativas", color="k")
        ax2.tick_params(axis='y', labelcolor="k")

        # 6) Legenda e grid
        lines, labels = ax1.get_legend_handles_labels()
        lines2, labels2 = ax2.get_legend_handles_labels()
        ax1.legend(lines + lines2, labels + labels2, loc="upper left")

        ax1.grid(True, which='both', linestyle='--', linewidth=0.5)
        plt.title(f'Dominância de direções (stacked) + Simulações ativas (linha)')
        plt.tight_layout()
        plt.show()


    # def direction_gene_dominance_analysis(self, GenesThreshold:float):
    #     """Outputs graphs of frequency of Gene that have values bigger than the given [GenesThreshold] \n"""

    #     # Merge all simulation steps
    #     allSimulationSteps = []
    #     for folder, data in self.data.items():
    #         steps_df = data["steps_df"].copy()
    #         steps_df["Simulation"] = folder
    #         allSimulationSteps.append(steps_df)

    #     df = pd.concat(allSimulationSteps, ignore_index=True)

    #     # Preparar contagens para cada direção
    #     directions = ["E", "N", "W", "S", "Z"]
    #     counts_per_direction = {}

    #     for direction in directions:
    #         def bigger_than_threshold(geneDict):
    #             if isinstance(geneDict, dict):
    #                 return geneDict.get(direction, 0) > GenesThreshold
    #             else:
    #                 return False

    #         df["tempColumn"] = df["Gene_Movement"].apply(bigger_than_threshold)
    #         countValuesPerStep = df.groupby("Step")["tempColumn"].sum()
    #         counts_per_direction[direction] = countValuesPerStep

    #     # Montar DataFrame para stackplot
    #     stack_data = pd.DataFrame(counts_per_direction).fillna(0)
    #     stack_data = stack_data[directions]  # garantir ordem correta

    #     # Normalizar para proporção (0 a 1)
    #     stack_data_normalized = stack_data.div(stack_data.sum(axis=1), axis=0).fillna(0)

    #     # Plotar stackplot normalizado
    #     plt.figure(figsize=(12, 6))
    #     plt.stackplot(stack_data_normalized.index, stack_data_normalized.T.values, labels=directions, alpha=0.8)

    #     plt.xlabel('Step')
    #     plt.ylabel('Proporção de Bots (%)')
    #     plt.title(f'Proporção de Bots com Gene_Movement > {GenesThreshold} por Direção')

    #     plt.yticks([i/10 for i in range(0, 11)])           
    #     max_step = int(stack_data_normalized.index.max())
    #     plt.xticks(range(0, max_step + 1, 5000)) 
    #     plt.legend(loc="upper left")
    #     plt.grid(True)
    #     plt.tight_layout()
    #     plt.show()

        # #Merge all simulation steps_df
        # allSimulationSteps = []
        # for folder, data in self.data.items():
        #     steps_df = data["steps_df"].copy()
        #     steps_df["Simulation"] = folder
        #     allSimulationSteps.append(steps_df)

        # df = pd.concat(allSimulationSteps, ignore_index=True)
        
        # #plots figure
        # plt.figure(figsize=(12,6))
        # for direction in ["E","N","W","S","Z"]:
        #     def bigger_than_threshold(geneDict):
        #         if isinstance(geneDict, dict):
        #             return geneDict.get(direction, 0) > GenesThreshold
        #         else:
        #             return False
            
        #     df["tempColumn"] = df["Gene_Movement"].apply(bigger_than_threshold)
        #     countValuesPerStep = df.groupby("Step")["tempColumn"].sum()
        #     plt.plot(countValuesPerStep.index, countValuesPerStep.values, label=f"{direction}>{GenesThreshold}")
        #     df.drop(columns=["tempColumn"], inplace=True)
        
        # totalBotsInStep = df.groupby("Step").size()
        # plt.plot(totalBotsInStep.index, totalBotsInStep.values, color="red",label=f"Total bots", linewidth=2)

        # plt.xlabel('Step')
        # plt.ylabel('Quantidade de Bots')
        # plt.title(f'Bots com Gene_Movement > {GenesThreshold} por Direção')
        # plt.legend()
        # plt.grid(True)
        # plt.show()

if __name__ == '__main__':
    Sim1 = Experiment(MAIN_LOG_FOLDER,"LogsDepoisDaNovaReplicacao")
    Sim1.direction_gene_dominance_analysis(0.2)
    # Sim1.debug_dict_column("Gene_Movement")
    # Sim1.build_simulation_step_df("/home/non4to/Documentos/SoftBodyLogs/Simulation_2025-05-06_18-27-33__47.26s")
    # Sim1.gene_dominance_analysis([0.2, 0.5, 0.5, 1, 0])