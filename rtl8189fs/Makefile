include $(TOPDIR)/rules.mk

PKG_NAME:=rtl8189fs
PKG_VERSION:=0~f95ad2e2
PKG_RELEASE:=1

PKG_SOURCE_URL:=https://github.com/EvilOlaf/rtl8189ES_linux.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=f95ad2e28bfb1a4350ff5da123a28df4183ca120
PKG_MIRROR_HASH:=9feeef5f4d481d3a6a6b6093fdd620893b0a400d59485704c8edf10979ca221d

PKG_LICENSE:=GPLv2
PKG_BUILD_PARALLEL:=1

SUPPORTED_OPENWRT_COMMIT:=b3ff21a2ec7a0d9ad69d68ff401e16d9a8ef7abb

STAMP_CONFIGURED_DEPENDS := $(STAGING_DIR)/usr/include/mac80211-backport/backport/autoconf.h

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/package.mk

define KernelPackage/rtl8189fs
  SUBMENU:=Wireless Drivers
  TITLE:=Realtek RTL8189FS SDIO WiFi driver
  URL:=https://github.com/EvilOlaf/rtl8189ES_linux
  DEPENDS:=@TARGET_sunxi +kmod-cfg80211 +kmod-mmc
  FILES:=$(PKG_BUILD_DIR)/8189fs.ko
  AUTOLOAD:=$(call AutoProbe,8189fs)
endef

define KernelPackage/rtl8189fs/description
  Out-of-tree driver for Realtek RTL8189FS SDIO wireless devices.
endef

NOSTDINC_FLAGS := \
	$(KERNEL_NOSTDINC_FLAGS) \
	-I$(PKG_BUILD_DIR) \
	-I$(PKG_BUILD_DIR)/include \
	-I$(STAGING_DIR)/usr/include/mac80211-backport \
	-I$(STAGING_DIR)/usr/include/mac80211-backport/uapi \
	-I$(STAGING_DIR)/usr/include/mac80211 \
	-I$(STAGING_DIR)/usr/include/mac80211/uapi \
	-include backport/backport.h \
	-Wno-error=address \
	-Wno-error=date-time \
	-Wno-error=empty-body \
	-Wno-error=missing-prototypes \
	-Wno-error=restrict \
	-Wno-error=stringop-overread
NOSTDINC_FLAGS += -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT

define Build/Prepare
	$(call Build/Prepare/Default)
	rm -f $(PKG_BUILD_DIR)/include/linux/wireless.h
endef

define Build/Compile
	+$(KERNEL_MAKE) $(PKG_JOBS) \
		M="$(PKG_BUILD_DIR)" \
		CONFIG_RTL8189FS=m \
		NOSTDINC_FLAGS="$(NOSTDINC_FLAGS)" \
		modules
endef

$(eval $(call KernelPackage,rtl8189fs))
