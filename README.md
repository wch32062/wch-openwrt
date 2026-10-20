# wch-openwrt

基于 [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede)（master 分支）的 OpenWrt 固件自动构建仓库，
用 GitHub Actions 完成「拉源码 → 装 feeds → 套配置 → 编译 → 打包 → 发 Release」全流程。

## 支持设备

| 设备 | 工作流 | 配置文件 | 平台 |
| --- | --- | --- | --- |
| 斐讯 K2 | `Build OpenWrt` | `.config` | ramips / mt7620（8 MB NOR + 64 MB RAM） |
| HINLINK OPC-H29K | `H29K` | `configs/h29k.config` | rockchip / armv8，RK3528，eMMC |
| FriendlyARM NanoPi R2S | `R2S` | `configs/r2s.config` | rockchip / armv8，RK3328，microSD |
| FriendlyARM NanoPi R4S | `R4S` | `configs/r4s.config` | rockchip / armv8，RK3399，microSD/eMMC |

## 默认登录

- 地址：**http://192.168.100.1**
- 密码：**password**（首次登录请立即修改）

> 默认 LAN 网段由 `diy-part2.sh` 统一改为 `192.168.100.0/24`，所有设备一致。

## 如何构建

1. 进入仓库 **Actions** 页；
2. 左侧选对应工作流（如 `H29K`）；
3. 点 **Run workflow**；
4. 需要时勾选 `ssh`，会通过 tmate 打开一个调试会话，方便进容器里手工排查。

构建产物：

- **Artifacts**：`OpenWrt_<设备>_<型号>_<时间>`，保留期由仓库设置决定；
- **Release**：K2 / H29K / R4S 会发布 Release，自动保留最近 3 个，更早的连同 tag 一起清理。

`Update Checker` 每 18 小时检查一次 lede 的 master 提交，有更新就触发 K2 构建
（需要先在 Settings → Secrets 里配置 `ACTIONS_TRIGGER_PAT`）。

## H29K：容量（镜像 2 GiB，开机自动撑满 eMMC）

镜像里的 rootfs 分区固定 **2 GiB**，只决定产物文件多大：

```ini
CONFIG_TARGET_ROOTFS_PARTSIZE=2048
```

刷进 eMMC 后，首次启动由 `files/h29k/etc/uci-defaults/99-h29k-growroot` 自动把 p2
扩到磁盘末尾并 `resize2fs`，所以实际可用容量就是整块 eMMC（8/16/32/64 GB 都行），
不用手工分区，也不会像上个项目那样 `/overlay` 只剩 338 MB、装 Docker 立刻爆盘。

- 看结果：`df -h /`、`logread -e h29k-growroot`
- 想固定大小、不自动扩：删掉 `99-h29k-growroot`，把上面改成你要的 MiB 数
- 用的是 **ext4 可写根分区**（`CONFIG_TARGET_ROOTFS_EXT4FS=y`，关掉 squashfs），
  `opkg install` 和 Docker 都直接落在分区里，不受 overlay 限制
- 构建日志会打印 `rootfs 分区大小: 2048 MiB`，用来确认配置真的生效

刷写：RKDevTool（Maskrom）→ boot 分区 `H29K-Boot-Loader.bin`，system 分区用
`*-sysupgrade.img.gz` **解压出来的 `.img`**（`.gz` 不能直接刷）。

K2 无法扩容：8 MB NOR 是硬件固定的，只能靠精简软件包腾空间。

## H29K：5G 模块与双上游（网线优先，5G 兜底）

### 驱动情况

| 硬件 | 提供方式 |
| --- | --- |
| 网口（GMAC + RTL8211F PHY） | 内核内置（`CONFIG_STMMAC_ETH` / `CONFIG_REALTEK_PHY`），插线即可用 |
| WiFi（AIC8800 SDIO） | `kmod-aic8800-sdio`，含固件 |
| 屏幕（ST7789V） | `kmod-fb-tft-st7789v` |
| 5G 模块（QMI/MBIM/AT） | **原来没有**，已在 `configs/h29k.config` 补上 |

补进去的包：`kmod-usb-net-qmi-wwan`、`kmod-usb-net-cdc-mbim`、`kmod-usb-net-rndis`、
`kmod-usb-wdm`、`kmod-usb-serial-option`、`kmod-usb-serial-qualcomm`、`kmod-usb-acm`，
拨号工具 `uqmi`、`umbim`，LuCI 协议 `luci-proto-qmi`、`luci-proto-mbim`。

模组是 **Quectel RM500U / RM520N** 的话，还额外装了 qmodem feed 里的
`kmod-qmi-wwan-q`（QMAP 必须用它，内核自带 `qmi_wwan` 不认）和 `kmod-pcie-mhi`（PCIe 形态）。

### 建 wwan 接口

APN 因卡而异，刷机后在 LuCI「网络 → 接口 → 添加新接口」建 `wwan`，或者直接用命令：

```bash
uci set network.wwan=interface
uci set network.wwan.proto='qmi'
uci set network.wwan.device='/dev/cdc-wdm0'
uci set network.wwan.apn='ctnet'      # 按你的卡改：cmnet / 3gnet …
uci set network.wwan.pdptype='ipv4'
uci set network.wwan.metric='20'      # 比 wan 的 10 大，所以只有在网线不通时才用它
uci commit network
ifup wwan
```

