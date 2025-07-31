import os
import json
import matplotlib.pyplot as plt
import statistics as st
MAIN_LOG_FOLDER = "/home/non4to/Documentos/OldLogsForAnalysis/Experimento #02"

class ReplicationNumber:
    def __init__(self, mainFolder:str):
        self.mainFolder = mainFolder
        self.data = self.get_simulations_data()
    #----------------------------------------------    
    def get_simulations_data(self) -> dict:
        data = {}
        for folder in os.listdir(self.mainFolder):
            data[folder] = []
            for folder2 in os.listdir(self.mainFolder+"/"+folder):
                address = self.mainFolder+"/"+folder+"/"+folder2+"/EndSimulation.json"
                with open(address,"r") as file:
                    data2 = json.load(file)
                data[folder].append(data2["NumberOfBotsCreatedByReplication"])
        return data
    #----------------------------------------------
    def get_average(self) -> dict:
        average = {}
        for data in self.data:
            average[data] = st.mean(self.data[data])
        return average
    #----------------------------------------------
    def get_stdev(self) -> dict:
        stdev = {}
        for data in self.data:
            stdev[data] = st.stdev(self.data[data])
        return stdev
    #----------------------------------------------        
    def plot_joining_boxplot(self, filepath: str):
        """
        Plota um boxplot comparando 'Joining' e 'NotJoining' e salva no caminho especificado.

        Parâmetros:
            data (dict): Dicionário com chaves 'Joining' e 'NotJoining' contendo listas de valores.
            filepath (str): Caminho do arquivo de imagem a ser salvo.
        """
        if 'Joining' not in self.data or 'NotJoining' not in self.data:
            raise ValueError("O dicionário precisa conter as chaves 'Joining' e 'NotJoining'.")

        # Dados em ordem de labels
        values = [self.data['Joining'], self.data['NotJoining']]
        labels = ['Joining', 'NotJoining']

        plt.figure(figsize=(8, 6))
        plt.boxplot(values, labels=labels)
        plt.title("Number of replications - Joining vs NotJoining")
        plt.ylabel("Number of replications")
        plt.grid(True)

        plt.savefig(filepath+"/children_number.jpeg")
        plt.close()
    #----------------------------------------------
if __name__ == '__main__':
    Exp = ReplicationNumber(MAIN_LOG_FOLDER)
    Exp.plot_joining_boxplot(MAIN_LOG_FOLDER)
    print("Average: ",Exp.get_average())
    print("StDev: ", Exp.get_stdev())
    # print()
    # print(st.mean(Exp.data["Joining"]))
    # print(st.mean(Exp.data["NotJoining"]))