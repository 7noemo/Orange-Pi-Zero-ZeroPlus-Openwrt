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
#echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
#echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default
git clone https://github.com/messense/aliyundrive-fuse.git package/lean/aliyundrive-fuse
git clone https://github.com/destan19/OpenAppFilter.git package/lean/OpenAppFilter
git clone https://github.com/linkease/docker_ddnsto.git package/lean/ddnsto
git clone https://github.com/HustLion/mentohust.git package/
git clone https://github.com/KyleRicardo/MentoHUST-OpenWrt-ipk.git package/mentohust package/
