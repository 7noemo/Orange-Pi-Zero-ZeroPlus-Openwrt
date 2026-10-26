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

# Fix LEDE's out-of-tree sun55i IOMMU driver for kernel >= 6.18.58:
# upstream changed iommu_domain_ops.attach_dev() to take a third
# "old domain" argument, breaking the build of arm64 sunxi targets
# (cortexa53, i.e. Orange Pi Zero Plus).
IOMMU_C=target/linux/sunxi/files/drivers/iommu/sun55i-iommu.c
if [ -f "$IOMMU_C" ]; then
	perl -0pi -e 's/(static int sun55i_iommu_attach_dev\(struct iommu_domain \*domain,\s*\n\s*struct device \*dev)\)/$1, struct iommu_domain *old)/' "$IOMMU_C"
	if /usr/bin/grep -q 'struct device \*dev, struct iommu_domain \*old)' "$IOMMU_C"; then
		echo "sun55i-iommu: attach_dev signature updated for kernel 6.18.58"
	fi
fi
