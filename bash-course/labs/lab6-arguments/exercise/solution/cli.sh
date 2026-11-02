#!/usr/bin/env bash
# Lab 6 solution — getopts option parsing and file-or-stdin input.

# parse_opts: parse -n N (default 10) and -v (flag); print "n=.. v=.. rest=..".
parse_opts() {
  local n=10 v=0 OPTIND opt
  while getopts ":n:v" opt; do
    case "$opt" in
      n)  n="$OPTARG" ;;
      v)  v=1 ;;
      :)  printf 'error: -%s needs an argument\n' "$OPTARG" >&2; return 2 ;;
      \?) printf 'error: unknown option -%s\n' "$OPTARG" >&2; return 2 ;;
    esac
  done
  shift $((OPTIND-1))
  printf 'n=%s v=%s rest=%s\n' "$n" "$v" "$*"
}

# read_input: print the named FILE if given, otherwise read from stdin.
read_input() {
  if [[ $# -ge 1 ]]; then
    cat -- "$1"
  else
    cat
  fi
}
