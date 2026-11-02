# shellcheck shell=bash
# bash completion for logsleuth. Install: source this file, or drop it in
# ~/.local/share/bash-completion/completions/logsleuth (install.sh does this).
_logsleuth() {
  local cur prev cmds opts
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  cmds="summary top errors bruteforce version help"
  opts="-c -n -f -h -V"
  case "$prev" in
    -f) mapfile -t COMPREPLY < <(compgen -W "ip path status" -- "$cur"); return ;;
    -c) mapfile -t COMPREPLY < <(compgen -f -- "$cur"); return ;;
  esac
  if [[ "$cur" == -* ]]; then
    mapfile -t COMPREPLY < <(compgen -W "$opts" -- "$cur")
  else
    mapfile -t COMPREPLY < <(compgen -W "$cmds" -- "$cur")
  fi
}
complete -F _logsleuth logsleuth
