#!/bin/bash
# Faz o .iso do Escorpião OS (ARM64, inicia por UEFI: máquinas virtuais, Macs com UTM, placas e servidores ARM).
# Dentro: o kernel compilado pelo capítulo 10 do livro, um initramfs pequeno e o sistema inteiro comprimido.
# Roda no computador do GitHub (precisa de: squashfs-tools xorriso mtools grub-efi-arm64-bin).
# Uso: sudo fazer-iso.sh <raiz-do-sistema> <saída.iso>
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$1; OUT=$(realpath -m "$2")
W=$(mktemp -d); ISO=$W/iso; mkdir -p "$ISO/boot/grub" "$ISO/LiveOS"
KER=$(ls "$ROOT"/boot/vmlinuz-* | head -1)
cp "$KER" "$ISO/boot/vmlinuz"
# --- o initramfs: o nosso init + os programas do PRÓPRIO sistema que ele usa (e as bibliotecas deles)
I=$W/initramfs; mkdir -p "$I"/{bin,lib,proc,sys,dev,run,novo}
for p in bash mount umount switch_root mkdir sleep blkid seq cat ls; do
  f=$(chroot "$ROOT" /usr/bin/bash -c "command -v $p"); cp -L "$ROOT$f" "$I/bin/"
  chroot "$ROOT" /usr/bin/ldd "$f" 2>/dev/null | grep -o '/[^ ]*' | while read -r lib; do cp -Ln "$ROOT$lib" "$I/lib/" 2>/dev/null || true; done
done
ln -s lib "$I/lib64" 2>/dev/null || true; ln -sf ../lib/ld-linux-aarch64.so.1 "$I/lib/ld-linux-aarch64.so.1" 2>/dev/null || true
install -m755 "$HERE/init" "$I/init"
( cd "$I" && find . | cpio -o -H newc --quiet | gzip -9 ) > "$ISO/boot/initrd.img"
# --- o sistema comprimido (o "/" do .iso), com o fstab de sistema ao vivo
cp "$ROOT/etc/fstab" "$W/fstab.original"
cat > "$ROOT/etc/fstab" <<'EOT'
# Escorpião OS ao vivo: o "/" é a camada overlay montada pelo initramfs (nada a montar nem conferir aqui)
proc     /proc          proc     nosuid,noexec,nodev 0 0
sysfs    /sys           sysfs    nosuid,noexec,nodev 0 0
devpts   /dev/pts       devpts   gid=5,mode=620      0 0
tmpfs    /run           tmpfs    defaults            0 0
devtmpfs /dev           devtmpfs mode=0755,nosuid    0 0
tmpfs    /dev/shm       tmpfs    nosuid,nodev        0 0
cgroup2  /sys/fs/cgroup cgroup2  nosuid,noexec,nodev 0 0
EOT
mksquashfs "$ROOT" "$ISO/LiveOS/sistema.sfs" -comp zstd -Xcompression-level 19 -noappend -quiet \
  -e sources tools jhalfs blfs proc sys dev run tmp lost+found
cp "$W/fstab.original" "$ROOT/etc/fstab"
# --- o menu de início (GRUB para UEFI ARM64)
cat > "$ISO/boot/grub/grub.cfg" <<'EOT'
set timeout=5
set default=0
menuentry "Escorpião OS (ao vivo)" {
    linux /boot/vmlinuz console=tty0 console=ttyAMA0 quiet
    initrd /boot/initrd.img
}
menuentry "Escorpião OS (ao vivo, mostrando as mensagens)" {
    linux /boot/vmlinuz console=tty0 console=ttyAMA0
    initrd /boot/initrd.img
}
EOT
grub-mkrescue -d /usr/lib/grub/arm64-efi -o "$OUT" "$ISO" -- -volid ESCORPIAO > "$W/grub.log" 2>&1 || { cat "$W/grub.log"; exit 1; }
rm -rf "$W"
echo "pronto: $OUT ($(du -h "$OUT" | cut -f1))"
