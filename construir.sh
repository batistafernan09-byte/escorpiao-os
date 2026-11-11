#!/bin/bash
# O "maestro" do Escorpião OS. Cada etapa do GitHub (no máximo 6 horas) roda este script: ele faz o que falta, na
# ordem, até o tempo acabar — e a próxima etapa continua de onde parou (cada parte pronta deixa uma marca).
#   1. LFS 12.4 ARM64 inteiro (capítulos 4 a 10), com o jhalfs — a ferramenta oficial que lê o livro e roda os comandos
#   2. BLFS 12.4, etapa 1: a área de trabalho (XFCE + o servidor gráfico TigerVNC + programas básicos)
#   3. a marca do Escorpião OS (nome, papel de parede, visual)
#   4. BLFS 12.4, etapa 2: os extras (Gnumeric, Parole, mpv, Firefox)
#   5. as entregas: o .iso, o kernel, o pacote para o celular e os códigos-fonte
# Uso (como usuário comum com sudo): ./construir.sh <minutos-de-trabalho>
# Saída: 0 = tudo pronto (entregas em ./saida); 3 = o tempo acabou (falta continuar); outro = erro
set -euo pipefail
REPO=$(cd "$(dirname "$0")" && pwd)
LFS=/mnt/lfs
LIVROS=$REPO/livros                       # baixados pelo construir.yml (LFS ARM64, BLFS e jhalfs, nas versões fixas)
FIM=$(( $(date +%s) + $1 * 60 ))
resto() { echo $(( (FIM - $(date +%s)) / 60 )); }
E=$LFS/.etapas
sudo mkdir -p "$E"
feito() { [ -e "$E/$1" ]; }
marcar() { sudo touch "$E/$1"; echo "### etapa pronta: $1"; }
tempo_acabou() { echo "### o tempo desta etapa acabou ($1) — a próxima continua daqui"; exit 3; }
kernfs()   { sudo env LFS=$LFS "$LFS/jhalfs/kernfs-scripts/devices.sh" >/dev/null 2>&1 || true; }
desmonta() { sudo env LFS=$LFS "$LFS/jhalfs/kernfs-scripts/teardown.sh" >/dev/null 2>&1 || true; }
trap desmonta EXIT

