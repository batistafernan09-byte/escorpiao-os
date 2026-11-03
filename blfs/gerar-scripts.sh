#!/bin/bash
# Gera os scripts de uma etapa do BLFS, na ordem certa, com a ferramenta oficial (jhalfs) lendo o livro BLFS 12.4.
# Uso: gerar-scripts.sh <jhalfs> <livro-blfs> <livro-lfs-arm64> <lista.txt> <pasta-de-saída> [scripts-da-etapa-anterior]
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
JH=$(realpath "$1"); BLFS=$(realpath "$2"); LFSB=$(realpath "$3"); LISTA=$(realpath "$4"); OUT=$(realpath -m "$5"); ANTES=${6:+$(realpath "$6")}
W=$(mktemp -d); mkdir -p "$W/home" "$W/track"
cp -r "$JH" "$W/jhalfs"
( cd "$W/jhalfs" && echo yes | HOME="$W/home" WORKING_COPY=y BLFS_BOOK="$BLFS" LFS_WORKING_COPY=y LFS_BOOK="$LFSB" \
    TRACKING_DIR="$W/track" INITSYS=sysv bash install-blfs-tools.sh > "$W/instalar.log" 2>&1 ) || { tail -30 "$W/instalar.log"; exit 1; }
B="$W/home/blfs_root"
python3 "$HERE/marcar-lfs.py" "$B/packages.xml" "$W/track/instpkg.xml" "$B/packdesc.dtd" $ANTES
make -s -C "$B" "$B/Config.in" TRACKING_DIR="$W/track" > /dev/null
python3 "$HERE/gerar-config.py" "$B" "$LISTA" 1
( cd "$B" && echo yes | ./gen_pkg_book.sh "$W/track/instpkg.xml" "$B" "$B/blfs-xml/tmp/blfs-full.xml" "$B/lfs-xml/tmp/lfs-full.xml" > "$W/gerar.log" 2>&1 ) \
  || { tail -30 "$W/gerar.log"; exit 1; }
rm -rf "$OUT"; cp -r "$B/scripts" "$OUT"
echo "$(ls "$OUT" | wc -l) scripts em $OUT"
