#!/bin/bash
# Aliases para la workstation claudio-home

# Git aliases
alias gst='git status'
alias gpl='git pull'
alias gco='git checkout'

# Docker aliases
alias docker-stop-all='docker stop $(docker ps -q) 2>/dev/null || echo "No hay contenedores corriendo"'
alias docker-prune='docker system prune -a --volumes -f'
alias docker-remove-unused='docker image prune -a -f'

# Reload aliases
alias reload-aliases='source "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")/aliases.sh" && echo "Aliases recargados"'
