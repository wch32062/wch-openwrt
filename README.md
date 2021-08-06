Welcome to wch32062's  git source of OpenWrt and packages
=
中文：如何编译自己需要的 OpenWrt 固件
-
注意：
1. 不要用 root 用户进行编译！！！
2. 国内用户编译前最好准备好梯子
3. 默认登陆IP: 192.168.1.1, 密码: password

  首先装好 Ubuntu 64bit，推荐  Ubuntu  18.04 LTS x64

编译命令如下
-
```bash
sudo apt-get update
sudo apt-get -y install build-essential asciidoc binutils bzip2 gawk gettext git libncurses5-dev libz-dev patch python3 python2.7 unzip zlib1g-dev lib32gcc1 libc6-dev-i386 subversion flex uglifyjs git-core gcc-multilib p7zip p7zip-full msmtp libssl-dev texinfo libglib2.0-dev xmlto qemu-utils upx libelf-dev autoconf automake libtool autopoint device-tree-compiler g++-multilib antlr3 gperf wget curl swig rsync
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
git pull
source /etc/environment
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
