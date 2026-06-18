#!/usr/bin/env bash
# ~/jsqr/casa/scripts/git-status.sh

# Show git repository status for all repos in ~/jsqr/
echo "=== Git Repository Status ==="

if command -v git &> /dev/null; then
    if [[ -d "$HOME/jsqr" ]]; then
        for repo in "$HOME/jsqr"/*/; do
            if [[ -d "$repo/.git" ]]; then
                echo -e "\n--- $(basename "$repo") ---"
                (cd "$repo" && git summary 2>/dev/null || echo "Not a git repo or git-extras not installed")
            fi
        done
    else
        echo "No ~/jsqr directory found"
    fi
else
    echo "git command not found"
fi

echo
