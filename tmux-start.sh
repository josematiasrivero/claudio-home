#!/bin/bash
# Creates a tmux session with one window per subfolder in /code,
# each window split into 4 panes (2x2 grid).

SESSION="dev"
CODE_DIR="/root/code"

tmux kill-session -t "$SESSION" 2>/dev/null

FIRST=true
for dir in "$CODE_DIR"/*/; do
    name=$(basename "$dir")

    if $FIRST; then
        tmux new-session -d -s "$SESSION" -n "$name" -c "$dir"
        FIRST=false
    else
        tmux new-window -t "$SESSION" -n "$name" -c "$dir"
    fi

    # Split into 2x2 grid
    tmux split-window -t "$SESSION:$name" -h -c "$dir"   # left | right
    tmux split-window -t "$SESSION:$name.0" -v -c "$dir"  # top-left / bottom-left
    tmux split-window -t "$SESSION:$name.2" -v -c "$dir"  # top-right / bottom-right

    tmux select-pane -t "$SESSION:$name.0"
done

tmux select-window -t "$SESSION:0"
tmux attach-session -t "$SESSION"
