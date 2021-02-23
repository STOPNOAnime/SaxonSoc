#pragma once

#include "bsp.h"
#include "start.h"
#include "sdram.h"
#include "spiFlash.h"

#define SDRAM_BASE SYSTEM_SDRAM_A_BMB

#define SPI SYSTEM_SPI_A_CTRL
#define SPI_CS 0

#define GPIO SYSTEM_GPIO_A_CTRL

#define OPENSBI_MEMORY 0x80600000
#define OPENSBI_FLASH  0x00000000
#define OPENSBI_SIZE      0x40000

#define UBOOT_MEMORY     0x80500000
#define UBOOT_SBI_FLASH  0x00040000
#define UBOOT_SIZE          0x80000

void bspMain() {

    /*
    while(1){
        bsp_putString("\nMem test .. ");
        sdram_mem_init(SDRAM_BASE, 0x800000); 
        if(!sdram_mem_test(SDRAM_BASE, 0x800000)) {
            bsp_putString("pass\n");
            break;
        }
        bsp_putString("failure\n");
        bsp_uDelay(1000000);
    }
    */

    /*
    spiFlash_init(SPI, SPI_CS);
    spiFlash_wake(SPI, SPI_CS);
    bsp_putString("OpenSBI copy\n");
    spiFlash_f2m(SPI, SPI_CS, OPENSBI_FLASH, OPENSBI_MEMORY, OPENSBI_SIZE);
    bsp_putString("U-Boot copy\n");
    spiFlash_f2m(SPI, SPI_CS, UBOOT_SBI_FLASH, UBOOT_MEMORY, UBOOT_SIZE);
    */

    bsp_putString("Payload boot\n");
    void (*userMain)(u32, u32, u32) = (void (*)(u32, u32, u32))OPENSBI_MEMORY;
    smp_unlock(userMain);
    userMain(0,0,0);
}


