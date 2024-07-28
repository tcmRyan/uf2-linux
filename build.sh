#!/bin/sh

CURRENT_DIR=pwd()
curl -fsSL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh && bash nodesource_setup.sh
sudo apt-get update
sudo apt-get install -y mtools cpio bc p7zip-full squashfs-tools bison flex libssl-dev fatcat nodejs build-essential gcc-arm*

mkdir -p /picore/kernel3
cd /picore/kernel3
curl http://tinycorelinux.net/14.x/armv6/releases/RPi/src/kernel/rpi-linux-6.1.68.tar.xz > linux-rpi.tar.xz
tar xf linux-rpi.tar.xz -C linux-rpi
rm linux-rpi.tar.xz

curl http://tinycorelinux.net/14.x/armv6/releases/RPi/src/kernel/6.1.68-piCore_Module.symvers.xz | xzcat > Module.symvers
curl http://tinycorelinux.net/14.x/armv6/releases/RPi/src/kernel/6.1.68-piCore_System.map.xz | xzcat > System.map
mkdir /picore/img3
cd /picore/img3
curl http://tinycorelinux.net/14.x/armv6/releases/RPi/piCore-14.1.0.zip > picore.zip
mkdir /picore/boot3
7z x picore.zip && dd if=piCore-14.1.0.img of=fat.img bs=4194304 skip=1 count=23 && fatcat fat.img -x /picore/boot3
cd /picore/kernel3/linux-rpi
cp $CURRENT_DIR/docker/config .config
make ARCH=arm CROSS_COMPILE=/rpxc/bin/arm-linux-gnueabihf- modules_prepare
echo "#!/bin/sh" > mkusb.sh
echo "make ARCH=arm CROSS_COMPILE=/rpxc/bin/arm-linux-gnueabihf- SUBDIRS=drivers/usb -j10 modules" >> mkusb.sh
chmod +x mkusb.sh
./mkusb.sh

cd /picore
rm -rf img3
mkdir rootfs3
cd rootfs3 && zcat ../boot3/piCore-14.1.0.gz | cpio -i -H newc -d

git clone https://github.com/WiringPi/WiringPi
cd /picore/WiringPi/wiringPi
arm-linux-gnueabihf-gcc -g -ffunction-sections -fdata-sections -Os -c *.c -I .
arm-linux-gnueabihf-ar rcs libwiringPi.a *.o
cp libwiringPi.a /rpxc/arm-linux-gnueabihf/lib/
cp *.h /rpxc/arm-linux-gnueabihf/libc/usr/include/

cd /picore
rm -rf WiringPi

curl http://tinycorelinux.net/14.x/armv6/tcz/libasound.tcz > libasound.tcz
curl http://tinycorelinux.net/14.x/armv6/tcz/libasound-dev.tcz > libasound-dev.tcz
mkdir sq/
unsquashfs libasound.tcz && cp -r squashfs-root/* sq/ && rm -rf squashfs-root
unsquashfs libasound-dev.tcz && cp -r squashfs-root/* sq/ && rm -rf squashfs-root
cp -a sq/usr/local/lib/libasound* /rpxc/arm-linux-gnueabihf/lib/
cp -ar sq/usr/local/include/* /rpxc/arm-linux-gnueabihf/libc/usr/include/
rm -rf sq

useradd -m build
cp $CURRENT_DIR/docker /home/build
