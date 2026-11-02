#!/usr/bin/env bash
# install.sh — put logsleuth on your PATH, with its man page and completion.
# Default prefix ~/.local; override with PREFIX=/usr/local ./install.sh
set -euo pipefail
SRC="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${PREFIX:-$HOME/.local}"

install -d "$PREFIX/bin" "$PREFIX/share/man/man1" "$PREFIX/share/bash-completion/completions"
# symlink the entry point; bin/logsleuth resolves the link to find lib/ and etc/
ln -sf "$SRC/bin/logsleuth" "$PREFIX/bin/logsleuth"
install -m 0644 "$SRC/man/logsleuth.1" "$PREFIX/share/man/man1/logsleuth.1"
install -m 0644 "$SRC/completions/logsleuth.bash" "$PREFIX/share/bash-completion/completions/logsleuth"

echo "installed:"
echo "  $PREFIX/bin/logsleuth        (ensure $PREFIX/bin is on your PATH)"
echo "  man 1 logsleuth              (ensure $PREFIX/share/man is on MANPATH)"
echo "  bash completion              (new shells; or: source the completion file)"
echo "config: copy $SRC/etc/logsleuth.conf to ~/.config/ and point -c at it, or set LOGSLEUTH_CONFIG."
