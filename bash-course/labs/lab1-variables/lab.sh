#!/usr/bin/env bash
# Lab 1 — Variables, quoting, and parameter expansion. The single biggest source
# of bash bugs is an unquoted variable; the single biggest source of clever,
# readable bash is parameter expansion. Both, proven. Project milestone: build a
# report filename from a log path and read config values the way logsleuth does.
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/../_lib.sh"
W="$(lab_workdir lab1)"; cd "$W" || exit 1

echo "== assignment has NO spaces; expansion needs a \$ =="
name="logsleuth"; version="1.0.0"
is_eq "two variables, one string" "$name-$version" "logsleuth-1.0.0"
is_eq "command substitution captures output" "$(printf 'hi')" "hi"

echo "== QUOTE every expansion: unquoted \$var splits on spaces and globs =="
path="/var/log/my access.log"              # a path with a space (and imagine a *)
# unquoted, the space splits this into TWO arguments; quoted, it stays one
is_eq "unquoted word-splits (2 args)" "$(set -- $path; echo $#)" "2"
is_eq "quoted stays one argument"     "$(set -- "$path"; echo $#)" "1"
touch 'a.log' 'b.log'; glob='*.log'
is_eq "unquoted a glob EXPANDS to filenames" "$(set -- $glob; echo $#)" "2"
is_eq "quoted a glob stays literal"          "$(set -- "$glob"; echo "$1")" "*.log"

echo "== parameter expansion: defaults, length, case =="
is_eq "default when unset: \${x:-fallback}" "${missing:-fallback}" "fallback"
top_n="${TOP_N:-10}"; is_eq "use an env value or a default" "$top_n" "10"
word="Error"
is_eq "length \${#word}"      "${#word}" "5"
is_eq "lowercase \${word,,}"  "${word,,}" "error"
is_eq "uppercase \${word^^}"  "${word^^}" "ERROR"

echo "== parameter expansion: strip prefixes/suffixes to build names =="
logpath="/var/log/nginx/access.log"
base="${logpath##*/}"                        # strip the longest leading */  -> access.log
is_eq "basename via \${x##*/}" "$base" "access.log"
dir="${logpath%/*}"                          # strip the shortest trailing /* -> the directory
is_eq "dirname via \${x%/*}" "$dir" "/var/log/nginx"
stem="${base%.log}"                          # strip the .log suffix -> access
is_eq "strip .log suffix via \${x%.log}" "$stem" "access"
# build a report filename the way logsleuth would, deterministically
stamp="2026-10-16"
report="report-${stem}-${stamp}.txt"
is_eq "composed report filename" "$report" "report-access-2026-10-16.txt"

echo "== parameter expansion: substitution and substrings =="
line="203.0.113.9 - - [16/Oct/2026] POST /api/predict 401"
is_eq "replace all via \${x//a/b}" "${line//401/BLOCKED}" "203.0.113.9 - - [16/Oct/2026] POST /api/predict BLOCKED"
ip="${line%% *}"                             # everything up to the first space
is_eq "first field via \${x%% *}" "$ip" "203.0.113.9"

echo "== arithmetic with \$(( )) =="
a=40; b=10
is_eq "integer math" "$(( a + b * 2 ))" "60"
is_eq "comparison yields 1/0" "$(( a > b ))" "1"
count=0; (( count += 5 )); is_eq "in-place arithmetic" "$count" "5"

echo "== read turns input into variables (used by the config parser) =="
# split "key = value" on '=' the way logsleuth's load_config does
IFS='=' read -r k v <<< "top_n = 25"
is_eq "key trimmed"   "$(echo "${k// /}")" "top_n"
is_eq "value trimmed" "$(echo "${v// /}")" "25"

echo "== the project: logsleuth reads a config VALUE and quotes a spaced path =="
make_fixtures "$W/fx"
# a config file that changes the default top count; logsleuth must honor it
printf 'top_n = 3\n' > my.conf
is_eq "config top_n=3 limits 'top' to 3 rows" \
  "$(logsleuth -c my.conf top "$W/fx/access.log" | grep -c '  ')" "3"
# a log path WITH A SPACE must survive because logsleuth quotes its expansions
cp "$W/fx/access.log" 'my access.log'
contains "a spaced filename still analyzes (quoting works end to end)" \
  "$(logsleuth summary 'my access.log')" "requests     140"

summary lab1
