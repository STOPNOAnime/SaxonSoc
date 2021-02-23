#!/bin/sh

# Locations
SAXON_SOURCED_SH=$(realpath ${BASH_SOURCE})
SAXON_BSP_PATH=$(dirname $SAXON_SOURCED_SH)
SAXON_ROOT=$SAXON_BSP_PATH/"../../../.."
SAXON_BSP_COMMON_SCRIPTS=$SAXON_ROOT/SaxonSoc/bsp/common/scripts

# Configurations
SAXON_OPENSBI_PLATEFORM=spinal/saxon/bsp
SAXON_UBOOT_DEFCONFIG=saxon_bsp_defconfig
SAXON_BUILDROOT_DEFCONFIG=spinal_saxon_bsp_defconfig
SAXON_BUILDROOT_DTS=board/spinal/saxon_bsp/dts
SAXON_BUILDROOT_OVERLAY=board/spinal/saxon_bsp/rootfs_overlay

# Fixes
SAXON_FIXES=()
SAXON_FIXES+=($SAXON_ROOT/SaxonSoc/bsp/common/fixes/buildroot/rng-tools/use_urandom)

# Functionalities
source $SAXON_BSP_COMMON_SCRIPTS/base.sh
source $SAXON_BSP_COMMON_SCRIPTS/openocd.sh
source $SAXON_BSP_COMMON_SCRIPTS/opensbi.sh
source $SAXON_BSP_COMMON_SCRIPTS/uboot.sh
source $SAXON_BSP_COMMON_SCRIPTS/buildroot.sh

saxon_netlist(){
  cd $SAXON_SOC
  sbt "runMain saxon.board.sipeed.TangSmpLinux"
}

saxon_bitstream_compile(){
  cd $SAXON_SOC/hardware/synthesis/sipeed/TangSmpLinux
  make build
}

saxon_bitstream_flash(){
  cd $SAXON_SOC/hardware/synthesis/sipeed/TangSmpLinux
  make flash
}

saxon_bitstream_clean(){
  cd $SAXON_SOC/hardware/synthesis/sipeed/TangSmpLinux
  make clean
}

saxon_serial(){
  picocom -b 115200 /dev/ttyUSB1 --imap lfcrlf
}

saxon_gdb(){
  riscv64-unknown-elf-gdb -ex 'target remote localhost:3333' -ex 'set remotetimeout 60' -ex 'set arch riscv:rv32' -ex 'monitor reset halt'
}

saxon_sdcard_format(){
  (
  echo o
  echo n
  echo p
  echo 1
  echo
  echo +100M
  echo n
  echo p
  echo 2
  echo
  echo +500M
  echo t
  echo 1
  echo b
  echo p
  echo w
  ) | sudo fdisk $1
}

saxon_sdcard_p1(){
  cd $SAXON_ROOT
  sudo umount $11
  sudo mkdosfs $11
  sudo rm -rf sdcard1
  sudo mkdir -p sdcard1
  sudo mount $11 sdcard1
  sudo cp buildroot/output/images/dtb  sdcard1/dtb
  sudo cp buildroot/output/images/uImage  sdcard1/uImage
}

saxon_sdcard_p2(){
  cd $SAXON_ROOT
  sudo umount $12
  sudo mke2fs $12
  rm -rf sdcard2
  mkdir -p sdcard2
  sudo mount $12 sdcard2
  sudo tar xf buildroot/output/images/rootfs.tar -C sdcard2
}

saxon_flash_sd(){
  if [ -z "$1" ]
  then
    echo "No argument supplied"
  else
    saxon_sdcard_format $1
    saxon_sdcard_p1 $1
    saxon_sdcard_p2 $1
  fi
}