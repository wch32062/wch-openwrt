# wch-openwrt

HINLINK OPC-H29K（Rockchip RK3528）的 OpenWrt 固件自动构建仓库。

架构：**ImmortalWrt 源码 + 社区 BSP 补丁 + qmodem**，由 GitHub Actions 完成
「拉源码 → 打板级补丁 → 装 feeds → 套配置 → 编译 → 打包 → 发 Release」。

> 为什么不直接用 coolsnowwolf/lede：qmodem 依赖 `kmod-mhi-wwan`、`quectel-CM-5G`，
> 这两个包在 lede 里不存在，`make defconfig` 会把 qmodem 丢掉，编出来的镜像没有 5G 拨号。
> ImmortalWrt 的 feeds 里有这两个包，所以改走 ImmortalWrt。

## 支持设备

| 设备 | 工作流 | 配置文件 | 说明 |
| --- | --- | --- | --- |
| HINLINK OPC-H29K | `H29K (ImmortalWrt)` | `configs/h29k-imwrt.config` | RK3528，eMMC，1.14" ST7789V 小屏 |
| 斐讯 K2（可选） | `Build OpenWrt` | `.config` | ramips/mt7620，8 MB NOR |

K2 那条线是仓库早期留下的，继续用 lede 源码；不再需要可以把 `build-openwrt.yml`、
`build-core.yml` 和 `.config` 一起删掉。

## 默认登录

- 地址：**http://192.168.10.1**
- 密码：**password**
- Wi‑Fi：`H29K-5G` / `wchzyy520`（首次开机由 `99-h29k-dualwan` 写入）

默认 LAN 由 `diy-part2.sh` 统一改成 `192.168.10.0/24`。

## 如何构建

1. Actions → 左侧 **`H29K (ImmortalWrt)`**
2. 右上 **Run workflow**
3. `rootfs_mb` 保持 `2048`（想要 4G 就填 4096）
4. 绿色按钮

产物在运行的 **Artifacts**，同时会发一个 **Release**。
刷机用 `*-squashfs-sysupgrade.img.gz` 解压出的 `.img`。

## H29K 关键组成

| 需求 | 实现 |
| --- | --- |
| 5G 拨号 | `qmodem` + `luci-app-qmodem` + `kmod-qmi-wwan-q`（Quectel RM500U/RM520N） |
| 网线优先、5G 兜底 | `h29k-netmode`（有线 metric 10，蜂窝 metric 30） |
| 无线发信号 | `aic8800` SDIO 驱动 + 固件，`wpad-openssl` |
| 小屏 | `sitronix,st7789v` 135×240 @6MHz，`kmod-fb-tft-st7789v` |
| 容量 | rootfs 分区 2 GiB（squashfs + overlay，可用约 1.9 GiB） |

板级支持来自 [ouyangzq/H29KorH69K-OPENWRT](https://github.com/ouyangzq/H29KorH69K-OPENWRT)。
注意它自带的几个补丁用 `patch -F3` 应用时会**插错位置**（设备定义、u-boot 列表、
`U-Boot/rk3568/Default` define 嵌套），仓库里的流水线已修正，见
`.github/workflows/H29K-imwrt.yml` 里的注释。

## 目录结构

```
.
├── .github/workflows/
│   ├── H29K-imwrt.yml      # H29K 主流水线（ImmortalWrt + BSP）
│   ├── build-openwrt.yml   # K2（可选）
│   ├── build-core.yml      # K2 的公共核心（可选）
│   └── update-checker.yml  # 源码更新检查（定时已停用）
├── board/h29k/
│   ├── device-h29k.mk                  # 设备定义（避开 BSP 补丁的插入错误）
│   ├── 104-h29k-panel-st7789v.patch    # 小屏面板参数
│   └── video-st7789v.mk                # 补 video.mk 缺的 kmod 包
├── configs/
│   ├── h29k-imwrt.config   # H29K 种子配置（2G + qmodem + 小屏）
│   └── h29k.config         # lede 版旧配置（已不用，保留参考）
├── diy-part1.sh            # feeds 前：加第三方源（含 qmodem）
├── diy-part2.sh            # feeds 后：改默认 LAN
└── .config                 # K2 配置（可选）
```

## 已知限制

- **尚未实机验证**。GitHub 这条流水线已修掉三处问题（BSP 补丁路径、Release 门控、files/h29k 覆盖层），
  但还没跑出过完整镜像；本机同版本已编通（27 MB squashfs，276 包），正在补上双上行覆盖层后重编。
- 小屏按 **1.14 寸 ST7789V** 配置（依据原厂 dtb 反编译：135×240 / 6MHz / 背光 gpio0 PA0）。
  若是 1.47 寸 GC9307 那版，去掉 `board/h29k/104-h29k-panel-st7789v.patch`，
  改用 BSP 默认 dts（172×320 / 15MHz / PA1）。
  分辨方法：量屏幕发光区宽度（约 2.4 cm = 1.14 寸，约 3.0 cm = 1.47 寸），或看板子丝印（V1.3 / V5）。
- `Update Checker` 需要 `ACTIONS_TRIGGER_PAT` secret 才能自动触发，未配置时只能手动运行。

## 致谢

- [ImmortalWrt](https://github.com/immortalwrt/immortalwrt)
- [ouyangzq/H29KorH69K-OPENWRT](https://github.com/ouyangzq/H29KorH69K-OPENWRT)（H29K BSP）
- [FUjr/QModem](https://github.com/FUjr/QModem)（5G 模组管理）
- [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede)

## License

[MIT](LICENSE)
