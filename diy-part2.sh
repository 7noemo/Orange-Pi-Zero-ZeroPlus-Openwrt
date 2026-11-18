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

# --- LuCI feed integrity guard (fail fast) --------------------------------
# coolsnowwolf/luci d341231 (2026-11-17, "Remove packages provided by QWRT
# core") deleted modules/luci-mod-network, but luci-mod-admin-full still
# declares +luci-mod-network. LEDE ships no core replacement, so feeds
# install only prints a warning and the build dies ~2.5 hours later at
# package/install: "cannot find dependency luci-mod-network for
# luci-mod-admin-full" -> "Cannot install package luci".
# Upstream restored it in 14761f2 (2026-11-18). Detect this exact breakage
# before defconfig so a temporarily broken upstream feed cannot waste a full
# compile. The dependency check makes the guard auto-retire if upstream ever
# legitimately removes the module.
LUCI_FEED=feeds/luci
if grep -q 'luci-mod-network' "$LUCI_FEED/modules/luci-mod-admin-full/Makefile" 2>/dev/null && \
   [ ! -f "$LUCI_FEED/modules/luci-mod-network/Makefile" ]; then
	echo "::error::LuCI feed is missing luci-mod-network but luci-mod-admin-full depends on it."
	echo "::error::Upstream coolsnowwolf/luci regression (d341231, restored in 14761f2)."
	echo "::error::Wait for the feed to recover, or pin the luci feed to a known-good commit."
	exit 1
fi
echo "luci feed integrity: luci-mod-network present (or no longer required)"

# --- profiles.json generation fix (LEDE verbose.mk b77bd85b1) ------------
# LEDE 2026-11-18 commit b77bd85b1 ("build: preserve diagnostics when
# verbose descriptors are closed") added `$(info $(_MESSAGE))` to
# include/verbose.mk, which leaks a parse-time status line onto stdout.
# scripts/json_overview_image_info.py calls
#   make ... val.DEFAULT_PACKAGES val.ARCH_PACKAGES
# and unpacks stdout into exactly two values, so the extra line causes
# "ValueError: too many values to unpack (expected 2)" at the very end of
# the build (images are already built; only profiles.json fails).
# Keep the LAST two non-empty lines, which are always the variable values.
# Guarded on the original statement so it auto-retires if upstream fixes it.
JSON_INFO=scripts/json_overview_image_info.py
if [ -f "$JSON_INFO" ] && \
   grep -q 'default_packages, output\["arch_packages"\] = run(' "$JSON_INFO"; then
	python3 - "$JSON_INFO" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
old1 = '    default_packages, output["arch_packages"] = run('
new1 = '    _val_lines = run('
assert old1 in s, "pattern 1 missing"
s = s.replace(old1, new1, 1)
old2 = '    ).stdout.splitlines()\n\n    output["default_packages"] = sorted(default_packages.split())'
new2 = '''    ).stdout.splitlines()

    # LEDE include/verbose.mk (b77bd85b1) emits a parse-time status line on
    # stdout, so the two val.* values are the LAST two non-empty lines.
    _val_lines = [line for line in _val_lines if line.strip()]
    default_packages, output["arch_packages"] = _val_lines[-2], _val_lines[-1]

    output["default_packages"] = sorted(default_packages.split())'''
assert old2 in s, "pattern 2 missing"
s = s.replace(old2, new2, 1)
open(p, "w").write(s)
PY
	echo "json_overview_image_info.py: tolerate extra stdout diagnostics (profiles.json)"
else
	echo "json_overview_image_info.py: pattern changed (upstream fixed?) - skipping"
fi

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

# --- gettext-full host build fix (LEDE issue #14291) ----------------------
# LEDE master pairs gettext-full 0.22.5 (2023) with tools/gnulib 2026.07;
# gettext's bundled autogen breaks against the new gnulib-tool and the host
# build dies at Host/Prepare ("Replacing file ..." then Error 1).
# OpenWrt solved this by moving to gettext 0.24.2 + a separate gnulib-l10n
# host package. Pull both from OpenWrt master. Guarded on the stale version:
# auto-skips once LEDE catches up.
if grep -q 'PKG_VERSION:=0.22.5' package/libs/gettext-full/Makefile 2>/dev/null; then
	rm -rf /tmp/owrt-pkgs
	git clone --depth 1 --filter=blob:none --sparse \
		https://github.com/openwrt/openwrt /tmp/owrt-pkgs >/dev/null 2>&1
	git -C /tmp/owrt-pkgs sparse-checkout set \
		package/libs/gettext-full package/libs/gnulib-l10n >/dev/null 2>&1
	if [ -f /tmp/owrt-pkgs/package/libs/gettext-full/Makefile ] && \
	   grep -q 'PKG_VERSION:=0.24.2' /tmp/owrt-pkgs/package/libs/gettext-full/Makefile; then
		rm -rf package/libs/gettext-full
		cp -r /tmp/owrt-pkgs/package/libs/gettext-full package/libs/
		cp -r /tmp/owrt-pkgs/package/libs/gnulib-l10n package/libs/
		echo "gettext-full: replaced with OpenWrt 0.24.2 + gnulib-l10n (fixes host build, LEDE#14291)"
	else
		echo "::warning::failed to fetch OpenWrt gettext-full/gnulib-l10n - keeping LEDE version (host build may fail)"
	fi
	rm -rf /tmp/owrt-pkgs
else
	echo "gettext-full: no longer 0.22.5 (LEDE caught up?) - skipping"
fi

# --- erofs-utils source repoint (kernel.org unreachable from runners) -----
# LEDE fetches the 1.8.10 cgit snapshot tarball from git.kernel.org, which
# has been timing out from GitHub Actions runners (port 443), and OpenWrt
# mirrors never carry LEDE's version => tools download fails.
# The official GitHub mirror tag archive is byte-identical (same sha256:
# 05eb4ede...), so only URL + filename need to change. Guarded: skips once
# LEDE changes version/URL (e.g. adopts git proto like OpenWrt master).
if [ -f tools/erofs-utils/Makefile ] && \
   grep -q 'PKG_VERSION:=1.8.10' tools/erofs-utils/Makefile && \
   grep -q 'git.kernel.org' tools/erofs-utils/Makefile; then
	sed -i \
		-e 's|PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz|PKG_SOURCE:=v$(PKG_VERSION).tar.gz|' \
		-e 's|PKG_SOURCE_URL=https://git.kernel.org/pub/scm/linux/kernel/git/xiang/erofs-utils.git/snapshot/|PKG_SOURCE_URL=https://github.com/erofs/erofs-utils/archive/refs/tags/|' \
		tools/erofs-utils/Makefile
	if grep -q 'github.com/erofs/erofs-utils' tools/erofs-utils/Makefile; then
		echo "erofs-utils: repointed source to GitHub mirror tag archive (same tarball hash)"
	else
		echo "::error::erofs-utils repoint failed - pattern mismatch, update diy-part2.sh"
		exit 1
	fi
else
	echo "erofs-utils: not kernel.org/1.8.10 anymore (LEDE caught up?) - skipping"
fi
