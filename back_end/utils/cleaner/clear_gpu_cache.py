import psutil
import torch

def cleanup_demucs_processes():
    """Nettoie tous les processus Demucs restants"""
    try:
        for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
            try:
                # Chercher les processus Demucs
                if proc.info['cmdline'] and any('demucs' in cmd.lower() for cmd in proc.info['cmdline']):
                    print(f"Termination du processus Demucs: {proc.info['pid']}")
                    proc.terminate()
                    proc.wait(timeout=5)
            except (psutil.NoSuchProcess, psutil.TimeoutExpired):
                pass
    except Exception as e:
        print(f"Erreur lors du nettoyage Demucs: {e}")

def force_gpu_cleanup():
    """Force le nettoyage GPU après Demucs"""
    try:
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
            torch.cuda.synchronize()
        import gc
        gc.collect()
    except Exception as e:
        print(f"Erreur lors du nettoyage GPU: {e}")