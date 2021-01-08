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
SAXON_FIXES+=($SAXON_ROOT/SaxonSoc/bsp/common/fixes/buildroot/libopenssl/vexriscv_aes)
SAXON_FIXES+=($SAXON_ROOT/SaxonSoc/bsp/common/fixes/buildroot/dropbear/vexriscv_aes)
SAXON_FIXES+=($SAXON_ROOT/SaxonSoc/bsp/common/fixes/buildroot/dropbear/no_swap)
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

saxon_bitstream(){
  cd $SAXON_SOC/hardware/synthesis/sipeed/TangSmpLinux
  make all
}

saxon_serial(){
  picocom -b 115200 /dev/ttyUSB1 --imap lfcrlf
}

