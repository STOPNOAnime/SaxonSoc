package saxon.board.sipeed

import saxon.common.I2cModel
import saxon._
import spinal.core
import spinal.core.{Clock, _}
import spinal.core.sim._
import spinal.lib.blackbox.lattice.ecp5.{IFS1P3BX, ODDRX1F, OFS1P3BX}
import spinal.lib.blackbox.xilinx.s7.{BSCANE2, BUFG, STARTUPE2}
import spinal.lib.bus.bmb._
import spinal.lib.bus.bsb.BsbInterconnectGenerator
import spinal.lib.bus.misc.{AddressMapping, SizeMapping}
import spinal.lib.bus.simple.{PipelinedMemoryBus, PipelinedMemoryBusDecoder}
import spinal.lib.com.eth.{MacEthParameter, PhyParameter}
import spinal.lib.com.jtag.sim.JtagTcp
import spinal.lib.com.jtag.{Jtag, JtagTap, JtagTapDebuggerGenerator, JtagTapInstructionCtrl}
import spinal.lib.com.jtag.xilinx.Bscane2BmbMasterGenerator
import spinal.lib.com.spi.ddr.{SpiXdrMasterCtrl, SpiXdrParameter}
import spinal.lib.com.uart.UartCtrlMemoryMappedConfig
import spinal.lib.com.uart.sim.{UartDecoder, UartEncoder}
import spinal.lib.generator._
import spinal.lib.graphic.RgbConfig
import spinal.lib.graphic.vga.{BmbVgaCtrlGenerator, BmbVgaCtrlParameter}
import spinal.lib.io.{Gpio, InOutWrapper, TriStateOutput}
import spinal.lib.master
import spinal.lib.memory.sdram.sdr._
import spinal.lib.memory.sdram.xdr.CoreParameter
import spinal.lib.memory.sdram.xdr.phy.{Ecp5Sdrx2Phy, XilinxS7Phy}
import spinal.lib.misc.analog.{BmbBsbToDeltaSigmaGenerator, BsbToDeltaSigmaParameter}
import spinal.lib.system.dma.sg.{DmaMemoryLayout, DmaSgGenerator}
import vexriscv.demo.smp.VexRiscvSmpClusterGen


// Define a SoC abstract enough to be used in simulation (no PLL, no PHY)
class TangSmpLinuxAbstract(cpuCount : Int) extends VexRiscvClusterGenerator(cpuCount){
  val fabric = withDefaultFabric(withOutOfOrderDecoder = false)

  val sdramA = SdramSdrBmbGenerator(address = 0x80000000l)

  val gpioA = BmbGpioGenerator(0x00000)

  val uartA = BmbUartGenerator(0x10000)

  val spiA = new BmbSpiGenerator(0x20000){
    val decoder = SpiPhyDecoderGenerator(phy)
    val user = decoder.spiMasterNone()
    val flash = decoder.spiMasterId(0)
    val sdcard = decoder.spiMasterId(1)
  }

  implicit val bsbInterconnect = BsbInterconnectGenerator()

  val ramA = BmbOnChipRamGenerator(0xA00000l)
  ramA.hexOffset = bmbPeripheral.mapping.lowerBound
  ramA.dataWidth.load(32)
  interconnect.addConnection(bmbPeripheral.bmb, ramA.ctrl)

  interconnect.addConnection(
    fabric.iBus.bmb -> List(sdramA.bmb, bmbPeripheral.bmb),
    fabric.dBus.bmb -> List(sdramA.bmb, bmbPeripheral.bmb)
  )
}

class TangSmpLinux(cpuCount : Int) extends Generator{
  // Define the clock domains used by the SoC
  val globalCd = ClockDomainResetGenerator()
  globalCd.holdDuration.load(255)
  globalCd.enablePowerOnReset()

  val systemCd = ClockDomainResetGenerator()
  systemCd.setInput(globalCd)
  systemCd.holdDuration.load(63)

  val system = new TangSmpLinuxAbstract(cpuCount){
  }
  system.onClockDomain(systemCd.outputClockDomain)

