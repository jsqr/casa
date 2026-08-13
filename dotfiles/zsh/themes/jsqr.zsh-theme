autoload -Uz add-zsh-hook

git_prompt_info() {
  local gitdir ref state dirty
  gitdir=$(git rev-parse --git-dir 2>/dev/null) || return

  # Detached HEAD: fall back to short SHA, flagged in red
  if ! ref=$(git symbolic-ref --short HEAD 2>/dev/null); then
    ref="%F{red}➦ $(git rev-parse --short HEAD 2>/dev/null)%f%F{yellow}"
  fi

  # In-progress operations, detected from state files in the git dir
  if   [[ -d $gitdir/rebase-merge || -d $gitdir/rebase-apply ]]; then state='rebase'
  elif [[ -f $gitdir/MERGE_HEAD ]];       then state='merge'
  elif [[ -f $gitdir/CHERRY_PICK_HEAD ]]; then state='cherry-pick'
  elif [[ -f $gitdir/REVERT_HEAD ]];      then state='revert'
  elif [[ -f $gitdir/BISECT_LOG ]];       then state='bisect'
  fi
  [[ -n $state ]] && state="%F{red}|${state}%f%F{yellow}"

  # One status call: * = dirty, ✖ = unmerged conflicts
  local status_out=$(git status --porcelain 2>/dev/null)
  [[ -n $status_out ]] && dirty="%F{red}*%f"
  local -a lines=(${(f)status_out})
  (( ${#${(M)lines:#(U?|?U|AA|DD)*}} )) && dirty="%F{red}✖%f"

  echo "%F{yellow}‹${ref}${state}${dirty}%F{yellow}›%f "
}

virtualenv_prompt_info() {
  [[ -n "${VIRTUAL_ENV:-}" ]] || return
  echo "${ZSH_THEME_VIRTUALENV_PREFIX}${VIRTUAL_ENV:t}${ZSH_THEME_VIRTUALENV_SUFFIX}"
}

# Based on bira and gnzh themes
setopt prompt_subst

# Check the UID
if [[ $UID -ne 0 ]]; then # normal user
  PR_USER='%F{green}%n%f'
  PR_PROMPT='%F{245}⊳%f '
else # root
  PR_USER='%F{red}%n%f'
  PR_PROMPT='%F{red}⊳ %f'
fi

# Check if we are on SSH or not
if [[ -n "$SSH_CLIENT" || -n "$SSH2_CLIENT" ]]; then
  PR_HOST='%F{red}%M%f' # SSH: FQDN
else
  PR_HOST='%F{green}%m%f' # no SSH
fi

# Cache git and venv info once per prompt to avoid double subprocess calls
_jsqr_precmd() {
  _JSQR_GIT_INFO="$(git_prompt_info)"
  _JSQR_VENV_INFO="$(virtualenv_prompt_info)"
}
add-zsh-hook precmd _jsqr_precmd

prompt_line() {
  print -rn -- '%F{245}─────⭘%f'
}

PROMPT='%F{245}╭─%f${_JSQR_VENV_INFO}${PR_USER}%F{cyan}@${PR_HOST} %B%F{blue}%~%f%b ${_JSQR_GIT_INFO}$(prompt_line)
%F{245}╰─%f${PR_PROMPT}'
RPROMPT='%(?..%F{red}%? ↵%f)'

ZSH_THEME_VIRTUALENV_PREFIX="%F{red}("
ZSH_THEME_VIRTUALENV_SUFFIX=")%f "
