module top (
  input               ResetN,
  input 			  MainClk,
  
  input               jtag_tms,
  input               jtag_tdi,
  output              jtag_tdo,
  input               jtag_tck,
  
  output              uart_txd,
  input               uart_rxd,
  
  inout wire [13:0]   gpioA
);

wire [13:0] gpioA_writeEnable;
wire [13:0] gpioA_write;
wire [13:0] gpioA_read;

genvar i;
for (i=0;i<14;i=i+1) begin
	assign gpioA[i] = gpioA_writeEnable[i] ? gpioA_write[i] : 1'bz; // To drive the inout net
end
assign gpioA_read = gpioA; // To read from inout net

wire sdram_RASn; // synthesis keep
wire sdram_CASn; // synthesis keep
wire sdram_WEn; // synthesis keep
wire [10:0] sdram_ADDR; // synthesis keep
wire [1:0] sdram_BA; // synthesis keep
wire sdram_CKE; // synthesis keep
wire sdram_CSn; // synthesis keep
wire [3:0] sdram_DQM; // synthesis keep

wire [31:0] sdram_DQ_read;
wire [31:0] sdram_DQ_write;
wire [31:0] sdram_DQ_writeEnable;
wire [31:0] sdram_DQ; // synthesis keep

for (i=0;i<32;i=i+1) begin
	assign sdram_DQ[i] = sdram_DQ_writeEnable[i] ?  sdram_DQ_write[i] : 1'bz; // To drive the inout net
end
assign sdram_DQ_read = sdram_DQ; // To redad from inout net

TangSmpLinux TangSmpLinux (
	.clocking_MainClk(MainClk),
	.clocking_ResetN(ResetN),

	.system_uartA_uart_txd(uart_txd),
	.system_uartA_uart_rxd(uart_rxd),

	.system_gpioA_gpio_read(gpioA_read),
	.system_gpioA_gpio_write(gpioA_write),
	.system_gpioA_gpio_writeEnable(gpioA_writeEnable),

	.debug_jtag_tms(jtag_tms),
	.debug_jtag_tdi(jtag_tdi),
	.debug_jtag_tdo(jtag_tdo),
	.debug_jtag_tck(jtag_tck),

	.system_sdramA_sdram_ADDR(sdram_ADDR),
	.system_sdramA_sdram_BA(sdram_BA),
	.system_sdramA_sdram_DQ_read(sdram_DQ_read),
	.system_sdramA_sdram_DQ_write(sdram_DQ_write),
	.system_sdramA_sdram_DQ_writeEnable(sdram_DQ_writeEnable),
	.system_sdramA_sdram_DQM(sdram_DQM),
	.system_sdramA_sdram_CASn(sdram_CASn),
	.system_sdramA_sdram_CKE(sdram_CKE),
	.system_sdramA_sdram_CSn(sdram_CSn),
	.system_sdramA_sdram_RASn(sdram_RASn),
	.system_sdramA_sdram_WEn(sdram_WEn)
);

EG_PHY_SDRAM_2M_32 EG_PHY_SDRAM_2M_32 (
    .clk(MainClk), 
	.ras_n(sdram_RASn), 
	.cas_n(sdram_CASn), 
	.we_n(sdram_WEn), 
	.addr(sdram_ADDR), 
	.ba(sdram_BA), 
	.dq(sdram_DQ), 
	.cs_n(sdram_CSn), 
	.dm0(sdram_DQM[0]), 
	.dm1(sdram_DQM[1]),  
	.dm2(sdram_DQM[2]),  
	.dm3(sdram_DQM[3]),  
	.cke(sdram_CKE) 
);

endmodule
