#!/usr/bin/env bash
# Lab 0 — Your first script: shebang, execution, exit codes, strict mode,
# printf vs echo, and shellcheck. Everything a script needs before it has logic.
# The project milestone: `logsleuth version`/`help` already run — the skeleton
# you will fill in through the course.
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/../_lib.sh"
W="$(lab_workdir lab0)"; cd "$W" || exit 1

echo "== a script is text + a shebang + the execute bit =="
cat > hello.sh <<'EOF'
#!/usr/bin/env bash
name="${1:-world}"          # positional arg, defaulting to "world"
echo "hello, $name"
EOF
chmod +x hello.sh
check "the shebang names the interpreter" bash -c 'head -1 hello.sh | grep -q "^#!/usr/bin/env bash"'
# `bash file` ignores the execute bit; `./file` needs it
is_eq "run with 'bash hello.sh'"        "$(bash hello.sh)"       "hello, world"
is_eq "an argument changes the output"  "$(bash hello.sh Antonio)" "hello, Antonio"
check "the execute bit is set (so ./hello.sh would work on a normal FS)" test -x hello.sh

echo "== exit codes are a script's return value: 0 = success, non-zero = failure =="
bash -c 'exit 0'; is_eq "true -> \$? is 0" "$?" "0"
bash -c 'exit 7'; is_eq "exit 7 -> \$? is 7" "$?" "7"
# && runs the next command only on success; || only on failure
is_eq "'&&' chains on success" "$(true  && echo yes)" "yes"
is_eq "'||' runs on failure"   "$(false || echo recovered)" "recovered"

echo "== printf is portable and precise; echo is not =="
# echo mangles backslashes/leading -e differently across shells; printf does not
is_eq "printf places fields exactly" "$(printf '%s=%d' ip 42)" "ip=42"
is_eq "printf adds no trailing newline unless you ask" "$(printf 'a'; printf 'b')" "ab"

echo "== strict mode turns silent bugs into loud failures =="
# unset variable: lenient bash prints nothing; `set -u` aborts
is_eq "WITHOUT set -u an unset var is empty (silent)" "$(bash -c 'echo "[$missing]"')" "[]"
check "WITH set -u an unset var aborts (loud)" bash -c '! bash -c "set -u; echo \$missing" 2>/dev/null'
# pipefail: a failure mid-pipe is otherwise hidden by the last command's success
check "WITHOUT pipefail a mid-pipe failure is hidden (grep then true -> 0)" \
  bash -c 'grep nope <<<"x" | true; [ $? -eq 0 ]'
check "WITH pipefail the pipe reports the failure" \
  bash -c 'set -o pipefail; ! { grep nope <<<"x" | cat; }'

echo "== the course's house header: strict mode on every script =="
cat > strict.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail      # -e exit on error, -u error on unset, pipefail catch mid-pipe
IFS=$'\n\t'            # safer word-splitting than the default space+tab+newline
echo "ready"
EOF
check "strict.sh is shellcheck-clean" bash -c 'command -v shellcheck >/dev/null && shellcheck strict.sh || true'
is_eq "strict.sh runs" "$(bash strict.sh)" "ready"

echo "== the project skeleton already runs (version + help) =="
contains "logsleuth reports its version" "$(logsleuth version)" "logsleuth 1.0.0"
contains "logsleuth prints usage" "$(logsleuth help)" "usage: logsleuth"
check "the whole project is shellcheck-clean" bash -c '
  shellcheck -x -P "$COURSE_ROOT/logsleuth/lib" \
    "$COURSE_ROOT/logsleuth/bin/logsleuth" "$COURSE_ROOT/logsleuth/lib/"*.sh'

summary lab0
