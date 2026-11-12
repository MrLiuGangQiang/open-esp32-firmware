#!/usr/bin/env bash
# ============================================================================
# 固件烧录辅助脚本（容器内运行）
# 用法:
#   flash-firmware info              查看固件清单与手动烧录命令
#   flash-firmware flash <串口设备>   自动烧录固件
# 宿主机示例:
#   docker run --rm -it --device=/dev/ttyACM0 <镜像> flash /dev/ttyACM0
# ============================================================================
set -euo pipefail

FIRMWARE_DIR="${FIRMWARE_DIR:-/opt/firmware}"

usage() {
  cat <<EOF
open-esp32-firmware 烧录工具

用法:
  flash-firmware info               查看固件清单与手动烧录命令
  flash-firmware flash <串口设备>    自动烧录固件（默认 921600 波特率）

宿主机示例:
  docker run --rm -it --device=/dev/ttyACM0 \\
    registry.cn-hangzhou.aliyuncs.com/liugangqiang/open-esp32-firmware \\
    flash /dev/ttyACM0
EOF
}

do_flash() {
  local port="$1"
  cd "${FIRMWARE_DIR}"
  echo "==> 目标设备: ${port}"
  echo "==> 固件目录: ${FIRMWARE_DIR}"
  if [[ -f merged-binary.bin ]]; then
    echo "==> 使用整包固件 merged-binary.bin（写入 0x0）"
    python -m esptool --chip esp32s3 --port "${port}" --baud 921600 \
      write_flash 0x0 merged-binary.bin
  elif [[ -f flash_args ]]; then
    echo "==> 使用分区镜像与 flash_args 烧录"
    python -m esptool --chip esp32s3 --port "${port}" --baud 921600 \
      write_flash @flash_args
  else
    echo "!! 未找到固件文件（merged-binary.bin / flash_args）" >&2
    exit 1
  fi
  echo "==> 烧录完成，设备即将重启"
}

case "${1:-info}" in
  info)
    usage
    echo
    echo "==> 固件清单:"
    ls -lah "${FIRMWARE_DIR}"
    ;;
  flash)
    [[ -n "${2:-}" ]] || { usage; exit 1; }
    do_flash "$2"
    ;;
  -h|--help)
    usage
    ;;
  *)
    echo "!! 未知命令: $1" >&2
    usage
    exit 1
    ;;
esac