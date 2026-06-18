autoload -Uz add-zsh-hook

git_prompt_info() {
  local ref
  ref=$(git symbolic-ref --short HEAD 2>/dev/null) || return
  local dirty
  if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
    dirty="%F{red}*%f"
  fi
  echo "%F{yellow}‹${ref}${dirty}%F{yellow}›%f "
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
  PR_PROMPT='%F{245}➤%f '
else # root
  PR_USER='%F{red}%n%f'
  PR_PROMPT='%F{red}➤ %f'
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
  print -rn -- '%F{245}─────%f'
}

PROMPT='%F{245}╭─%f${_JSQR_VENV_INFO}${PR_USER}%F{cyan}@${PR_HOST} %B%F{blue}%~%f%b ${_JSQR_GIT_INFO}$(prompt_line)
%F{245}╰─%f${PR_PROMPT}'
RPROMPT='%(?..%F{red}%? ↵%f)'

ZSH_THEME_VIRTUALENV_PREFIX="%F{red}("
ZSH_THEME_VIRTUALENV_SUFFIX=")%f "
