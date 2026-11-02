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

# --- Kernel 6.18 sunxi compatibility -------------------------------------
# LEDE upstream now maintains BOTH patches itself (refreshed 2026-11-02 for
# kernel 6.18.60):
#   generic/hack-6.18/953-net-patch-linux-kernel-to-support-shortcut-fe.patch
#   sunxi/patches-6.18/950-iommu-sun55i-update-attach-dev-for-linux-6.18.patch
# Our local overrides now DUPLICATE the upstream fixes: the perl edit below
# changed the attach_dev signature before the 950 patch could apply, so
# "Hunk #1 FAILED at 711" killed the whole build. Only fall back to the local
# hacks when upstream stops shipping the corresponding patch.

# Shortcut-FE skbuff.h hunk (fallback only)
if [ ! -f target/linux/generic/hack-6.18/953-net-patch-linux-kernel-to-support-shortcut-fe.patch ]; then
	cp "$GITHUB_WORKSPACE/patches/953-net-patch-linux-kernel-to-support-shortcut-fe.patch" \
		target/linux/generic/hack-6.18/953-net-patch-linux-kernel-to-support-shortcut-fe.patch
	echo "953-shortcut-fe: upstream patch missing, installed local fallback"
fi

# sun55i IOMMU attach_dev() third argument (fallback only)
IOMMU_C=target/linux/sunxi/files/drivers/iommu/sun55i-iommu.c
if [ -f "$IOMMU_C" ] && ! ls target/linux/sunxi/patches-6.18/950-iommu-sun55i-*.patch >/dev/null 2>&1; then
	perl -0pi -e 's/(static int sun55i_iommu_attach_dev\(struct iommu_domain \*domain,\s*\n\s*struct device \*dev)\)/$1, struct iommu_domain *old)/' "$IOMMU_C"
	if /usr/bin/grep -q 'struct device \*dev, struct iommu_domain \*old)' "$IOMMU_C"; then
		echo "sun55i-iommu: upstream 950 patch missing, applied local signature fix"
	fi
fi
