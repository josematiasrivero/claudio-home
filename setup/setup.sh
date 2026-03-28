#!/bin/bash
# Setup script for claudio-home workstation
# Run: bash setup/setup.sh [options]
# Options: --all, --claude, --tmux, --aliases, --ohmyzsh, --docker

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[>>]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ---------- 1. Claude Code ----------
install_claude_code() {
    echo ""
    echo "=== Installing Claude Code ==="

    if command -v claude &>/dev/null; then
        info "Claude Code already installed: $(claude --version 2>/dev/null || echo 'unknown version')"
        return
    fi

    # Requires Node.js
    if ! command -v node &>/dev/null; then
        warn "Node.js not found. Installing via NodeSource..."
        curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
        apt-get install -y nodejs
    fi

    npm install -g @anthropic-ai/claude-code
    info "Claude Code installed"
}

# ---------- 2. Tmux ----------
install_tmux() {
    echo ""
    echo "=== Installing tmux ==="

    if command -v tmux &>/dev/null; then
        info "tmux already installed: $(tmux -V)"
        return
    fi

    apt-get update -qq
    apt-get install -y tmux
    info "tmux installed"
}

# ---------- 3. Aliases ----------
install_aliases() {
    echo ""
    echo "=== Applying script aliases ==="

    bash "$REPO_DIR/scripts/install.sh"
    info "Aliases applied"
}

# ---------- 4. Oh My Zsh ----------
install_ohmyzsh() {
    echo ""
    echo "=== Installing Oh My Zsh ==="

    if [ -d "$HOME/.oh-my-zsh" ]; then
        info "Oh My Zsh already installed"
        return
    fi

    # Ensure zsh is installed
    if ! command -v zsh &>/dev/null; then
        warn "zsh not found. Installing..."
        apt-get update -qq
        apt-get install -y zsh
    fi

    # Install Oh My Zsh unattended (keeps current shell)
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    info "Oh My Zsh installed"

    # Set zsh as default shell if not already
    if [ "$SHELL" != "$(which zsh)" ]; then
        chsh -s "$(which zsh)" 2>/dev/null || warn "Could not change default shell to zsh. Run: chsh -s \$(which zsh)"
    fi
}

# ---------- 5. Docker ----------
install_docker() {
    echo ""
    echo "=== Installing Docker ==="

    if command -v docker &>/dev/null; then
        info "Docker already installed: $(docker --version)"
        return
    fi

    apt-get update -qq
    apt-get install -y ca-certificates curl gnupg

    # Add Docker GPG key and repo
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -qq
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Configure Docker and containerd to store data on /mnt/data/docker-system
    mkdir -p /mnt/data/docker-system/docker /mnt/data/docker-system/containerd

    cat > /etc/docker/daemon.json <<'DJSON'
{
  "data-root": "/mnt/data/docker-system/docker"
}
DJSON

    # Update containerd root in config
    if [ -f /etc/containerd/config.toml ]; then
        sed -i 's|^root = .*|root = "/mnt/data/docker-system/containerd"|' /etc/containerd/config.toml
    fi

    # Start docker if not running
    systemctl start containerd 2>/dev/null || true
    systemctl start docker 2>/dev/null || true
    systemctl enable docker 2>/dev/null || true

    info "Docker installed (data-root: /mnt/data/docker-system)"
}

# ---------- 6. Clone repos ----------
clone_repos() {
    echo ""
    echo "=== Cloning project repos ==="

    CODE_DIR="$REPO_DIR/code"
    mkdir -p "$CODE_DIR"

    if ! command -v git &>/dev/null; then
        warn "git not found. Installing..."
        apt-get update -qq
        apt-get install -y git
    fi

    if [ -d "$CODE_DIR/bearme" ]; then
        info "bearme already cloned"
    else
        git clone https://github.com/josematiasrivero/bearme.git "$CODE_DIR/bearme"
        info "bearme cloned"
    fi

    if [ -d "$CODE_DIR/poc-cotizador" ]; then
        info "poc-cotizador already cloned"
    else
        git clone https://github.com/josematiasrivero/poc-cotizador.git "$CODE_DIR/poc-cotizador"
        info "poc-cotizador cloned"
    fi
}

# ---------- Menu ----------
run_all() {
    install_claude_code
    install_tmux
    install_aliases
    install_ohmyzsh
    install_docker
    clone_repos
}

show_menu() {
    echo ""
    echo "claudio-home setup"
    echo "=================="
    echo "1) Claude Code"
    echo "2) tmux"
    echo "3) Script aliases"
    echo "4) Oh My Zsh"
    echo "5) Docker"
    echo "6) Clone repos"
    echo "A) All"
    echo "Q) Quit"
    echo ""
    read -rp "Select options (e.g. 1 3 5 or A): " choices

    for choice in $choices; do
        case $choice in
            1) install_claude_code ;;
            2) install_tmux ;;
            3) install_aliases ;;
            4) install_ohmyzsh ;;
            5) install_docker ;;
            6) clone_repos ;;
            [Aa]) run_all ;;
            [Qq]) exit 0 ;;
            *) error "Unknown option: $choice" ;;
        esac
    done
}

# ---------- Main ----------
if [ "$#" -eq 0 ]; then
    show_menu
else
    for arg in "$@"; do
        case $arg in
            --all)      run_all ;;
            --claude)   install_claude_code ;;
            --tmux)     install_tmux ;;
            --aliases)  install_aliases ;;
            --ohmyzsh)  install_ohmyzsh ;;
            --docker)   install_docker ;;
            --repos)    clone_repos ;;
            *)          error "Unknown flag: $arg"; exit 1 ;;
        esac
    done
fi

echo ""
info "Setup complete!"
