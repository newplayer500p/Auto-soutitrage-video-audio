#!/usr/bin/env python3
from pathlib import Path
import os
import logging
import torch
import subprocess
import shlex

from utils.cleaner.clear_gpu_cache import cleanup_demucs_processes, force_gpu_cleanup

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def demucs_cli_run(input_wav: Path, out_dir: Path, model: str = "mdx_q", cpu: bool = False):
    """
    Version améliorée avec meilleur contrôle du processus
    """
    input_wav = Path(input_wav)
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    # Construction commande
    cmd = ["demucs", "-n", model,  str(input_wav), "--two-stems", "vocals", "-o", str(out_dir)]
    
    if cpu:
        device = "cpu"
    else:
        device = "cuda" if torch.cuda.is_available() else "cpu"

    cmd += ["-d", device]

    logger.info("Lancement Demucs CLI: %s", " ".join(shlex.quote(a) for a in cmd))
    
    try:
        # Utiliser Popen pour mieux contrôler le processus
        process = subprocess.Popen(
            cmd, 
            stdout=subprocess.PIPE, 
            stderr=subprocess.PIPE,
            text=True
        )
                
        # Attendre avec timeout
        stdout, stderr = process.communicate(timeout=3600)  # 1 heure timeout
        
        if process.returncode != 0:
            logger.error("Demucs CLI failed: rc=%s stderr=%s", process.returncode, stderr)
            raise subprocess.CalledProcessError(process.returncode, cmd, output=stdout, stderr=stderr)
            
    except subprocess.TimeoutExpired:
        logger.error("Demucs CLI timeout")
        process.kill()
        stdout, stderr = process.communicate()
        raise
    except Exception as e:
        logger.exception("Erreur durant Demucs CLI")
        if 'process' in locals():
            process.kill()
        raise

    # Chercher le fichier vocals
    stem_folder_candidates = [
        out_dir / model / input_wav.stem,
        out_dir / input_wav.stem,
    ]
    vocals_path = None
    for cand in stem_folder_candidates:
        cand_v = cand / "vocals.wav"
        if cand_v.exists():
            vocals_path = cand_v
            break

    if vocals_path is None:
        for p in out_dir.rglob("vocals.wav"):
            vocals_path = p
            break

    if vocals_path and vocals_path.exists():
        logger.info("Demucs CLI produced vocals: %s", vocals_path)
        return vocals_path
    else:
        logger.warning("Demucs CLI finished but vocals.wav not found in %s", out_dir)
        return None

def run_demucs(
    wav_path: Path,
    out_target: Path,
    *,
    single_sig: str = None,    # sig unique, ex: 'a1d90b5c' (si fourni on l'utilise comme clé de modèle)
    model: str = "mdx",  # modèle par défaut si single_sig=None
    device: str = "cuda",   # ignoré par CLI sauf si cpu=True
    use_cli: bool = True,   # si True utilisera la CLI, sinon (fallback) garderait l'API (non utilisée ici)
):
    """
    Wrapper principal : si use_cli=True, lance demucs en CLI et retourne le path du vocals wav.
    """

    wav_path = Path(wav_path)
    out_target = Path(out_target)

    # create base output folder similar to CLI behaviour (the CLI will create subfolders)
    output_base = out_target
    output_base.mkdir(parents=True, exist_ok=True)
    
    force_gpu_cleanup()

    # decide model_key
    model_key = "htdemucs" if (single_sig and single_sig != "") else model

    # If using CLI -> run CLI child process
    if use_cli:
        # If device == 'cpu' force CPU via flag; else allow GPU in child if available
        cpu_flag = (str(device).lower() == "cpu")
        # choose a safer default model for limited GPUs? we keep model_key as provided
        try:
            vocals_path = demucs_cli_run(wav_path, out_target, model=model_key, cpu=cpu_flag)
            
            cleanup_demucs_processes()
            force_gpu_cleanup()
            return vocals_path
        
        except Exception as e:
            logger.exception("Erreur lors de l'appel Demucs CLI: %s", e)
            cleanup_demucs_processes()
            force_gpu_cleanup()
            
            return None

    # fallback: (NOT USED) keep original python API path if you ever need it
    logger.warning("use_cli=False demandé, mais la voie API n'est pas implémentée dans ce wrapper.")
    return None


# Petit test rapide si on exécute directement
if __name__ == "__main__":
    import sys
    if len(sys.argv) < 3:
        print("Usage: python demucs_runner_api.py input.wav out_dir [sig_unique]")
        sys.exit(1)

    input_wav = Path(sys.argv[1])
    out_dir = Path(sys.argv[2])
    sig_unique = sys.argv[3] if len(sys.argv) > 3 else None

    res = run_demucs(input_wav, out_dir, single_sig=sig_unique, device=("cpu" if os.environ.get("DEMUCS_FORCE_CPU") == "1" else ("cuda" if torch.cuda.is_available() else "cpu")), jobs=1, use_cli=True)
    print("Result:", res)
