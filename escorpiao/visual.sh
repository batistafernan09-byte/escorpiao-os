#!/bin/bash
# Roda na 1ª vez que a pessoa abre a área de trabalho: deixa o XFCE com um jeito parecido com o do Windows
# (barra embaixo, botão "Iniciar", janelas abertas no meio, bandeja e relógio no canto). Só o jeito de usar:
# continua sendo Linux, e nada aqui usa a marca ou o logotipo da Microsoft.
set -u
H="${HOME:-/root}"
X="$H/.config/xfce4/xfconf/xfce-perchannel-xml"
P="$H/.config/xfce4/panel"
S=/usr/share/escorpiao
mkdir -p "$X" "$P/launcher-3" "$P/launcher-4" "$P/launcher-5" "$H/Desktop" "$H/.local/share/applications"

lanc() {   # lanc <arquivo> <nome> <comando> <ícone>
  cat > "$1" <<EOF
[Desktop Entry]
Type=Application
Name=$2
Exec=$3
Icon=$4
Terminal=false
EOF
}
NAV=firefox; command -v firefox >/dev/null 2>&1 || NAV="xdg-open https://www.google.com"
# os ícones que o próprio XFCE instala (o Firefox traz o dele)
NAVI=org.xfce.webbrowser; command -v firefox >/dev/null 2>&1 && NAVI=firefox
lanc "$P/launcher-3/navegador.desktop" "Navegador" "$NAV" "$NAVI"
lanc "$P/launcher-4/arquivos.desktop"  "Arquivos"  "thunar" "org.xfce.thunar"
lanc "$P/launcher-5/terminal.desktop"  "Terminal"  "xfce4-terminal" "org.xfce.terminalemulator"
# (na área de trabalho só o LEIA-ME: atalhos .desktop ali pedem "confiar no atalho" a cada vez no XFCE 4.18+)
cat > "$H/Desktop/LEIA-ME.txt" <<'EOF'
ESCORPIÃO OS

Uma distribuição Linux feita do zero, seguindo o livro Linux From Scratch 12.4 (edição ARM64)
e o Beyond Linux From Scratch 12.4 (a área de trabalho XFCE e os programas).

- Iniciar (canto de baixo): todos os programas
- Navegador, Arquivos e Terminal: na barra de baixo
- Para programar: gcc, python3, git e vim já vêm instalados (abra o Terminal)
- No celular ele roda por cima do Android (usa o kernel do próprio celular).
  No computador, use o arquivo .iso (ele traz o kernel próprio).

É Linux — não é o Windows e não abre programas .exe.
EOF

cat > "$X/xsettings.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Adwaita"/>
    <property name="IconThemeName" type="string" value="Adwaita"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="FontName" type="string" value="DejaVu Sans 10"/>
    <property name="CursorThemeSize" type="int" value="32"/>
  </property>
  <property name="Xft" type="empty">
    <property name="Antialias" type="int" value="1"/>
  </property>
</channel>
EOF

cat > "$X/xfwm4.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="button_layout" type="string" value="O|HMC"/>
    <property name="title_alignment" type="string" value="left"/>
    <property name="use_compositing" type="bool" value="false"/>
    <property name="workspace_count" type="int" value="1"/>
  </property>
</channel>
EOF

cat > "$X/xfce4-desktop.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitorVNC-0" type="empty">
        <property name="workspace0" type="empty">
          <property name="last-image" type="string" value="$S/papel-de-parede.png"/>
          <property name="image-style" type="int" value="5"/>
        </property>
      </property>
      <property name="monitorscreen" type="empty">
        <property name="workspace0" type="empty">
          <property name="last-image" type="string" value="$S/papel-de-parede.png"/>
          <property name="image-style" type="int" value="5"/>
        </property>
      </property>
    </property>
  </property>
</channel>
EOF

# a barra de baixo: [espaço] [Iniciar] [Navegador] [Arquivos] [Terminal] [janelas abertas] [espaço] [bandeja] [relógio]
cat > "$X/xfce4-panel.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=10;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="size" type="uint" value="44"/>
      <property name="icon-size" type="uint" value="28"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="2"/>
        <value type="int" value="3"/>
        <value type="int" value="4"/>
        <value type="int" value="5"/>
        <value type="int" value="6"/>
        <value type="int" value="7"/>
        <value type="int" value="8"/>
        <value type="int" value="9"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="separator">
      <property name="expand" type="bool" value="true"/>
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-2" type="string" value="applicationsmenu">
      <property name="button-title" type="string" value="Iniciar"/>
      <property name="show-button-title" type="bool" value="true"/>
      <property name="button-icon" type="string" value="/usr/share/escorpiao/icone.png"/>
    </property>
    <property name="plugin-3" type="string" value="launcher">
      <property name="items" type="array"><value type="string" value="navegador.desktop"/></property>
    </property>
    <property name="plugin-4" type="string" value="launcher">
      <property name="items" type="array"><value type="string" value="arquivos.desktop"/></property>
    </property>
    <property name="plugin-5" type="string" value="launcher">
      <property name="items" type="array"><value type="string" value="terminal.desktop"/></property>
    </property>
    <property name="plugin-6" type="string" value="tasklist">
      <property name="show-labels" type="bool" value="false"/>
      <property name="flat-buttons" type="bool" value="true"/>
    </property>
    <property name="plugin-7" type="string" value="separator">
      <property name="expand" type="bool" value="true"/>
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-8" type="string" value="systray"/>
    <property name="plugin-9" type="string" value="clock">
      <property name="digital-format" type="string" value="%H:%M%n%d/%m/%Y"/>
    </property>
  </property>
</channel>
EOF
echo "visual do Escorpião OS aplicado"
