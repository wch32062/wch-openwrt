#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# 由工作流在 openwrt/ 目录下执行。注意：GitHub Actions 用 `bash -e` 运行，
# 所以本脚本里任何一条命令失败都会让整个构建步骤失败，严禁出现裸的中文注释行。
#
set -eu

FEEDS_CONF=feeds.conf.default

# 1) 取消 lede 自带的 helloworld 源注释
sed -i '/^#.*helloworld/s/^#//' "$FEEDS_CONF"

# 2) 追加第三方源
#    必须显式写分支：Lienol/openwrt-package 默认分支是 main，
#    不写分支时 feeds 会去找 master 并失败。
add_feed() {
	local name="$1"
	local url="$2"

	if grep -q "^src-git[[:space:]]\+${name}[[:space:]]" "$FEEDS_CONF"; then
		echo "feed ${name} 已存在，跳过"
	else
		echo "src-git ${name} ${url}" >> "$FEEDS_CONF"
		echo "feed ${name} 已添加"
	fi
}

add_feed lienol 'https://github.com/Lienol/openwrt-package;main'
add_feed haiibo 'https://github.com/haiibo/openwrt-packages;master'
