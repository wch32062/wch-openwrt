# ST7789V 小屏（1.14 寸 135x240）的 fbtft 驱动
# 这棵 ImmortalWrt 的 video.mk 只打包了 gc9307 / ili9486，st7789v 驱动在内核里却没有 kmod 包。
# 注意：这类内核模块包必须定义在 package/kernel/linux/modules/video.mk 里，
# 单独的 package 目录会因为缺内核构建上下文而报 "No targets specified"。
define KernelPackage/fb-tft-st7789v
  SUBMENU:=$(VIDEO_MENU)
  TITLE:=FB driver for the ST7789V LCD Controller
  DEPENDS:=+kmod-fb-tft
  KCONFIG:=CONFIG_FB_TFT_ST7789V
  FILES:=$(LINUX_DIR)/drivers/staging/fbtft/fb_st7789v.ko
  AUTOLOAD:=$(call AutoLoad,09,fb_st7789v)
endef

define KernelPackage/fb-tft-st7789v/description
  FB driver for the ST7789V LCD Controller
endef

$(eval $(call KernelPackage,fb-tft-st7789v))
