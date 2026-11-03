#!/bin/bash
# Roda os scripts do BLFS, um por um, DENTRO do sistema novo (chroot), na ordem que a ferramenta calculou.
# Cada pacote pronto ganha uma marca; se o tempo da etapa do GitHub acabar, a próxima continua de onde parou.
# Uso: sudo rodar.sh <raiz-do-sistema (ex.: /mnt/lfs)> <pasta-de-scripts-dentro-da-raiz (ex.: /blfs/desktop)> <minutos-máximos>
# Saída: 0 = tudo pronto; 3 = o tempo acabou (falta continuar); 1 = um pacote falhou (o registro fica em /blfs/logs)
set -uo pipefail
ROOT=$1; DIR=$2; MAX=$3
HERE=$(cd "$(dirname "$0")" && pwd)
FIM=$(( $(date +%s) + MAX * 60 ))
mkdir -p "$ROOT/blfs/feitos" "$ROOT/blfs/logs"
for s in "$ROOT$DIR"/*; do
  n=$(basename "$s"); pkg=${n#*-z-}
  [ -e "$ROOT/blfs/feitos/$pkg" ] && continue
  if [ "$(date +%s)" -ge "$FIM" ]; then echo "TEMPO: parei antes de $pkg (continua na próxima etapa)"; exit 3; fi
  [ -x "$HERE/ajustes/$pkg.sh" ] && "$HERE/ajustes/$pkg.sh" "$s"          # conserto de um script, se precisar
  echo "==> $(date +%H:%M) $pkg"
  if chroot "$ROOT" /usr/bin/env -i HOME=/root TERM=xterm-256color LANG=pt_BR.UTF-8 \
       PATH=/usr/bin:/usr/sbin SSL_CERT_FILE=/etc/pki/tls/certs/ca-bundle.crt \
       /bin/bash -e "$DIR/$n" > "$ROOT/blfs/logs/$n.log" 2>&1; then
    touch "$ROOT/blfs/feitos/$pkg"
  else
    echo "FALHOU: $pkg — últimas linhas do registro:"; tail -40 "$ROOT/blfs/logs/$n.log"; exit 1
  fi
done
echo "PRONTO: todos os pacotes de $DIR"
exit 0
