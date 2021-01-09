#pragma once

#include "bsp.h"
#include "sdram.h"

#define SDRAM_CTRL SYSTEM_SDRAM_A_CTRL
#define SDRAM_PHY  SDRAM_DOMAIN_PHY_A_CTRL
#define SDRAM_BASE SYSTEM_SDRAM_A0_BMB

#define RL 3
#define WL 0
#define CTRL_BURST_LENGHT 1
#define PHY_CLK_RATIO 1

void bspMain() {

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

    asm("ebreak");
}
