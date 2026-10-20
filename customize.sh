#!/bin/bash
#=================================================
# Description: DIY script（历史遗留，GitHub Actions 不调用）
# License: MIT
# Author: eSirPlayground
# Youtube Channel: https://goo.gl/fvkdwm
#
# 注意：CI 实际使用的是 diy-part1.sh / diy-part2.sh。
# 本文件中的默认 IP（192.168.37.2）与 diy-part2.sh（192.168.100.1）不同，
# 仅在你手动、独立地使用它时才会生效；如需统一，请改成 192.168.100.1。
#=================================================
#1. Modify default IP
sed -i 's/192.168.1.1/192.168.37.2/g' openwrt/package/base-files/files/bin/config_generate

#2. Clear the login password
sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.//g' openwrt/package/lean/default-settings/files/zzz-default-settings

#3. Replace with JerryKuKu’s Argon
#rm openwrt/package/lean/luci-theme-argon -rf
