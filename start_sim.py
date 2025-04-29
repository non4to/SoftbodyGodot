import subprocess
import time
import os

# Caminho do seu Godot e do projeto
godot_path = "/home/non4to/Documentos/godot_v4.4"
project_path = "/home/non4to/GitRepos/SoftbodyGodot"

# Iniciar o Godot em modo headless
process = subprocess.Popen([godot_path, "--headless", "--path", project_path])

# Esperar por um tempo para garantir que o Godot comece a gerar frames
time.sleep(5)

