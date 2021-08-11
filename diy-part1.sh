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

Add a feed source
echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall package/passwall' >>feeds.conf.defaul
echo 'src-git litte https://github.com/kenzok8/litte package/litte' >>feeds.conf.defaul
echo 'src-git passwall https://github.com/kenzok8/small' >>feeds.conf.defaul
