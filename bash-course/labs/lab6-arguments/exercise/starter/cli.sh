#!/usr/bin/env bash
# Lab 6 exercise — getopts option parsing and file-or-stdin input.
# Complete each TODO, then run:  bash ../grade.sh

# parse_opts: parse -n N (default 10) and -v (flag), then print a summary line
#   n=<N> v=<0|1> rest=<remaining args>
# Return 2 on a missing argument or an unknown option.
parse_opts() {
  local n=10 v=0 OPTIND opt
  # TODO: while getopts ":n:v" opt; do case "$opt" in
  #   n) n="$OPTARG" ;;  v) v=1 ;;
  #   :)  printf 'error: -%s needs an argument\n' "$OPTARG" >&2; return 2 ;;
  #   \?) printf 'error: unknown option -%s\n' "$OPTARG" >&2; return 2 ;;
  # esac; done
  # shift $((OPTIND-1))
  printf 'n=%s v=%s rest=%s\n' "$n" "$v" "FIXME"
}

# read_input: print the named FILE if given, otherwise read from stdin.
read_input() {
  # TODO: if [[ $# -ge 1 ]]; then cat -- "$1"; else cat; fi
  printf 'FIXME\n'
}
