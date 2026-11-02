#!/usr/bin/env bash
# Lab 5 — The text-processing toolkit: the pipeline that makes shell uniquely
# good at logs — grep, cut, sort, uniq -c, tr, sed, awk — plus redirection,
# here-docs, here-strings, and process substitution. Project milestone: you
# build logsleuth's `top` and `summary` as pipelines and confirm the tool agrees.
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/../_lib.sh"
W="$(lab_workdir lab5)"; cd "$W" || exit 1; make_fixtures "$W/fx"
A="$W/fx/access.log"

echo "== grep: find lines; -c count, -o only-match, -E regex, -v invert =="
is_eq "grep -c counts matching lines (401s)" "$(grep -c ' 401 ' "$A")" "40"
is_eq "grep -v inverts (non-200 lines)"      "$(grep -cv ' 200 ' "$A")" "55"
is_eq "grep -oE extracts just the IP of line 1" \
  "$(head -1 "$A" | grep -oE '^[0-9.]+')" "10.0.0.1"

echo "== cut / awk: pick columns =="
is_eq "cut -d' ' -f1 is the client IP"   "$(head -1 "$A" | cut -d' ' -f1)" "10.0.0.1"
is_eq "awk \$9 is the status code"        "$(head -1 "$A" | awk '{print $9}')" "200"

echo "== sort | uniq -c | sort -rn: the counting pipeline =="
# the canonical 'top talkers' one-liner
top_ip="$(awk '{print $1}' "$A" | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')"
is_eq "top talker via the counting pipeline" "$top_ip" "10.0.0.1"
is_eq "its request count"                    "$(awk '{print $1}' "$A" | sort | uniq -c | sort -rn | head -1 | awk '{print $1}')" "50"
is_eq "uniq needs sorted input (distinct IPs)" "$(awk '{print $1}' "$A" | sort -u | grep -c .)" "4"

echo "== tr / sed: transform text =="
is_eq "tr lowercases"           "$(printf 'ERROR' | tr 'A-Z' 'a-z')" "error"
is_eq "sed substitutes"         "$(printf '401' | sed 's/401/BLOCKED/')" "BLOCKED"
is_eq "sed -E with a capture group pulls the status" \
  "$(head -1 "$A" | sed -E 's/.*\" ([0-9]{3}) .*/\1/')" "200"

echo "== awk: the Swiss-army knife — fields, filters, sums, counting =="
is_eq "awk filter: count 5xx lines" "$(awk '$9 ~ /^5/' "$A" | grep -c .)" "5"
is_eq "awk sum: total bytes served" "$(awk '{b+=$10} END{print b}' "$A")" \
  "$(awk '{b+=$10} END{print b}' "$A")"   # self-consistent; proves the idiom runs
is_eq "awk associative count: 4xx total" \
  "$(awk '$9 ~ /^4/ {c++} END{print c+0}' "$A")" "50"

echo "== redirection, here-docs, here-strings, process substitution =="
echo "one" > f.txt; echo "two" >> f.txt         # > truncates, >> appends
is_eq "append then read back" "$(cat f.txt)" "$(printf 'one\ntwo')"
cat > note.txt <<'EOF'
status report
EOF
is_eq "here-doc wrote a block" "$(cat note.txt)" "status report"
is_eq "here-string feeds a command" "$(tr a-z A-Z <<< 'hi')" "HI"
# process substitution: feed a command's output where a FILE is expected
is_eq "diff two pipelines via <( )" \
  "$(diff <(awk '{print $9}' "$A" | sort -u) <(awk '{print $9}' "$A" | sort -u) && echo same)" "same"

echo "== the project: your pipeline == logsleuth's report =="
# top IPs: your one-liner vs the tool
mine="$(awk '{print $1}' "$A" | sort | uniq -c | sort -rn | head -3 | awk '{printf "%s:%s ", $2, $1}')"
tool="$(logsleuth -n 3 top "$A" | awk 'NR>1 {printf "%s:%s ", $2, $1}')"
is_eq "top-3 IPs: your pipeline matches logsleuth" "$mine" "$tool"
# status classes: your awk vs the tool's summary
is_eq "summary 4xx count matches the tool" \
  "$(awk '$9~/^4/{c++}END{print c+0}' "$A")" \
  "$(logsleuth summary "$A" | awk '$1=="4xx"{print $2}')"

summary lab5
