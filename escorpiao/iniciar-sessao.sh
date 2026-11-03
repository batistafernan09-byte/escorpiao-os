#!/bin/bash
# Liga a área de trabalho do Escorpião OS e o servidor gráfico (Xvnc, do TigerVNC).
# O Jarvis chama isto e depois mostra a tela pela porta 127.0.0.1:5901 (só dentro do celular, com senha).
# Uso: iniciar-sessao.sh <largura> <altura> <dpi>
set -u
W=${1:-1280}; H=${2:-720}; DPI=${3:-120}
export HOME=${HOME:-/root} USER=${USER:-root} LANG=pt_BR.UTF-8 LC_ALL=pt_BR.UTF-8
export PATH=/usr/bin:/usr/sbin:/bin:/sbin XDG_RUNTIME_DIR=/tmp/xdg-$USER XDG_CONFIG_DIRS=/etc/xdg
mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"
[ -f "$HOME/.escorpiao-visual" ] || { bash /usr/share/escorpiao/visual.sh && touch "$HOME/.escorpiao-visual"; }
# limpa uma sessão anterior que ficou para trás
pkill -f "Xvnc :1" 2>/dev/null; rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix
Xvnc :1 -geometry "${W}x${H}" -depth 24 -dpi "$DPI" -localhost -rfbport 5901 \
     -SecurityTypes VncAuth -PasswordFile "$HOME/.vnc/passwd" -AlwaysShared -AcceptSetDesktopSize \
     > /tmp/xvnc.log 2>&1 &
for i in $(seq 1 50); do [ -e /tmp/.X11-unix/X1 ] && break; sleep 0.2; done
export DISPLAY=:1
echo "PRONTO"
exec dbus-launch --exit-with-session startxfce4 > /tmp/xfce.log 2>&1
