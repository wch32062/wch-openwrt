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

## H29K：把固件容量加大

H29K 使用 eMMC，根分区大小由配置项决定，默认 **2 GiB**：

```ini
CONFIG_TARGET_ROOTFS_PARTSIZE=2048
```

想装更多程序就把它改大（`4096`、`8192` …），只要不超过 eMMC 实际可用容量：

```ini
# configs/h29k.config
CONFIG_TARGET_ROOTFS_PARTSIZE=4096
```

几点说明：

- **为什么用 ext4 而不是 squashfs**：`CONFIG_TARGET_ROOTFS_EXT4FS=y` + 关闭 squashfs 后，
  整个根分区可读可写，`opkg install` 装的东西直接落在分区里，不会因为 overlay 空间不足失败。
  想换回 squashfs，就把这两行反过来写：
  ```ini
  CONFIG_TARGET_ROOTFS_SQUASHFS=y
  CONFIG_TARGET_ROOTFS_EXT4FS=n
  ```
- **分区不能超过硬件**：`2048` 表示 2 GiB 的 rootfs 分区，镜像文件也会接近 2 GiB。
  eMMC 只有 8 GB 时用 `4096` 仍然安全，`8192` 就要先确认容量。
- **构建日志会回显实际值**：编译步骤会打印 `rootfs 分区大小: 2048 MiB`，Release 说明里也会写，
  用来确认配置真的生效了（配置被 `make defconfig` 丢弃时会露出差异）。
- **刷写方式**：RKDevTool（Maskrom）→ boot 分区选 `H29K-Boot-Loader.bin`，
  system 分区选产物里 `*-sysupgrade.img.gz` **解压后的 `.img`**。
  `.gz` 是压缩包，不能直接当镜像刷。

K2 无法用这种方式扩容：8 MB NOR 是硬件固定的，只能靠精简软件包来腾空间。

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
