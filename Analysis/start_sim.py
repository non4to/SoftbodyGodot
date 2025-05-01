import subprocess
import sys
import argparse
import time
import os

# Configuração padrão (ajuste conforme necessário)
CAMINHO_SIMULACAO = "/home/non4to/GitRepos/SoftbodyGodot"  # Altere para seu caminho real
COMANDO_BASE = ["/home/non4to/Documentos/godot_v4.4", "--path", CAMINHO_SIMULACAO]

def executar_simulacoes(repetições):
    duration_times = []
    for i in range(1, repetições + 1):
        try:
            print(f"\n--- Executando simulação {i}/{repetições} ---")
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
            duration_times.append(duration)
            print(f"Simulação {i} finalizada com código {processo.returncode}, em {duration}")

        except subprocess.CalledProcessError as e:
            print(f"Erro na execução {i}: {e}")
            break  # Interrompe o loop em caso de erro
        except Exception as e:
            print(f"Erro inesperado na execução {i}: {e}")
            break

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Executa simulação Godot múltiplas vezes')
    parser.add_argument('-n', '--vezes', type=int, default=30,
                        help='Número de vezes para executar a simulação')
    args = parser.parse_args()

    if args.vezes < 1:
        print("O número de execuções deve ser pelo menos 1")
        sys.exit(1)

    print(f"\nIniciando ciclo de {args.vezes} execuções...")
    executar_simulacoes(args.vezes)
    print("\nTodas as execuções foram concluídas!")