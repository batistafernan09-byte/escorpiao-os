#!/bin/bash
# A configuração do kernel do Escorpião OS:
#   1. o padrão da arquitetura ARM64 (defconfig: liga as placas e máquinas virtuais mais comuns);
#   2. o que o LIVRO exige (chapter10/kernel/sysv.toml do LFS 12.4 ARM64: '*' = ligado, ' ' = desligado, 'M' = módulo);
#   3. o que o .iso "ao vivo" precisa (ler o CD, o sistema comprimido squashfs e a camada de escrita overlay) e as
#      peças de máquina virtual (virtio).
# Uso: kernel-config.sh <pasta-do-código-do-linux> <sysv.toml-do-livro> <arquivo-de-saída>
set -euo pipefail
SRC=$1; TOML=$2; OUT=$3
cd "$SRC"
make ARCH=arm64 defconfig >/dev/null
# 2. as exigências do livro
while IFS='=' read -r k v; do
  k=$(echo "$k" | tr -d ' '); v=$(echo "$v" | tr -d "'\" ")
  [[ -z "$k" || "$k" == \#* || "$k" == revision ]] && continue
  case "$v" in
    "*"|"*M") scripts/config --enable "$k" ;;
    "M")      scripts/config --module "$k" ;;
    "")       scripts/config --disable "$k" ;;
    *)        scripts/config --set-str "$k" "$v" ;;      # ex.: DRM_PANIC_SCREEN='kmsg'
  esac
done < "$TOML"
# 3. o .iso ao vivo e as máquinas virtuais
for k in BLK_DEV_INITRD BLK_DEV_LOOP SQUASHFS SQUASHFS_XZ SQUASHFS_ZSTD OVERLAY_FS ISO9660_FS JOLIET ZISOFS \
         VIRTIO VIRTIO_PCI VIRTIO_MMIO VIRTIO_BLK VIRTIO_NET VIRTIO_CONSOLE VIRTIO_INPUT HW_RANDOM_VIRTIO \
         SCSI SCSI_VIRTIO BLK_DEV_SR DRM_VIRTIO_GPU FB_EFI EFI_STUB EXT4_FS VFAT_FS MSDOS_FS NLS_CODEPAGE_437 \
         NLS_ISO8859_1 NLS_UTF8 TMPFS TMPFS_POSIX_ACL FUSE_FS INPUT_EVDEV USB_HID HID_GENERIC; do
  scripts/config --enable "$k"
done
make ARCH=arm64 olddefconfig >/dev/null
cp .config "$OUT"
# confere: tudo o que o livro manda ligar ficou ligado?
falhou=0
while IFS='=' read -r k v; do
  k=$(echo "$k" | tr -d ' '); v=$(echo "$v" | tr -d "'\" ")
  [[ -z "$k" || "$k" == \#* || "$k" == revision ]] && continue
  if [[ "$v" == "*" || "$v" == "*M" ]] && ! grep -qE "^CONFIG_${k}=(y|m)$" "$OUT"; then echo "AVISO: CONFIG_$k não ficou ligado"; falhou=1; fi
done < "$TOML"
echo "kernel-config pronto ($(grep -c '=y' "$OUT") opções ligadas)"
exit $falhou