# ---------------------------------------------------------------- 1. LFS (o livro, capítulos 4 a 10)
if ! feito lfs; then
  # Garante TODAS as fontes (pacotes + patches) em $LFS/sources. O jhalfs às vezes baixa incompleto, e a lista que o
  # urls.xsl gera saiu curta (faltou o ncurses). A lista OFICIAL e completa é a do próprio fork ARM64 (wget-list-sysv);
  # usamos ela como base e ainda juntamos o que o urls.xsl achar. Pacotes "datados" (ex.: o snapshot ncurses-6.5-2025...)
  # somem do diretório 'current' do servidor original quando sai uma versão nova — para esses, caímos num espelho do LFS
  # que guarda o conjunto exato da versão 12.4. Roda em toda etapa; -nc não rebaixa o que já existe.
  sudo mkdir -p "$LFS/sources" && sudo chmod 1777 "$LFS/sources"; mkdir -p "$REPO/trabalho"
  WL="$REPO/trabalho/wget-list"
  echo "### garantindo as fontes do livro (lista oficial do fork ARM64 + urls.xsl)"
  : > "$WL"
  for u in "https://www.linuxfromscratch.org/~xry111/lfs/view/arm64/wget-list-sysv" \
           "https://www.linuxfromscratch.org/~xry111/lfs/wget-list-sysv"; do
    wget -q -O "$WL.oficial" "$u" 2>/dev/null && [ -s "$WL.oficial" ] && { cat "$WL.oficial" >> "$WL"; break; }
  done
  ( cd "$LIVROS/lfs" && bash git-version.sh sysv >/dev/null 2>&1 || true )   # cria conditional.ent (resolve as entidades)
  xsltproc --xinclude --nonet --stringparam revision sysv "$LIVROS/jhalfs/common/urls.xsl" "$LIVROS/lfs/index.xml" 2>/dev/null \
    | grep -oE 'https?://[^ ]+' >> "$WL" || true
  grep -E '^https?://' "$WL" | sort -u -o "$WL"
  if [ -s "$WL" ]; then
    echo "### $(wc -l < "$WL") fontes na lista; baixando as que faltam"
    sudo wget -q -nc -T 45 -t 2 -P "$LFS/sources" -i "$WL" 2>/dev/null || true
    # reserva: busca nos espelhos do LFS 12.4 só o que ainda falta (ex.: snapshot datado que saiu do 'current')
    for m in "https://mirrors.aliyun.com/lfs/lfs-packages/12.4" \
             "https://ftp.osuosl.org/pub/lfs/lfs-packages/12.4" \
             "https://mirror.rackspace.com/lfs/lfs-packages/12.4"; do
      falta=0
      while read -r u; do
        f=$(basename "$u"); [ -s "$LFS/sources/$f" ] && continue
        falta=1; sudo wget -q -nc -T 30 -t 1 -P "$LFS/sources" "$m/$f" 2>/dev/null || true
      done < "$WL"
      [ "$falta" = 0 ] && break
    done
  else
    echo "(aviso: não consegui montar a lista de fontes; seguindo com o que o jhalfs baixar)"
  fi
  echo "### fontes presentes: $(ls -1 "$LFS/sources" 2>/dev/null | grep -ivE '\.patch$|^build$' | wc -l) pacotes + $(ls -1 "$LFS/sources"/*.patch 2>/dev/null | wc -l) patches"
  if [ ! -f "$LFS/jhalfs/Makefile" ]; then
    echo "### preparando o jhalfs com o livro LFS 12.4 ARM64"
    K=$REPO/trabalho/kernel; mkdir -p "$K"
    ent() { sed -n "s/.*ENTITY linux-$1-version *\"\([^\"]*\)\".*/\1/p" "$LIVROS/lfs/packages.ent"; }
    KV=$(ent major).$(ent minor); [ -n "$(ent patch)" ] && [ "$(ent patch)" != 0 ] && KV=$KV.$(ent patch)
    wget -q -O "$K/linux.tar.xz" "https://www.kernel.org/pub/linux/kernel/v6.x/linux-$KV.tar.xz"
    tar -xf "$K/linux.tar.xz" -C "$K"
    bash "$REPO/lfs/kernel-config.sh" "$K/linux-$KV" "$LIVROS/lfs/chapter10/kernel/sysv.toml" "$REPO/trabalho/kernel-config"
    rm -rf "$K"
    sudo mkdir -p "$LFS/sources" && sudo chmod 1777 "$LFS/sources"
    python3 "$REPO/lfs/gerar-config.py" "$LIVROS/jhalfs" "$LIVROS/lfs" "$LFS" "$REPO/trabalho/kernel-config" "$LFS/sources"
    ( cd "$LIVROS/jhalfs" && touch -d '1 hour ago' configuration.old && printf 'yes\nyes\n' | ./jhalfs run )
    [ -f "$LFS/jhalfs/Makefile" ] || { echo "o jhalfs não gerou o Makefile"; exit 1; }
    # o computador do GitHub não tem terminal (TTY); o jhalfs checa o tamanho do terminal (stty size) e falha logo de cara.
    # Essa checagem não serve numa build automática, então tiro ela do alvo principal (ck_UID e ck_mountpoint continuam).
    sudo sed -i 's/ ck_terminal//' "$LFS/jhalfs/Makefile"
  fi
  # a etapa anterior pode ter parado nos capítulos 5-6 (feitos pelo usuário "lfs" do computador do GitHub)
  if [ -e "$LFS/jhalfs/mk_SETUP" ] && [ ! -e "$LFS/jhalfs/mk_SUDO" ] && ! id lfs >/dev/null 2>&1; then
    sudo groupadd lfs; sudo useradd -s /bin/bash -g lfs -m -k /dev/null lfs
    [ -d "$LFS/.casa-lfs" ] && sudo cp -a "$LFS/.casa-lfs/." /home/lfs/ && sudo chown -R lfs:lfs /home/lfs
  fi
  echo "### LFS: rodando o livro (faltam $(resto) min nesta etapa)"
  if timeout "$(resto)m" make -C "$LFS/jhalfs"; then
    marcar lfs
  else
    # mostra o fim do registro do pacote que parou (pode ser erro de verdade, não só falta de tempo)
    echo "### o make do LFS parou — últimos registros do(s) pacote(s) mais recente(s):"
    for lg in $(sudo ls -t "$LFS/jhalfs/logs" 2>/dev/null | head -2); do
      echo "===== $lg ====="; sudo tail -n 40 "$LFS/jhalfs/logs/$lg" 2>/dev/null || true
    done
    [ -d /home/lfs ] && sudo rm -rf "$LFS/.casa-lfs" && sudo cp -a /home/lfs "$LFS/.casa-lfs"
    tempo_acabou "LFS"
  fi
fi

