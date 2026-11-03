#!/bin/bash
# Roda DENTRO do sistema novo (chroot), no fim: o nome Escorpião OS, o papel de parede, o visual e o início da sessão.
# Os arquivos chegam em /tmp/escorpiao (copiados pelo construir.yml).
set -euo pipefail
D=/tmp/escorpiao
install -d /usr/share/escorpiao
install -m644 $D/papel-de-parede.png $D/icone.png /usr/share/escorpiao/
install -m755 $D/visual.sh $D/iniciar-sessao.sh /usr/share/escorpiao/
install -m644 $D/os-release /etc/os-release
cat > /etc/lsb-release <<'EOT'
DISTRIB_ID="Escorpiao OS"
DISTRIB_RELEASE="1.0"
DISTRIB_CODENAME="12.4"
DISTRIB_DESCRIPTION="Escorpião OS 1.0 (Linux From Scratch 12.4 ARM64)"
EOT
echo "Escorpião OS 1.0" > /etc/escorpiao-release
# fontes DejaVu (as letras da tela; o livro BLFS lista as fontes TTF mas não tem uma página de instalação)
if ls /sources/dejavu-fonts-ttf-*.tar.bz2 >/dev/null 2>&1; then
  install -d /usr/share/fonts/dejavu
  tar -xf /sources/dejavu-fonts-ttf-*.tar.bz2 -C /tmp
  install -m644 /tmp/dejavu-fonts-ttf-*/ttf/*.ttf /usr/share/fonts/dejavu/
  rm -rf /tmp/dejavu-fonts-ttf-*
  fc-cache -f >/dev/null 2>&1 || true
fi
# o .iso: usuário root, senha "escorpiao" (está no LEIA-ME e nas notas); "startx" abre a área de trabalho
echo 'root:escorpiao' | chpasswd
printf 'exec startxfce4\n' > /root/.xinitrc
# a sessão gráfica sempre em português
cat > /etc/profile.d/escorpiao.sh <<'EOT'
export LANG=pt_BR.UTF-8
EOT
echo "marca do Escorpião OS instalada"
