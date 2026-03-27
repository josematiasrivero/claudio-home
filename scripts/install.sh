#!/bin/bash
# Registra los aliases en zshrc o bashrc

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ALIASES_FILE="$SCRIPT_DIR/aliases.sh"
SOURCE_LINE="source \"$ALIASES_FILE\""

install_aliases() {
    local rc_file="$1"
    if grep -qF "$ALIASES_FILE" "$rc_file" 2>/dev/null; then
        echo "Ya registrado en $rc_file"
    else
        echo "" >> "$rc_file"
        echo "# claudio-home aliases" >> "$rc_file"
        echo "$SOURCE_LINE" >> "$rc_file"
        echo "Registrado en $rc_file"
    fi
}

if [ -f "$HOME/.zshrc" ]; then
    install_aliases "$HOME/.zshrc"
fi

if [ -f "$HOME/.bashrc" ]; then
    install_aliases "$HOME/.bashrc"
fi

if [ ! -f "$HOME/.zshrc" ] && [ ! -f "$HOME/.bashrc" ]; then
    echo "No se encontro .zshrc ni .bashrc. Creando .bashrc..."
    install_aliases "$HOME/.bashrc"
fi

echo "Listo. Ejecuta 'source ~/.zshrc' o 'source ~/.bashrc' para activar los aliases."
