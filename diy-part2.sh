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

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate
#sed -i 's/luci-theme-bootstrap/luci-theme-netgear/g' feeds/luci/collections/luci/Makefile

# Fix upstream Shortcut-FE patch for kernel >= 6.18.58 (stable backport
# added __u8 tc_depth:2 after unreadable:1, breaking the hunk context)
if [ -f target/linux/generic/hack-6.18/953-net-patch-linux-kernel-to-support-shortcut-fe.patch ]; then
	cp "$GITHUB_WORKSPACE/patches/953-net-patch-linux-kernel-to-support-shortcut-fe.patch" \
		target/linux/generic/hack-6.18/953-net-patch-linux-kernel-to-support-shortcut-fe.patch
	echo "953-shortcut-fe patch: replaced with 6.18.58-compatible version"
fi
