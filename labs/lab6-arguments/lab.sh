#!/usr/bin/env bash
# Lab 6 — Arguments, options, and UX: positional parameters, getopts for short
# options (with arguments and error handling), subcommands, stdin-vs-file, and
# exit codes as an API. Project milestone: logsleuth's full command line.
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/../_lib.sh"
W="$(lab_workdir lab6)"; cd "$W" || exit 1; make_fixtures "$W/fx"
A="$W/fx/access.log"

echo "== positional parameters: \$1.. \$@ \$# and shift =="
first_and_rest() { echo "first=$1 count=$#"; shift; echo "rest=$*"; }
is_eq "\$1 and \$#" "$(first_and_rest a b c | head -1)" "first=a count=3"
is_eq "shift drops \$1" "$(first_and_rest a b c | tail -1)" "rest=b c"
is_eq "\"\$@\" preserves spaced args" "$(set -- 'x y' z; printf '[%s]' "$@")" "[x y][z]"

echo "== getopts parses short options, with and without arguments =="
# a self-contained parser like logsleuth's: -n takes a number, -v is a flag
parse() {
  local n=10 verbose=0 OPTIND opt
  while getopts ":n:v" opt; do
    case "$opt" in
      n) n="$OPTARG" ;;
      v) verbose=1 ;;
      :)  echo "ERR:need-arg:$OPTARG"; return 2 ;;
      \?) echo "ERR:unknown:$OPTARG"; return 2 ;;
    esac
  done
  shift $((OPTIND-1))
  echo "n=$n verbose=$verbose rest=$*"
}
is_eq "option with argument -n 5"    "$(parse -n 5 file)"  "n=5 verbose=0 rest=file"
is_eq "flag -v and bundled -vn"      "$(parse -v -n 3 f)"  "n=3 verbose=1 rest=f"
is_eq "options stop at the first non-option" "$(parse -v cmd -n 9)" "n=10 verbose=1 rest=cmd -n 9"
is_eq "missing argument is caught (:)"  "$(parse -n)"      "ERR:need-arg:n"
is_eq "unknown option is caught (\\?)"  "$(parse -z)"      "ERR:unknown:z"

echo "== a tool reads a FILE argument OR stdin when none is given =="
reader() { if [[ $# -ge 1 ]]; then wc -l < "$1"; else wc -l; fi; }
is_eq "reads a named file"        "$(reader "$A" | tr -d ' ')" "140"
is_eq "reads stdin when no file"  "$(reader < "$A" | tr -d ' ')" "140"

echo "== exit codes are the script's API: distinct codes for distinct outcomes =="
api() { case "$1" in ok) return 0;; bad-usage) return 2;; notfound) return 1;; esac; }
api ok;        is_eq "success -> 0" "$?" "0"
api notfound;  is_eq "not found -> 1" "$?" "1"
api bad-usage; is_eq "usage error -> 2" "$?" "2"

echo "== the project: logsleuth's real command line =="
contains "-V prints the version"              "$(logsleuth -V)" "logsleuth 1.0.0"
contains "help lists the subcommands"         "$(logsleuth help)" "bruteforce"
is_eq "-n 2 limits top to 2 rows"             "$(logsleuth -n 2 top "$A" | grep -c '  ')" "2"
is_eq "-f path switches the top field"        "$(logsleuth -n 1 -f path top "$A" | awk 'NR==2{print $2}')" "/api/predict"
is_eq "reads stdin when FILE is omitted"      "$(logsleuth summary < "$A" | awk '/requests/{print $2}')" "140"
check "unknown option -> exit 2"              bash -c 'logsleuth -Q top "$1" 2>/dev/null; [ $? -eq 2 ]' _ "$A"
check "-n with a non-number -> exit 2"        bash -c 'logsleuth -n abc top "$1" 2>/dev/null; [ $? -eq 2 ]' _ "$A"
contains "a bad -f field is rejected clearly" "$(logsleuth -f bogus top "$A" 2>&1)" "unknown -f field"

summary lab6
