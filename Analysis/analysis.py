FAVORITE_DIRECTION_THRESHOLD = 0.5
LIKES_DIRECTION_THRESHOLD = 0.2

import os
import json
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import subprocess


class Simulation():
    def __init__(self, log_folder:str):
        self.mainFolder:str = log_folder
        self.BotsLog = self.open_json("BotsLog")
        self.BotStepLog = self.open_json("BotStepLog")
        self.EventLog = self.open_json("EventLog")
        self.GeneralLog = self.open_json("GeneralLog")

    def movement_gene_analysis(self,steps:list) -> None:
        df = self.build_movement_analysis_df(steps)
        self.plot_heatmap_comparing_steps(df)

    def build_movement_analysis_df(self, steps:list) -> pd.DataFrame:
        df_dicts:dict={}
        for step in steps:
            df_dicts["Step"+str(step)] = pd.DataFrame.from_dict(self.movement_genes_snapshot(step), orient="index")
        
        all_combinations:tuple = set()
        step_counts:dict = {}

        for step, dataframe in df_dicts.items():
            combinations = self.sorts_joins_list_into_strings(df=dataframe,collumn="likes") 
            counts = combinations.value_counts()
            step_counts[step] = counts
            all_combinations.update(counts.index)

        all_combinations = sorted(all_combinations)
        united_df = pd.DataFrame(index=all_combinations)

        for step, counts in step_counts.items():
            united_df[step] = counts.reindex(all_combinations, fill_value = 0)
        return united_df

    def generate_video_of_frames(self):
        input_path = os.path.join(self.mainFolder, "frames", "frame_%06d.png")
        output_path = os.path.join(self.mainFolder, "output.mp4")
        
        cmd = [
            "ffmpeg",
            "-framerate", "10",
            "-i", input_path,
            "-c:v", "libx264",
            "-pix_fmt", "yuv420p",
            output_path
        ]
        print("Rodando FFmpeg com:", " ".join(cmd))  # Debug
        subprocess.run(cmd, check=True)


    def open_json(self, name:str) -> list:
        adress:str = self.mainFolder+"/"+name+".json"
        data:list = []
        with open(adress,"r") as file:
            for line in file:
                line = line.strip()
                if line: data.append(json.loads(line))         
        return data
    
    def sorts_joins_list_into_strings(self,df:pd.DataFrame,collumn:str):
        return df[collumn].apply(lambda x: ', '.join(sorted(x)))
        
    def plot_heatmap_comparing_steps(self,df:pd.DataFrame) -> None:
        plt.figure(figsize=(16, 8))
        sns.heatmap(df, annot=True, fmt="d", cmap="viridis", cbar_kws={'label': 'Frequência'})
        plt.title("Frequência por Combinação de Likes (Heatmap)")
        plt.xlabel("Passo")
        plt.ylabel("Combinação de Likes")
        plt.tight_layout()
        plt.show()

    def movement_genes_snapshot(self,step:int) -> dict:
        output:dict = {}
        for line in self.BotStepLog:
            if line[0]==step:
                favorite, likes = self.categorize_mov_prob(line[1]) 
                output[line[1]] = {}
                output[line[1]]["age"] = line[2]
                output[line[1]]["favorite"] = favorite
                output[line[1]]["likes"] = likes
        return output
    
    def categorize_mov_prob(self,bot:str) -> list:
        mov_dict:dict = self.get_mov_probs_from_gene(bot)
        favorite:list = []
        likes:list = []
        for key in mov_dict.keys():
            if mov_dict[key] > FAVORITE_DIRECTION_THRESHOLD:
                favorite.append(key)
            if mov_dict[key] > LIKES_DIRECTION_THRESHOLD:
                likes.append(key)
        return favorite, likes

    def get_mov_probs_from_gene(self,bot:str) -> dict:
        for line in self.BotsLog:
            if line[0]==bot:
                return (line[3][0])
        return {}

if __name__ == '__main__':
    data="/home/non4to/Documentos/SoftBodyLogs/2025-04-29_10-59-03_s1000"
    A = Simulation(data)
    A.generate_video_of_frames()
    # A.movement_gene_analysis([0,500,1000,2000,3000,4000,5000,6000,7000,8000,9000,10000])