MBIM 模块把 `proto` 换成 `mbim`。执行 `ls /dev/cdc-wdm*` 能看到设备，说明驱动装对了。

### 双上行（网线优先，5G 兜底）

直接把上个项目 v3 里验证过的那套 `h29k-netmode` 搬过来了，没有另写脚本：

| 文件 | 作用 |
| --- | --- |
| `files/h29k/usr/sbin/h29k-netmode` | 单网口双上行管理 |
| `files/h29k/etc/init.d/h29k-netmode` | 开机自启（START=95，网络与防火墙就绪后） |
| `files/h29k/etc/config/netmode` | 参数 |
| `files/h29k/etc/uci-defaults/99-h29k-dualwan` | 首次开机写 Wi‑Fi（SSID `H29K-5G`）与 LAN `192.168.10.1` |

```ini
config main 'main'
	option ethernet_enabled '1'
	option mode 'auto'            # 有载波且拿到地址就当 WAN，否则回落 LAN
	option wan_proto 'dhcp'       # dhcp | pppoe | static
	option wan_metric '10'        # 有线优先
	option cellular_enabled '1'
	option modem_metric '30'      # 5G 兜底
```

有线的 metric 10 小于 5G 的 30：插着网线就走网线；拔掉或拿不到地址，默认路由自动落到 5G。
5G 侧由 **qmodem** 拨号（`configs/h29k.config` 已选中 `qmodem`、`luci-app-qmodem`）。

```bash
h29k-netmode status     # 当前模式 / 载波 / 地址
h29k-netmode auto       # 自动（默认）
h29k-netmode wan        # 网线固定当 WAN
h29k-netmode lan        # 网线只当 LAN
h29k-netmode apply      # 按 /etc/config/netmode 立即应用
logread -e netmode      # 切换日志
```

## 目录结构

```
.
├── .config                     # 斐讯 K2 的完整配置
├── configs/
│   ├── h29k.config             # H29K 种子配置（含 rootfs 容量）
│   ├── r2s.config              # NanoPi R2S 种子配置
│   └── r4s.config              # NanoPi R4S 种子配置
├── diy-part1.sh                # feeds 更新前执行：取消 helloworld 注释、追加第三方源
├── diy-part2.sh                # feeds 更新后执行：改默认 LAN IP
├── customize.sh                # 历史遗留脚本，CI 不调用
├── files/
│   └── h29k/                   # H29K 专属 rootfs 覆盖（h29k-netmode、扩容、Wi-Fi 默认值）
└── .github/workflows/
    ├── build-core.yml          # 可复用构建核心（被下面四个调用）
    ├── build-openwrt.yml       # K2
    ├── H29K.yml
    ├── R2S.yml
    ├── R4S.yml
    └── update-checker.yml      # lede 源码更新检查
```

`configs/*.config` 都是**种子配置**：只写目标平台、设备、容量和要装的软件包，
构建时由 `make defconfig` 补全成完整 `.config`。这样几百 KB 的完整配置不用四个各存一份。

## 常用自定义

| 想改什么 | 改哪里 |
| --- | --- |
| 默认 LAN IP | `diy-part2.sh` 里的 `DEFAULT_LAN_IP` |
| 固件容量 | 对应 `configs/*.config` 的 `CONFIG_TARGET_ROOTFS_PARTSIZE` |
| 加软件包 | 对应配置里加 `CONFIG_PACKAGE_xxx=y` |
| 换 lede 分支 | `build-core.yml` 里的 `REPO_BRANCH` |
| 加第三方 feed | `diy-part1.sh` 里 `add_feed 名字 '仓库地址;分支'` |

## 本地编译

```bash
sudo apt update -y
sudo apt full-upgrade -y
sudo apt install -y ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
  bzip2 ccache cmake cpio curl device-tree-compiler fastjar file flex gawk gettext genisoimage git \
  gperf haveged help2man intltool libelf-dev libglib2.0-dev libgmp-dev libltdl-dev libmpc-dev \
  libmpfr-dev libncurses5-dev libncursesw5-dev libreadline-dev libssl-dev libtool lrzsz msmtp nano \
  ninja-build p7zip p7zip-full patch pkgconf python3 python3-pyelftools libpython3-dev qemu-utils \
  rsync scons squashfs-tools subversion swig texinfo uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev

git clone --depth 1 -b master https://github.com/coolsnowwolf/lede openwrt
cd openwrt
cp ../wch-openwrt/configs/h29k.config .config
../wch-openwrt/diy-part1.sh            # 在 openwrt/ 目录里执行
./scripts/feeds update -a
./scripts/feeds install -a
../wch-openwrt/diy-part2.sh
make defconfig
make -j$(nproc) download
make -j$(nproc) V=s
```

注意：

- **不要用 root 用户编译**；
- 国内网络建议先准备代理，`feeds update` 和大文件下载对网络比较敏感；
- 二次编译建议 `rm -rf ./tmp && make defconfig` 后再编。

## 致谢

- [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede)
- [Lienol/openwrt-package](https://github.com/Lienol/openwrt-package)
- [P3TERX/Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt)

## License

[MIT](LICENSE)
