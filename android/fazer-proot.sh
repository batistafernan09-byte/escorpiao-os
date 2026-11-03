#!/bin/bash
# Compila o proot (o programa que deixa o Linux rodar por cima do Android, sem root) para ARM64, sem depender
# de nenhuma biblioteca do celular (estático, com musl). É a versão do Termux, que conhece as manias do Android.
# O "loader" sai separado: o Jarvis leva os dois dentro do APK (libproot.so e libproot-loader.so), porque o
# Android 10+ só deixa rodar programas que vieram no próprio APK.
# Uso (num computador ARM64 com docker): fazer-proot.sh <pasta-de-saída>
set -euo pipefail
OUT=$(realpath -m "$1"); mkdir -p "$OUT"
docker run --rm -v "$OUT:/out" alpine:3.20 sh -euxc '
  apk add --no-cache build-base git linux-headers python3 wget
  # talloc estático (a única biblioteca que o proot usa)
  wget -q https://www.samba.org/ftp/talloc/talloc-2.4.2.tar.gz && tar -xf talloc-2.4.2.tar.gz && cd talloc-2.4.2
  ./configure --prefix=/usr --disable-python --disable-rpath --without-gettext >/dev/null
  make -j"$(nproc)" >/dev/null
  ar rcs /usr/lib/libtalloc.a $(find bin/default -maxdepth 1 -name "talloc.c.*.o") $(find bin/default/lib/replace -name "*.o" 2>/dev/null) && cp talloc.h /usr/include/
  cd / && git clone --depth 1 https://github.com/termux/proot && cd proot/src
  make -j"$(nproc)" PROOT_UNBUNDLE_LOADER=/naousado LDFLAGS="-static -ltalloc -Wl,-z,noexecstack" proot loader/loader
  strip proot loader/loader
  cp proot /out/libproot.so && cp loader/loader /out/libproot-loader.so
  cp ../COPYING /out/PROOT-LICENCA.txt
'
file "$OUT"/libproot*.so
# teste de verdade: o proot liga um Linux pequeno (o do Alpine) e roda um programa lá dentro
R=$(mktemp -d); docker export "$(docker create alpine:3.20)" | tar -x -C "$R"
mkdir -p "$R/tmp"; T=$(mktemp -d)
saida=$(PROOT_LOADER="$OUT/libproot-loader.so" PROOT_TMP_DIR="$T" "$OUT/libproot.so" --kill-on-exit --link2symlink -0 -r "$R" \
        -b /dev -b /proc -b /sys -w /root /usr/bin/env -i PATH=/bin:/usr/bin /bin/sh -c 'echo "proot-ok $(id -u) $(uname -m)"')
echo "$saida"
case "$saida" in "proot-ok 0 aarch64") echo "o proot funciona";; *) echo "o proot NÃO funcionou"; exit 1;; esac
