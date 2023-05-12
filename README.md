Welcome to wch32062's  git source of OpenWrt and packages
=
中文：如何编译自己需要的 OpenWrt 固件
-
注意：
1. 不要用 root 用户进行编译！！！
2. 国内用户编译前最好准备好梯子
3. 默认登陆IP: 192.168.1.1, 密码: password

  首先装好 Ubuntu 64bit，推荐  Ubuntu  20.04 LTS x64

编译命令如下
-
```bash
（lede）
sudo apt update -y
sudo apt full-upgrade -y
sudo apt install -y ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
bzip2 ccache cmake cpio curl device-tree-compiler fastjar flex gawk gettext gcc-multilib g++-multilib \
git gperf haveged help2man intltool libc6-dev-i386 libelf-dev libglib2.0-dev libgmp3-dev libltdl-dev \
libmpc-dev libmpfr-dev libncurses5-dev libncursesw5-dev libreadline-dev libssl-dev libtool lrzsz \
mkisofs msmtp nano ninja-build p7zip p7zip-full patch pkgconf python2.7 python3 python3-pyelftools \
libpython3-dev qemu-utils rsync scons squashfs-tools subversion swig texinfo uglifyjs upx-ucl unzip \
vim wget xmlto xxd zlib1g-dev
```
```bash
git clone https://github.com/coolsnowwolf/lede
cd lede
```
编译过程中命令
-
```bash
./scripts/feeds update -a 
./scripts/feeds install -a
make menuconfig
source /etc/environment
make -j8 download
make -j1 V=s 
```
二次编译不改配置
-
```bash
cd lede
source /etc/environment
git pull
./scripts/feeds update -a && ./scripts/feeds install -a
make defconfig
make -j8 download
make -j$(($(nproc) + 1)) V=s
```

二次编译重新配置
-
```bash
cd lede
source /etc/environment
git pull
./scripts/feeds update -a && ./scripts/feeds install -a
rm -rf ./tmp && rm -rf .config
make menuconfig
make -j8 download
make -j$(($(nproc) + 1)) V=s
```

特别感谢：
=
Lean's源代码；
Lienol源代码；
P3TERX源代码；
-
