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
    
    def gene_dominance_stackplot(self, threshold, gene:int, normalize=False):
        """gene: index of which allelo is being analysed.
        0 -> Movement , 1 -> Attach, 2 -> Dettach, 3 -> Death, 4 -> Replication"""
        # Merge all simulation steps
        allSimulationSteps = []
        for folder, data in self.data.items():
            steps_df = data["steps_df"].copy()
            steps_df["Simulation"] = folder
            allSimulationSteps.append(steps_df)
        df = pd.concat(allSimulationSteps, ignore_index=True)

        if gene==0:
            graph_labels = ["E", "N", "W", "S", "Z"]
            graph_title = (f'Probability to move to a direction (value >{threshold*100}%) + Active Simulations (line) ')
            graph_y_axis_label= (f"Quantity of occurrences of corresponding allele value (value >{threshold*100}%)")
            stack_data = self.direction_gene_dominance_analysis(df,threshold)
            if normalize: stack_data = stack_data.div(stack_data.sum(axis=1), axis=0).fillna(0) #Normalize

        if gene==1:
            graph_labels = ["0","1","2","3"]
            graph_title = (f'Probability to attach based on number of existing links (value >{threshold*100}%) + Active Simulations (line)')
            graph_y_axis_label= (f"Quantity of occurrences of corresponding allele value (value >{threshold*100}%)")
            stack_data = self.attach_gene_dominance_analysis(df,threshold)
            if normalize: stack_data = stack_data.div(stack_data.sum(axis=1), axis=0).fillna(0) #Normalize

        if gene==2:
            graph_labels = ["1","2","3","4"]
            graph_title = (f'Probability to dettach based on number of existing links (value >{threshold*100}%) + Active Simulations (line)')
            graph_y_axis_label= (f"Quantity of occurrences of corresponding allele value (value >{threshold*100}%)")
            stack_data = self.dettach_gene_dominance_analysis(df,threshold)
            if normalize: stack_data = stack_data.div(stack_data.sum(axis=1), axis=0).fillna(0) #Normalize

        if gene==3:
            graph_labels = ["1","2","3","4"]
            graph_title = (f'Death allele value + Active Simulations (line)')
            graph_y_axis_label= (f"Quantity of occurrences of corresponding allele value")
            stack_data = self.death_gene_dominance_analysis(df)
            if normalize: stack_data = stack_data.div(stack_data.sum(axis=1), axis=0).fillna(0) #Normalize

        if gene==4:
            graph_labels = ["0","1","2","3","4"]
            graph_title = (f'Minimum-links to replicate allele value + Active Simulations (line)')
            graph_y_axis_label= (f"Quantity of occurrences of corresponding allele value")
            stack_data = self.replicate_gene_dominance_analysis(df)
            if normalize: stack_data = stack_data.div(stack_data.sum(axis=1), axis=0).fillna(0) #Normalize

        # How many simulations are active in each timestep
        # Take the last time step
        last_steps = df.groupby("Simulation")["Step"].max()
        # For each timestep value in the index, count how many simulations have last_step >= step 
        steps = stack_data.index.values
        active_sims = [ (last_steps >= s).sum() for s in steps ]

        # Plot
        fig, ax1 = plt.subplots(figsize=(12,6))

        # StackPlot
        ax1.stackplot(steps, stack_data.T.values, labels=graph_labels, alpha=0.8)
        ax1.set_xlabel("Step")
        if normalize: graph_y_axis_label = f"Normalized {graph_y_axis_label}"
        ax1.set_ylabel(graph_y_axis_label, color="black")
        if normalize: ax1.set_yticks([i/10 for i in range(0,11)])
        ax1.set_xticks(range(0, int(steps.max())+1, 5000))
        ax1.tick_params(axis='y', labelcolor="black")

        # ActiveSimulations
        ax2 = ax1.twinx()
        ax2.plot(steps, active_sims, color="k", linestyle="--", 
                label="Active Simulations")
        ax2.set_ylabel("Active Simulations", color="k")
        ax2.tick_params(axis='y', labelcolor="k")

        # Subtitle/Grid
        lines, labels = ax1.get_legend_handles_labels()
        lines2, labels2 = ax2.get_legend_handles_labels()
        ax1.legend(lines + lines2, labels + labels2, loc="upper left")

        ax1.grid(True, which='both', linestyle='--', linewidth=0.5)
        if normalize: graph_title = f"Normalized {graph_title}"
        plt.title(graph_title)
        plt.tight_layout()
        plt.savefig(f"{self.mainFolder}/Figures/{graph_title}.png")
        plt.show()

    def direction_gene_dominance_analysis(self, df:pd.DataFrame, genesThreshold: float) -> pd.DataFrame:
        """Returns dataframe with directions counted. \n
        [df] - Step dataframe with bot genes merged \n
        [genesThreshold] - The minimum value to count said bot
        """
        # Counts per direction
        alleles = ["E", "N", "W", "S", "Z"]
        counts_per_direction = {}
        for allele in alleles:
            df["tempColumn"] = df["Gene_Movement"].apply(
                lambda g: isinstance(g, dict) and g.get(allele, 0) > genesThreshold
            )
            counts_per_direction[allele] = df.groupby("Step")["tempColumn"].sum()

        stack_data = pd.DataFrame(counts_per_direction).fillna(0)[alleles]
        return stack_data

    def attach_gene_dominance_analysis(self, df:pd.DataFrame, genesThreshold: float) -> pd.DataFrame:
        """Returns dataframe with links counts value counted. \n
        [df] - Step dataframe with bot genes merged \n
        [genesThreshold] - The minimum value to count said bot
        """
        alleles = ["0","1","2","3"]
        counts_per_direction = {}
        for allele in alleles:
            df["tempColumn"] = df["Gene_Attach"].apply(
                lambda g: isinstance(g, dict) and g.get(allele, 0) > genesThreshold
            )
            counts_per_direction[allele] = df.groupby("Step")["tempColumn"].sum()

        stack_data = pd.DataFrame(counts_per_direction).fillna(0)[alleles]
        return stack_data
    
    def dettach_gene_dominance_analysis(self, df:pd.DataFrame, genesThreshold: float) -> pd.DataFrame:
        """Returns dataframe with links counts value counted. \n
        [df] - Step dataframe with bot genes merged \n
        [genesThreshold] - The minimum value to count said bot
        """
        alleles = ["1","2","3","4"]
        counts_per_direction = {}
        for allele in alleles:
            df["tempColumn"] = df["Gene_Dettach"].apply(
                lambda g: isinstance(g, dict) and g.get(allele, 0) > genesThreshold
            )
            counts_per_direction[allele] = df.groupby("Step")["tempColumn"].sum()

        stack_data = pd.DataFrame(counts_per_direction).fillna(0)[alleles]
        return stack_data

    def death_gene_dominance_analysis(self, df:pd.DataFrame) -> pd.DataFrame:
        """Counts how many bots have death gene == 1, 2, 3 or 4 in each Step."""
        death_values = [1, 2, 3, 4]
        counts_per_value = {}
        for val in death_values:
            df["tempColumn"] = df["Gene_Death"].apply(lambda g: g == val)
            counts_per_value[str(val)] = df.groupby("Step")["tempColumn"].sum()

        stack_data = pd.DataFrame(counts_per_value).fillna(0)[[str(v) for v in death_values]]
        return stack_data
    
    def replicate_gene_dominance_analysis(self, df:pd.DataFrame) -> pd.DataFrame:
        """Counts how many bots have death gene == 1, 2, 3 or 4 in each Step."""
        replicate_values = [0, 1, 2, 3, 4]
        counts_per_value = {}
        for val in replicate_values:
            df["tempColumn"] = df["Gene_Replicate"].apply(lambda g: g == val)
            counts_per_value[str(val)] = df.groupby("Step")["tempColumn"].sum()

        stack_data = pd.DataFrame(counts_per_value).fillna(0)[[str(v) for v in replicate_values]]
        return stack_data


if __name__ == '__main__':
    Sim1 = Experiment(MAIN_LOG_FOLDER,"LogsDepoisDaNovaReplicacao")
    graphs_to_print = {
        # "movement_norm": [0.2,0,True],
        "movement_not_norm": [0.2,0,False],
        # "attach_norm": [0.5,1,True],
        # "attach_not_norm": [0.5,1,False],
        # "dettach_norm": [0.5,2,True],
        # "dettach_not_norm": [0.5,2,False],
        # "death_norm": [0,3,True],
        # "death_not_norm": [0,3,False],
        # "replicate_norm": [0,4,True],
        # "replicate_not_norm":[0,4,False]
    }

    for key in graphs_to_print.keys():
        Sim1.gene_dominance_stackplot(graphs_to_print[key][0],graphs_to_print[key][1],graphs_to_print[key][2])
    # Sim1.gene_dominance_stackplot(0.20,0,True)
    # Sim1.debug_dict_column("Gene_Movement")
    # Sim1.build_simulation_step_df("/home/non4to/Documentos/SoftBodyLogs/Simulation_2025-05-06_18-27-33__47.26s")
    # Sim1.gene_dominance_analysis([0.2, 0.5, 0.5, 1, 0])