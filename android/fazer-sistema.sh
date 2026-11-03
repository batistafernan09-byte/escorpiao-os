#!/bin/bash
# O pacote do Escorpião OS para o celular: o sistema inteiro num .tar.gz, SEM o kernel (no celular quem faz o papel
# do kernel é o do próprio Android; o sistema roda por cima dele com o proot) e sem o que só serve para compilar.
# Formato pax (nomes longos) com números de dono — o Jarvis desempacota sozinho.
# Uso: sudo fazer-sistema.sh <raiz-do-sistema> <saída.tar.gz>
set -euo pipefail
ROOT=$1; OUT=$(realpath -m "$2")
tar --numeric-owner --format=pax -C "$ROOT" \
    --exclude=./sources --exclude=./tools --exclude=./jhalfs --exclude=./blfs --exclude=./boot \
    --exclude=./lost+found --exclude='./proc/*' --exclude='./sys/*' --exclude='./dev/*' --exclude='./run/*' \
    --exclude='./tmp/*' --exclude=./usr/lib/modules --exclude='./var/cache/*' --exclude='./var/log/*' \
    --exclude=./usr/share/doc --exclude=./usr/share/info --exclude=./usr/share/gtk-doc \
    -cpf - . | gzip -6 > "$OUT"
echo "pronto: $OUT ($(du -h "$OUT" | cut -f1))"