# ---------------------------------------------------------------- 2-4. BLFS (a área de trabalho e os extras)
if ! feito blfs-preparado; then
  echo "### BLFS: calculando o que instalar e em que ordem (ferramenta do jhalfs lendo o livro BLFS 12.4)"
  T=$REPO/trabalho; mkdir -p "$T"
  bash "$REPO/blfs/gerar-scripts.sh" "$LIVROS/jhalfs" "$LIVROS/blfs" "$LIVROS/lfs" "$REPO/blfs/desktop.txt" "$T/desktop"
  bash "$REPO/blfs/gerar-scripts.sh" "$LIVROS/jhalfs" "$LIVROS/blfs" "$LIVROS/lfs" "$REPO/blfs/extras.txt" "$T/extras" "$T/desktop"
  sudo mkdir -p "$LFS/blfs" && sudo cp -r "$T/desktop" "$T/extras" "$LFS/blfs/"
  echo "### BLFS: baixando os fontes (os endereços que estão no livro)"
  sudo python3 "$REPO/blfs/baixar-fontes.py" "$LFS/blfs/desktop" "$LFS/sources"
  sudo python3 "$REPO/blfs/baixar-fontes.py" "$LFS/blfs/extras" "$LFS/sources" || echo "(algum extra não baixou — tenta de novo no script dele)"
  sudo wget -q -O "$LFS/sources/dejavu-fonts-ttf-2.37.tar.bz2" \
    "https://github.com/dejavu-fonts/dejavu-fonts/releases/download/version_2_37/dejavu-fonts-ttf-2.37.tar.bz2"
  marcar blfs-preparado
fi
# a internet dentro do chroot (alguns pacotes, como o Rust, baixam peças durante a compilação)
sudo install -D -m644 /etc/ssl/certs/ca-certificates.crt "$LFS/etc/pki/tls/certs/ca-bundle.crt"
sudo install -D -m644 /etc/ssl/certs/ca-certificates.crt "$LFS/etc/ssl/certs/ca-certificates.crt"
sudo cp -L /etc/resolv.conf "$LFS/etc/resolv.conf"
kernfs

if ! feito desktop; then
  echo "### BLFS etapa 1: a área de trabalho"
  set +e; sudo "$REPO/blfs/rodar.sh" "$LFS" /blfs/desktop "$(resto)"; r=$?; set -e
  case $r in 0) marcar desktop ;; 3) tempo_acabou "área de trabalho" ;; *) echo "### a área de trabalho falhou"; exit 1 ;; esac
fi

if ! feito marca; then
  echo "### a marca do Escorpião OS"
  sudo rm -rf "$LFS/tmp/escorpiao" && sudo cp -r "$REPO/escorpiao" "$LFS/tmp/escorpiao"
  sudo chroot "$LFS" /usr/bin/env -i HOME=/root PATH=/usr/bin:/usr/sbin /bin/bash /tmp/escorpiao/instalar-marca.sh
  marcar marca
fi

if ! feito extras; then
  echo "### BLFS etapa 2: os extras"
  set +e; sudo "$REPO/blfs/rodar.sh" "$LFS" /blfs/extras "$(resto)"; r=$?; set -e
  case $r in
    0) marcar extras ;;
    3) tempo_acabou "extras" ;;
    *) echo "### um extra falhou: o sistema sai sem ele (o registro vai junto nas entregas)"; marcar extras; sudo touch "$E/extras-com-falha" ;;
  esac
fi

# ---------------------------------------------------------------- 5. as entregas
desmonta
S=$REPO/saida; mkdir -p "$S"
echo "### entregas: o pacote para o celular, o .iso, o kernel e os códigos-fonte"
sudo bash "$REPO/android/fazer-sistema.sh" "$LFS" "$S/escorpiao-os-arm64.tar.gz"
sudo bash "$REPO/iso/fazer-iso.sh" "$LFS" "$S/escorpiao-os-arm64.iso"
KER=$(ls "$LFS"/boot/vmlinuz-* | head -1)
sudo cp "$KER" "$S/escorpiao-kernel-$(basename "$KER" | sed 's/^vmlinuz-//')-arm64.efi"
sudo cp "$LFS/boot/config-"* "$S/" 2>/dev/null || true
sudo tar -C "$LFS/sources" -cf - . | split -b 1900M -d - "$S/codigos-fonte.tar.parte"
sudo tar -C "$LFS" -czf "$S/registros.tar.gz" jhalfs/logs blfs/logs 2>/dev/null || true
sudo chown -R "$(id -u):$(id -g)" "$S"
( cd "$S" && sha256sum * > SHA256SUMS )
marcar entregas
ls -la "$S"
exit 0
