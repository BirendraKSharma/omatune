#!/usr/bin/bash
# Tests for ytm-store in a throwaway HOME. No network: the audio cache is
# exercised with planted files. Run with: bash tests/store-test.sh
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

T=$(mktemp -d) || exit 1
trap 'rm -rf -- "$T"' EXIT
passed=0 failed=0
st() { env -i HOME="$T" PATH=/usr/bin /usr/bin/python3 -I -S ./ytm-store "$@"; }
check() {
  local name=$1 got=$2 want=$3
  if [[ $got == "$want" ]]; then passed=$((passed + 1)); else failed=$((failed + 1)); printf 'FAIL %s\n  got:  %s\n  want: %s\n' "$name" "$got" "$want"; fi
}
S=$T/.local/state/codydon-omatune
C=$T/.cache/codydon-omatune/audio

check "reads create nothing" "$(st history-get; st queue-get; st cache-list >/dev/null; find "$T" -mindepth 1 | wc -l)" \
  '{"ok":true,"history":[]}
{"ok":true,"queue":{"tracks":[],"index":0,"position":0.0}}
0'

st history-add "daft punk" >/dev/null; st history-add Future >/dev/null
check "history is newest first, case-insensitive" "$(st history-add 'DAFT PUNK')" '{"ok":true,"history":["DAFT PUNK","Future"]}'
check "history strips control characters" "$(st history-add "$(printf 'a\007b\342\200\256c')" | cut -c1-28)" '{"ok":true,"history":["abc",'
check "history remove" "$(st history-remove future | grep -c Future)" "0"
check "state dir is 0700, files 0600" "$(stat -c %a "$S" "$S/history.json" | tr '\n' ' ')" "700 600 "

st queue-put '{"tracks":[{"id":"wU26xVT_vBU","title":"One","duration":"5:21"},{"id":"bad"},{"id":"Rgrt_8mXrK8","title":"Two"}],"index":9,"position":"x"}' >/dev/null
check "queue keeps only valid tracks and clamps" "$(st queue-get)" \
  '{"ok":true,"queue":{"tracks":[{"id":"wU26xVT_vBU","title":"One","artist":"","album":"","duration":"5:21"},{"id":"Rgrt_8mXrK8","title":"Two","artist":"","album":"","duration":""}],"index":1,"position":0.0}}'
check "empty queue deletes the file" "$(st queue-put '{"tracks":[]}' >/dev/null; test -e "$S/queue.json"; echo $?)" "1"
check "invalid queue json is refused" "$(st queue-put 'nope' | cut -c1-12)" '{"ok": false'

ln -s /etc/hostname "$S/queue.json"
check "symlinked file is refused" "$(st queue-get | cut -c1-12)" '{"ok": false'
rm "$S/queue.json"; mkfifo "$S/queue.json"
check "fifo is refused without hanging" "$(timeout 5 env -i HOME="$T" PATH=/usr/bin /usr/bin/python3 -I -S ./ytm-store queue-get | cut -c1-12)" '{"ok": false'
rm "$S/queue.json"; head -c 300000 /dev/zero > "$S/queue.json"
check "oversized file is refused" "$(st queue-get | cut -c1-12)" '{"ok": false'
rm "$S/queue.json"
mv "$S" "$T/real"; ln -s "$T/real" "$S"
check "symlinked directory is refused" "$(st history-get | cut -c1-12)" '{"ok": false'
rm "$S"; mv "$T/real" "$S"

mkdir -p "$C"; chmod 700 "$C"
printf '\x1a\x45\xdf\xa3fakewebm' > "$C/wU26xVT_vBU.webm"
printf '{"id":"wU26xVT_vBU","title":"One More Time","artist":"Daft Punk"}' > "$C/wU26xVT_vBU.json"
printf 'x' > "$C/not-a-song.webm"
ln -s /etc/hostname "$C/Rgrt_8mXrK8.webm"
check "cache list shows only real, well-named files" "$(st cache-list | sed 's/"dir":"[^"]*",//')" \
  '{"ok":true,"tracks":[{"id":"wU26xVT_vBU","title":"One More Time","artist":"Daft Punk","album":"","duration":"","ext":"webm","size":12}],"bytes":12}'
check "cache touch refuses bad ids" "$(st cache-touch ../../x | cut -c1-12)" '{"ok": false'
check "cache fetch refuses a zero limit" "$(st cache-fetch 0 wU26xVT_vBU a b c 1:00 | cut -c1-12)" '{"ok": false'
st cache-clear >/dev/null
check "cache clear removes only its own names" "$(ls -A "$C" | LC_ALL=C sort | tr '\n' ' ')" "Rgrt_8mXrK8.webm not-a-song.webm "
check "cache clear leaves symlink targets alone" "$(test -f /etc/hostname && echo ok)" "ok"
check "unknown command" "$(st rm-rf)" '{"ok": false, "error": "Unknown command."}'

printf 'store-test: %d passed' "$passed"
(( failed )) && { printf ', %d failed\n' "$failed"; exit 1; }
echo
