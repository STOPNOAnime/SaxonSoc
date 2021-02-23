## Hardware

- Sipeed Tang Board
- Micro USB cable
- External JTAG interface
- SD card

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
- 0x80500000 : u-boot (it relocates itself later)
- 0x80600000 : openSBI, 512 KB of reserved-memory (Linux can't use that memory space)
- 0x80670000 : dtb 

FPGA SPI flash:
- 0x000000   : openSBI
- 0x040000   : u-boot

Sdcard :
- p1:uImage  : Linux kernel
- p1:dtb     : Linux device tree binary
- p2:rootfs  : Linux File system

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

You also need the [TD IDE](https://tang.sipeed.com/en/getting-started/installing-td-ide/linux/) in path.

## Building everything

```
# Getting this repository
mkdir TangSmpLinux 
cd TangSmpLinux
git clone https://github.com/STOPNOAnime/SaxonSoc.git -b dev-0.1 --recursive SaxonSoc

# Sourcing the build script
source SaxonSoc/bsp/sipeed/TangSmpLinux/source.sh

# Clone opensbi, u-boot, linux, buildroot, openocd
saxon_clone

# Build the FPGA bitstream
saxon_standalone_compile bootloader
saxon_netlist
saxon_bitstream_compile

# Build the firmware
saxon_opensbi
saxon_uboot
saxon_buildroot

# Build the programming tools
saxon_openocd
```

## Loading the FPGA and booting linux with sd card using openocd

```
source SaxonSoc/bsp/sipeed/TangSmpLinux/source.sh

# Flash the FPGA Bitstream
saxon_bitstream_flash

# Flash the sd card. IMPORTANT: replace "/dev/sd_card" with a proper dev device for your sd card
saxon_flash_sd /dev/sd_card

# Place the sd card into the FPGA

# Connect the USB serial port
saxon_serial

# Boot linux with openocd
saxon_buildroot_load

# Wait until linux is loaded and then execute these commands to flash the SPI Flash
TO DO

# Now you should be able to reset the board and see it boot linux on the serial terminal. You now have working linux :)
```
