#!/bin/sh
# 归一化 uboot-rockchip/Makefile 里的 generic-rk3528 / generic-rk3568 变体。
#
# 背景：BSP 的 002-uboot 补丁是照着某棵树写的，上游一变，patch -F3 就会把
#   · define U-Boot/generic-rk35xx 插进别的 define 里（导致变量自引用）
#   · 列表项 `generic-rk3528 \` 插到两个 define 之间（不进 UBOOT_TARGETS）
# 两种都会让 u-boot 包不被索引，最后表现是打包时缺
# generic-rk3528-u-boot-rockchip.bin。
#
# 这里不依赖补丁插在哪，直接重建：
#   1. 删掉所有 generic-rk35xx 的定义块与散落列表行
#   2. 在 UBOOT_TARGETS 列表里补两个名字
#   3. 在 UBOOT_TARGETS 之前补两个干净的定义
set -eu

MK="${1:-package/boot/uboot-rockchip/Makefile}"
[ -f "$MK" ] || { echo "找不到 $MK" >&2; exit 1; }

python3 - "$MK" <<'PY'
import re, sys

path = sys.argv[1]
s = open(path, encoding="utf-8").read()

# 1) 删除可能插错位置的定义块（含被嵌进别的 define 里的情况）
s = re.sub(r'\ndefine U-Boot/generic-rk3528\b.*?\nendef\n', '\n', s, flags=re.S)
s = re.sub(r'\ndefine U-Boot/generic-rk3568\b.*?\nendef\n', '\n', s, flags=re.S)

# 2) 删除散落的列表项
s = re.sub(r'^  generic-rk3528 \\\n', '', s, flags=re.M)
s = re.sub(r'^  generic-rk3568 \\\n', '', s, flags=re.M)

# 3) 在 UBOOT_TARGETS 列表开头补两项
anchor = 'UBOOT_TARGETS := \\\n'
if anchor not in s:
    sys.exit('找不到 UBOOT_TARGETS 定义，上游结构变了')
s = s.replace(anchor, anchor + '  generic-rk3528 \\\n  generic-rk3568 \\\n', 1)

# 4) 在 UBOOT_TARGETS 之前补干净的定义
defs = '''define U-Boot/generic-rk3528
  $(U-Boot/rk3528/Default)
  NAME:=Generic RK3528 board
  BUILD_DEVICES:= \\
    hinlink_opc-h29k
endef

define U-Boot/generic-rk3568
  $(U-Boot/rk3568/Default)
  NAME:=Generic RK3568 board
  BUILD_DEVICES:= \\
    hinlink_opc-h69k
endef

'''
s = s.replace(anchor, defs + anchor, 1)

open(path, "w", encoding="utf-8").write(s)
print("uboot 变体已归一化")
PY

grep -n 'generic-rk3528' "$MK" | head -5
