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
git clone --depth 1 https://github.com/messense/aliyundrive-fuse.git package/aliyundrive-fuse
git clone --depth 1 https://github.com/destan19/OpenAppFilter.git package/OpenAppFilter
git clone --depth 1 https://github.com/linkease/docker_ddnsto.git package/docker_ddnsto

# Copy self-packaged RTL8189FS SDIO WiFi driver kmod (for Orange Pi Zero Plus)
cp -a "$GITHUB_WORKSPACE/rtl8189fs" package/rtl8189fs

# Copy self-packaged XR819 SDIO WiFi driver kmod (for Orange Pi Zero)
# https://github.com/7noemo/xradio-openwrt
git clone --depth 1 https://github.com/7noemo/xradio-openwrt.git xr819-openwrt
cp -a xr819-openwrt/xradio package/kernel/xr819
rm -rf xr819-openwrt
