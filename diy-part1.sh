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

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
#sed -i '$a src-git lienol https://github.com/Lienol/openwrt-package' feeds.conf.default
src-git kenzok8 https://github.com/kenzok8/openwrt-packages.git
src-git haiibo https://github.com/haiibo/openwrt-packages.git
src-git helloworld https://github.com/fw876/helloworld.git
src-git passwall https://github.com/xiaorouji/openwrt-passwall.git
src-git maxminddb https://github.com/jerrykuku/lua-maxminddb.git
src-git vssr https://github.com/jerrykuku/luci-app-vssr.git  
