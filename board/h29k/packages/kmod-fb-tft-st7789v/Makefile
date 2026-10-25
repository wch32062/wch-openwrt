#
# ST7789V 小屏（1.14 寸 135x240）的 fbtft 驱动包
#
# 驱动本身在内核树里（drivers/staging/fbtft/fb_st7789v.c），
# 但这棵 ImmortalWrt 的 video.mk 只打包了 gc9307 / ili9486 等几个，
# 没有 st7789v 的 kmod 包，所以这里按同样写法补一个。
#
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=kmod-fb-tft-st7789v
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0

include $(INCLUDE_DIR)/package.mk

define KernelPackage/fb-tft-st7789v
  SUBMENU:=Video Support
  TITLE:=FB driver for the ST7789V LCD Controller
  DEPENDS:=+kmod-fb-tft
  KCONFIG:=CONFIG_FB_TFT_ST7789V
  FILES:=$(LINUX_DIR)/drivers/staging/fbtft/fb_st7789v.ko
  AUTOLOAD:=$(call AutoLoad,09,fb_st7789v)
endef

define KernelPackage/fb-tft-st7789v/description
  FB driver for the ST7789V LCD Controller (in-tree fbtft)
endef

$(eval $(call KernelPackage,fb-tft-st7789v))
