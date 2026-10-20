#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# 由工作流在 openwrt/ 目录下执行。
#
set -eu

CONFIG_GENERATE=package/base-files/files/bin/config_generate
DEFAULT_LAN_IP=192.168.100.1

# 修改默认 LAN IP（README 里写的也是这个地址）
if [ -f "$CONFIG_GENERATE" ]; then
	sed -i "s/192\.168\.1\.1/${DEFAULT_LAN_IP}/g" "$CONFIG_GENERATE"
	echo "默认 LAN IP 已改为 ${DEFAULT_LAN_IP}"
else
	echo "警告：未找到 $CONFIG_GENERATE，跳过 IP 修改" >&2
fi
