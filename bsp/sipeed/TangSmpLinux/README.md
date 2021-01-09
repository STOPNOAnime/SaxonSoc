## Hardware

- Sipeed Tang Board
- USB micro cable
- External JTAG interface
- Optional SDCARD
- Optional custom PS2 and VGA interface #TODO

## Implemented peripherals

* GPIO access in linux
* SPI, which provide
  * FPGA SPI flash access in Linux
  * SDCARD in linux
  * User usage SPI
* VGA, which can be used with DirectFB or X11 in linux

## Boot sequence

The boot sequence is done in 4 steps :

* bootloader : In the OnChipRam initialized by the FPGA bitstream
  * Copy the openSBI and the u-boot binary from the FPGA SPI flash to the SDRAM
  * Jump to the openSBI binary in machine mode

* openSBI : In the SDRAM
  * Initialise the machine mode CSR to support further supervisor SBI call and to emulate some missing CSR
  * Jump to the u-boot binary in supervisor mode

* u-boot : In the SDRAM
  * Wait two seconds for user inputs
  * Read the linux uImage and dtb from the sdcard first partition
  * Boot linux

* Linux : in the SDRAM
  * Kernel boot

## Binary locations

OnChipRam (8KB): 
- 0x1A000000 : bootloader 

SDRAM (8MB):
- 0x80000000 : Linux kernel
- 0x806F0000 : dtb 
- 0x80700000 : u-boot
- 0x80780000 : openSBI, 512 KB of reserved-memory (Linux can't use that memory space)

FPGA SPI flash:
- 0x000000   : u-boot
- 0x080000   : openSBI

Sdcard :
- p1:uImage  : Linux kernel
- p1:dtb     : Linux device tree binary

## Dependencies

```
# Java JDK 8 (higher is ok)
sudo add-apt-repository -y ppa:openjdk-r/ppa
sudo apt-get update
sudo apt-get install openjdk-8-jdk -y
sudo update-alternatives --config java
sudo update-alternatives --config javac

# SBT (Scala build tool)
echo "deb https://dl.bintray.com/sbt/debian /" | sudo tee -a /etc/apt/sources.list.d/sbt.list
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823
sudo apt-get update
sudo apt-get install sbt

# RISC-V toolchain
VERSION=8.3.0-1.2
mkdir -p ~/opt
cd ~/opt
wget https://github.com/xpack-dev-tools/riscv-none-embed-gcc-xpack/releases/download/v$VERSION/xpack-riscv-none-embed-gcc-$VERSION-linux-x64.tar.gz
tar -xvf xpack-riscv-none-embed-gcc-$VERSION-linux-x64.tar.gz
rm xpack-riscv-none-embed-gcc-$VERSION-linux-x64.tar.gz
mv xpack-riscv-none-embed-gcc-$VERSION xpack-riscv-none-embed-gcc
echo 'export PATH=~/opt/xpack-riscv-none-embed-gcc/bin:$PATH' >> ~/.bashrc
export PATH=~/opt/xpack-riscv-none-embed-gcc/bin:$PATH

```

## Building everything

It will take quite a while to build, good luck and have fun <3

```
# Getting this repository
mkdir TangSmpLinux 
cd TangmpLinux
git clone https://github.com/SpinalHDL/SaxonSoc.git -b dev-0.1 --recursive SaxonSoc

# Sourcing the build script
source SaxonSoc/bsp/sipeed/TangSmpLinux/source.sh

# Clone opensbi, u-boot, linux, buildroot, openocd
saxon_clone

# Build the FPGA bitstream
saxon_standalone_compile bootloader
saxon_netlist
saxon_bitstream

# Build the firmware
saxon_opensbi
saxon_uboot
saxon_buildroot

# Build the programming tools
saxon_standalone_compile sdramInit
saxon_openocd
```

## Loading the FPGA and booting linux with ramfs using openocd

```
source SaxonSoc/bsp/sipeed/TangSmpLinux/source.sh

# Load the bitestream into the FPGA
saxon_bitstream_flash

# Boot linux using a ram file system (no sdcard), look at the saxon_buildroot_load end message
saxon_fpga_load
saxon_buildroot_load

# Connecting the USB serial port
saxon_serial
```

