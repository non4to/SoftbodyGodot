import subprocess
import sys
import argparse
import time
import os
import datetime


# Configuração padrão (ajuste conforme necessário)
CAMINHO_SIMULACAO = "/home/non4to/GitRepos/SoftbodyGodot"  # Altere para seu caminho real
COMANDO_BASE = ["/home/non4to/Documentos/godot_v4.4", "--path", CAMINHO_SIMULACAO]
CAMINHO_LOGS = "/home/non4to/Documentos/SoftBodyLogs/CurrentSimulation"

def executar_simulacoes(repetitions):
    maxDuration = 0
    keepSimulating = True
    duration_times = []
    i=1
    # for i in range(1, repetitions + 1):
    while keepSimulating and i <= repetitions:
        try:
            print(f"\n--- Executando simulação {i}/{repetitions} ---")
            start_time = time.time()
            # Executa o comando e aguarda a finalização
            processo = subprocess.run(
                COMANDO_BASE,
                check=True,
                stdout=sys.stdout,
                stderr=sys.stderr,
                env={
                    **os.environ,
                    "__NV_PRIME_RENDER_OFFLOAD": "1",
                    "__GLX_VENDOR_LIBRARY_NAME": "nvidia"
                })
            duration = time.time() - start_time
            if duration > maxDuration: maxDuration = duration
            i += 1
            duration_times.append(duration)
            now = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
            NEW_FOLDER_NAME = f"/home/non4to/Documentos/SoftBodyLogs/Simulation_{now}__{duration:.2f}s"
            try:
                os.rename(CAMINHO_LOGS, NEW_FOLDER_NAME)
                print(f"✅ Pasta renomeada para: {NEW_FOLDER_NAME}")
            except Exception as e:
                print(f"⚠️ Erro ao renomear pasta de log: {e}")
            print(f"Simulação {i} finalizada com código {processo.returncode}, em {duration}")

        except subprocess.CalledProcessError as e:
            print(f"Erro na execução {i}: {e}")
            break  # Interrompe o loop em caso de erro
        except Exception as e:
            print(f"Erro inesperado na execução {i}: {e}")
            break
    return duration_times, maxDuration

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Executa simulação Godot múltiplas vezes')
    parser.add_argument('-n', '--vezes', type=int, default=50,
                        help='Número de vezes para executar a simulação')
    args = parser.parse_args()

    if args.vezes < 1:
        print("O número de execuções deve ser pelo menos 1")
        sys.exit(1)

    print(f"\nIniciando ciclo de {args.vezes} execuções...")
    duration_times, maxDuration = executar_simulacoes(args.vezes)
    print("\nTodas as execuções foram concluídas!")
    print(f"Maior duracao: {maxDuration}")
    for i, line in enumerate(duration_times):
        print(f"{i}. [{duration_times[i]}]")