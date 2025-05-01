import subprocess
import argparse
import os
import time

# Configuração
CAMINHO_SIMULACAO = "/home/non4to/GitRepos/SoftbodyGodot"
COMANDO_BASE = ["/home/non4to/Documentos/godot_v4.4", "--headless", "--path", CAMINHO_SIMULACAO]
NUM_PARALELAS = 4  # Quantas simulações ao mesmo tempo

def executar_simulacoes_em_paralelo(repeticoes, paralelas):
    processos = []
    iniciadas = 0
    terminadas = 0

    while terminadas < repeticoes:
        # Lança novos processos se possível
        while len(processos) < paralelas and iniciadas < repeticoes:
            print(f"→ Iniciando simulação {iniciadas+1}/{repeticoes}")
            p = subprocess.Popen(
                COMANDO_BASE,
                stdout=subprocess.DEVNULL,  # ou use sys.stdout se quiser ver logs
                stderr=subprocess.DEVNULL,
                env={
                    **os.environ,
                    "__NV_PRIME_RENDER_OFFLOAD": "1",
                    "__GLX_VENDOR_LIBRARY_NAME": "nvidia"
                }
            )
            processos.append(p)
            iniciadas += 1

        # Verifica e remove os que terminaram
        for p in processos[:]:
            if p.poll() is not None:  # Terminou
                processos.remove(p)
                terminadas += 1
                print(f"✓ Simulação finalizada ({terminadas}/{repeticoes})")

        time.sleep(0.1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Executa simulações Godot em paralelo')
    parser.add_argument('-n', '--vezes', type=int, default=30, help='Número de execuções')
    parser.add_argument('-p', '--paralelas', type=int, default=2, help='Máximo de execuções simultâneas')
    args = parser.parse_args()

    if args.vezes < 1 or args.paralelas < 1:
        print("Número de execuções e de paralelas deve ser pelo menos 1")
        exit(1)

    print(f"Iniciando {args.vezes} simulações, até {args.paralelas} ao mesmo tempo...\n")
    executar_simulacoes_em_paralelo(args.vezes, args.paralelas)
    print("\nTodas as simulações foram concluídas.")
