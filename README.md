# Projet de Sous-titrage Audio utilisant le GPU

Ce projet permet de générer des sous-titres à partir de fichiers audio ou vidéo en utilisant :

- **Whisper / WhisperX** pour la transcription et l'alignement des sous-titres
- **Demucs** pour séparer la voix de la musique si nécessaire
- **FFmpeg** pour le traitement audio/vidéo
- **GPU CUDA** pour accélérer la transcription et la séparation

---

## 🖥️ Configuration minimale de la machine (GPU)

| Composant       | Minimum recommandé      | Notes |
|-----------------|------------------------|-------|
| GPU             | NVIDIA avec **≥ 4 Go VRAM** | CUDA 11+ requis |
| CPU             | 4 cœurs                | Plus de cœurs = meilleure performance |
| RAM             | 16 Go                  | Pour fichiers audio/vidéo longs |
| Stockage        | 20 Go libre            | Pour fichiers temporaires |
| OS              | Linux / Windows 10+ / MacOS | |

> La présence d’un GPU est fortement recommandée pour l’accélération CUDA de Whisper, Demucs et PyTorch.

---

## 📦 Dépendances et installation

### 1. Python
- **Version recommandée** : Python 3.10

### 2. CUDA + PyTorch
Installe PyTorch avec support CUDA correspondant à ta carte GPU :

ensuit les depandance
pip install openai-whisper
pip install git+https://github.com/m-bain/whisperX.git
pip install demucs
sudo apt install ffmpeg

ensuite le premier lancement du programme téléchargera les package complémentaires 
