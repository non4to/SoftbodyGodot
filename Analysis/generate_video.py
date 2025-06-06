import os
import subprocess

MAIN_FOLDER = "/home/non4to/Documentos/SoftBodyLogs/"

def generate_video_of_frames(target:str):
    input_path = os.path.join(MAIN_FOLDER+target, "frames", "frame_%06d.png")
    output_path = os.path.join(MAIN_FOLDER+target, "output.mp4")
    
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

TargetFolder = ""
OutputName = ""

if __name__ == '__main__':
    folders = ["Simulation_2025-06-06_14-51-00__26.55s",
               "Simulation_2025-06-06_14-50-34__28.70s",
               "Simulation_2025-06-06_14-50-05__26.01s",]
    for folder in folders:
        generate_video_of_frames(folder)