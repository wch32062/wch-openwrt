
define Device/hinlink_opc-h29k
  $(Device/rk3528)
  DEVICE_VENDOR := HINLINK
  DEVICE_MODEL := OPC-H29K
  DEVICE_ALT0_VENDOR := LinkStar
  DEVICE_ALT0_MODEL := OPC-H29K
  UBOOT_DEVICE_NAME := generic-rk3528
  DEVICE_PACKAGES := hinlink-settings \
    kmod-fb-tft-gc9307 kmod-input-touchscreen-axs5106 \
    kmod-saradc-rockchip tft-display luci-theme-daocaoren \
    kmod-usb-serial-option kmod-usb-wdm \
    kmod-aic8800-sdio aic8800-sdio-firmware aic8800-loader \
    wpad-openssl
endef
TARGET_DEVICES += hinlink_opc-h29k
