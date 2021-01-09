#pragma once

#include "bsp.h"
#include "start.h"
#include "sdram.h"
#include "spiFlash.h"

#define SDRAM_CTRL SYSTEM_SDRAM_A_CTRL
#define SDRAM_PHY  SDRAM_DOMAIN_PHY_A_CTRL
#define SDRAM_BASE SYSTEM_SDRAM_A0_BMB

#define SPI SYSTEM_SPI_A_CTRL
#define SPI_CS 0

#define GPIO SYSTEM_GPIO_A_CTRL

#define OPENSBI_MEMORY 0x80780000
#define OPENSBI_FLASH  0x00000000
#define OPENSBI_SIZE      0x40000

#define UBOOT_MEMORY     0x80700000
#define UBOOT_SBI_FLASH  0x00040000
#define UBOOT_SIZE          0x80000

#define RL 3
#define WL 0
#define CTRL_BURST_LENGHT 1
#define PHY_CLK_RATIO 1

void bspMain() {
    bsp_putString("\n");
    bsp_putString("SDRAM init\n");

    sdram_init(
        SDRAM_CTRL,
        RL,
        WL,
        EG4S20_ps,
        CTRL_BURST_LENGHT,
        PHY_CLK_RATIO,
        40000
    );

    sdram_sdr_init(
        SDRAM_CTRL,
        RL,
        CTRL_BURST_LENGHT,
        PHY_CLK_RATIO
    );

    while(1){
        bsp_putString("Mem test .. ");
        sdram_mem_init(SDRAM_BASE, 0x100000);
        if(!sdram_mem_test(SDRAM_BASE, 0x100000)) {
            bsp_putString("pass\n");
            break;
        }

        bsp_putString("failure\n");
        bsp_uDelay(1000000);
    }
    
    spiFlash_init(SPI, SPI_CS);
    spiFlash_wake(SPI, SPI_CS);
    bsp_putString("OpenSBI copy\n");
    spiFlash_f2m(SPI, SPI_CS, OPENSBI_FLASH, OPENSBI_MEMORY, OPENSBI_SIZE);
    bsp_putString("U-Boot copy\n");
    spiFlash_f2m(SPI, SPI_CS, UBOOT_SBI_FLASH, UBOOT_MEMORY, UBOOT_SIZE);

    bsp_putString("Jumping to 0x80780000\n");
    void (*userMain)(u32, u32, u32) = (void (*)(u32, u32, u32))OPENSBI_MEMORY;
    smp_unlock(userMain);
    userMain(0,0,0);
}


