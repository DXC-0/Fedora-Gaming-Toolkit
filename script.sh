#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "Ce script doit être exécuté avec sudo !" >&2
  exit 1
fi

update_system() {
  echo "Mise à jour du système..."
  dnf upgrade --refresh -y
}

# 📦 Installation des dépôts RPM Fusion
install_rpmfusion() {
  echo "📦 Installation des dépôts RPM Fusion..."
  dnf install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
}

install_gpu_driver() {
  echo "Détection du GPU et installation des pilotes"
  GPU_INFO=$(lspci | grep -E "VGA|3D")
  echo "GPU détecté : $GPU_INFO"

  if echo "$GPU_INFO" | grep -qi "NVIDIA"; then
    echo "GPU NVIDIA détecté"
    dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
  elif echo "$GPU_INFO" | grep -qi "AMD"; then
    echo "GPU AMD détecté"
    dnf install -y mesa-dri-drivers mesa-libGL mesa-vulkan-drivers
  elif echo "$GPU_INFO" | grep -qi "Intel"; then
    echo "GPU Intel détecté"
  else
    echo "GPU non reconnu automatiquement"
  fi
}

install_codecs() {
  echo "📦  Installation des codecs multimédias..."
  dnf groupupdate -y multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
  dnf groupupdate -y sound-and-video
  dnf install -y gstreamer1-plugins-{base,good,bad-free,bad-freeworld,ugly} \
    gstreamer1-libav lame ffmpeg
}

install_gaming_tools() {
  echo "🎮 Installation des outils gaming..."
  echo "📦 Installation de Lutris"
  dnf install -y lutris
  echo "📦 Installation de Steam"
  dnf install -y steam
  echo "📦 Installation de Wine et dépendances"
  dnf install -y wine winetricks
  echo "📦 Installation de Heroic Games Launcher"
  TMP_DIR="/tmp/heroic-install"
  mkdir -p "$TMP_DIR"
  cd "$TMP_DIR"
  RPM_URL="https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/v2.18.1/heroic-2.18.1.rpm"
  wget "$RPM_URL" -O heroic.rpm
  dnf install -y ./heroic.rpm
  rm -rf "$TMP_DIR"
  
  echo "✅ Outils gaming installés !"
}


install_proton_ge() {
  echo "📦 Installation de Proton GE (GloriousEggroll)..."
  PROTON_DIR="$HOME/.steam/root/compatibilitytools.d"
  mkdir -p "$PROTON_DIR"
  cd "$PROTON_DIR"

  echo "Recherche de la dernière version de proton"
  LATEST_URL=$(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest | grep "browser_download_url" | grep ".tar.gz" | cut -d '"' -f 4)

  if [[ -z "$LATEST_URL" ]]; then
    echo "Impossible de récupérer la dernière version"
    return 1
  fi

  FILE_NAME=$(basename "$LATEST_URL")
  echo "📦 Téléchargement : $FILE_NAME"
  wget "$LATEST_URL"

  echo "Extraction..."
  tar -xvf "$FILE_NAME"
  rm "$FILE_NAME"

  echo "✅ Proton GE installé"
}

install_proton_cachyos() {
  echo "📦 Installation de Proton-CachyOS"
  PROTON_DIR="$HOME/.steam/root/compatibilitytools.d"
  mkdir -p "$PROTON_DIR"
  cd "$PROTON_DIR"

  echo "Recherche de la dernière version de proton"
  LATEST_URL=$(curl -s https://api.github.com/repos/CachyOS/proton-cachyos/releases/latest | grep "browser_download_url" | grep ".tar.xz" | cut -d '"' -f 4)

  if [[ -z "$LATEST_URL" ]]; then
    echo "Impossible de récupérer la dernière version"
    return 1
  fi

  FILE_NAME=$(basename "$LATEST_URL")
  echo "Téléchargement : $FILE_NAME"
  wget "$LATEST_URL"

  echo "Extraction..."
  tar -xvf "$FILE_NAME"
  rm "$FILE_NAME"

  echo "✅ Proton-CachyOS installé"
}

while true; do
  echo ""
  echo "Fedora Gaming Toolkit"
  echo ""
  echo "1️⃣  Mettre à jour le système"
  echo "2️⃣  Installer les dépôts RPM Fusion"
  echo "3️⃣  Détecter le GPU et installer le pilote"
  echo "4️⃣  Installer les codecs multimédias"
  echo "5️⃣  Installer les outils de gaming (Steam, Lutris, Heroic)"
  echo "6️⃣  Installer Proton GE"
  echo "7️⃣  Installer Proton-CachyOS"
  echo "8️⃣  Installation automatisée"
  echo "0️⃣  Quitter"
  echo ""
  read -p "Choisis une options pour paramétrer ta fedora (en cas de doute, utilise l'installation automatisée) : " choice

  case $choice in
    1) update_system ;;
    2) install_rpmfusion ;;
    3) install_gpu_driver ;;
    4) install_codecs ;;
    5) install_gaming_tools ;;
    6) install_proton_ge ;;
    7) install_proton_cachyos ;;
    8)
      update_system
      install_rpmfusion
      install_gpu_driver
      install_codecs
      install_gaming_tools
      install_proton_ge
      install_proton_cachyos
      ;;
    0) echo "Merci d'avoir utilisé mon script !"; exit 0 ;;
    *) echo "Option non valide" ;;
  esac
done