  // Enable native JTAG debug
  val debug = system.withDebugBus(globalCd, systemCd, 0x10B80000).withJtag()

  //Manage clocks and PLL
  val clocking = add task new Area{
    val MainClk = in Bool()
    val ResetN = in Bool()

    globalCd.setInput(
      ClockDomain(
        clock = MainClk,
        reset = ResetN,
        frequency = FixedFrequency(24 MHz),
        config = ClockDomainConfig(
          resetKind = ASYNC,
          resetActiveLevel = LOW
        )
      )
    )
  }

}

object TangSmpLinuxAbstract{
  def default(g : TangSmpLinuxAbstract) = g {
    import g._

    // Configure the CPUs
    for((cpu, coreId) <- cores.zipWithIndex) {
      cpu.config.load(VexRiscvSmpClusterGen.vexRiscvConfig(
        hartId = coreId,
        ioRange = _ (31 downto 28) === 0x1,
        resetVector = 0x10A00000l,
        iBusWidth = 32,
        dBusWidth = 32,
        iCacheSize = 8192,
        dCacheSize = 8192,
        iCacheWays = 2,
        dCacheWays = 2,
        iBusRelax = true,
        earlyBranch = false
      ))
    }

    // Configure the peripherals
    ramA.size.load(8 KiB)
    ramA.hexInit.load(null)

    uartA.parameter load UartCtrlMemoryMappedConfig(
      baudrate = 115200,
      txFifoDepth = 128,
      rxFifoDepth = 128
    )
    uartA.connectInterrupt(plic, 1)

    gpioA.parameter load Gpio.Parameter(
      width = 28,
      interrupt = List(15)
    )
    gpioA.connectInterrupts(plic, 4)

    spiA.parameter load SpiXdrMasterCtrl.MemoryMappingParameters(
      SpiXdrMasterCtrl.Parameters(
        dataWidth = 8,
        timerWidth = 12,
        spi = SpiXdrParameter(
          dataWidth = 2,
          ioRate = 1,
          ssWidth = 4
        )
      ) .addFullDuplex(id = 0, lateSampling = true)
        .addHalfDuplex(id = 1, rate = 1, ddr = false, spiWidth = 1, lateSampling = false),
      cmdFifoDepth = 256,
      rspFifoDepth = 256
    )

    // Add some interconnect pipelining to improve FMax
    for(cpu <- cores) interconnect.setPipelining(cpu.dBus)(cmdValid = true, invValid = true, ackValid = true, syncValid = true)
    interconnect.setPipelining(fabric.dBus.bmb)(cmdValid = true, cmdReady = true, rspValid = true)
    interconnect.setPipelining(fabric.iBus.bmb)(cmdValid = true)
    interconnect.setPipelining(fabric.exclusiveMonitor.input)(cmdValid = true, cmdReady = true, rspValid = true)
    interconnect.setPipelining(fabric.invalidationMonitor.output)(cmdValid = true, cmdReady = true, rspValid = true)
    interconnect.setPipelining(bmbPeripheral.bmb)(cmdHalfRate = true, rspHalfRate = true)
    //interconnect.setPipelining(sdramA.bmb)(cmdValid = true, cmdReady = true, rspValid = true)

    g
  }
}


object TangSmpLinux {
  //Function used to configure the SoC
  def default(g : TangSmpLinux) = g{
    import g._

    system.sdramA.layout.load(EG4S20.layout)
    system.sdramA.timings.load(EG4S20.timingGrade7)

    TangSmpLinuxAbstract.default(system)
    system.ramA.hexInit.load("software/standalone/bootloader/build/bootloader.hex")

    g
  }

  //Generate the SoC
  def main(args: Array[String]): Unit = {

    val report = SpinalRtlConfig.generateVerilog(default(new TangSmpLinux(1)).toComponent())
    BspGenerator("sipeed/TangSmpLinux", report.toplevel.generator, report.toplevel.generator.system.cores(0).dBus)
  }
}