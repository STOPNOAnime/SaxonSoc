## Remeber
in BmpSdramControl

def busCapabilities(layout : SdramLayout) = BmbAccessCapabilities(
    addressWidth  = layout.byteAddressWidth,
    dataWidth     = layout.dataWidth,
    lengthWidthMax   = log2Up(layout.dataWidth/8),
    alignment     = BmbParameter.BurstAlignement.LENGTH
  )

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

## Building everything

It will take quite a while to build, good luck and have fun <3

```
# Getting this repository
mkdir TangSmpLinux 
cd TangmpLinux
git clone https://github.com/STOPNOAnime/SaxonSoc.git -b dev-0.1 --recursive SaxonSoc

# Sourcing the build script
source SaxonSoc/bsp/sipeed/TangSmpLinux/source.sh

# Clone opensbi, u-boot, linux, buildroot, openocd
saxon_clone

# Build the FPGA bitstream and flash it
saxon_standalone_compile bootloader
saxon_netlist
saxon_bitstream_flash

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

# Flash the sd card
saxon_flash_sd

# Connecting the USB serial port
saxon_serial

# Boot linux using a sdcard
saxon_buildroot_load
```

3501804 bytes read in 32276 ms (105.5 KiB/s)
2748 bytes read in 89 ms (29.3 KiB/s)
## Booting kernel from Legacy Image at 80000000 ...
   Image Name:   Linux
   Image Type:   RISC-V Linux Kernel Image (uncompressed)
   Data Size:    3501740 Bytes = 3.3 MiB
   Load Address: 80000000
   Entry Point:  80000000
   Verifying Checksum ... OK
## Flattened Device Tree blob at 80670000
   Booting using the fdt blob at 0x80670000
   Loading Kernel Image
   Using Device Tree in place at 80670000, end 80673abb

Starting kernel ...

[    0.000000] No DTB passed to the kernel
[    0.000000] Linux version 5.0.9 (user@manjaro) (gcc version 8.4.0 (Buildroot 2020.02.1-06029-gf8a5848e93-dirty)) #1 SMP Tue Jan 12 13:01:28 CET 2021
[    0.000000] earlycon: sbi0 at I/O port 0x0 (options '')
[    0.000000] printk: bootconsole [sbi0] enabled
[    0.000000] initrd not found or empty - disabling initrd
[    0.000000] Zone ranges:
[    0.000000]   Normal   [mem 0x0000000080000000-0x00000000807fffff]
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x0000000080000000-0x00000000807fffff]
[    0.000000] Initmem setup node 0 [mem 0x0000000080000000-0x00000000807fffff]
[    0.000000] elf_hwcap is 0x1101
[    0.000000] percpu: Embedded 10 pages/cpu @(ptrval) s16784 r0 d24176 u40960
[    0.000000] Built 1 zonelists, mobility grouping off.  Total pages: 2032
[    0.000000] Kernel command line: rootwait console=hvc0 earlycon=sbi root=/dev/mmcblk0p2 init=/sbin/init mmc_core.use_spi_crc=0 loglevel=7
[    0.000000] Dentry cache hash table entries: 1024 (order: 0, 4096 bytes)
[    0.000000] Inode-cache hash table entries: 1024 (order: 0, 4096 bytes)
[    0.000000] Sorting __ex_table...
[    0.000000] Memory: 4136K/8192K available (2558K kernel code, 99K rwdata, 423K rodata, 144K init, 185K bss, 4056K reserved, 0K cma-reserved)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=1, Nodes=1
[    0.000000] rcu: Hierarchical RCU implementation.
[    0.000000] rcu:     RCU restricting CPUs from NR_CPUS=8 to nr_cpu_ids=1.
[    0.000000] rcu: RCU calculated value of scheduler-enlistment delay is 25 jiffies.
[    0.000000] rcu: Adjusting geometry for rcu_fanout_leaf=16, nr_cpu_ids=1
[    0.000000] NR_IRQS: 0, nr_irqs: 0, preallocated irqs: 0
[    0.000000] plic: mapped 32 interrupts to 2 (out of 2) handlers.
[    0.000000] clocksource: riscv_clocksource: mask: 0xffffffffffffffff max_cycles: 0x588fe9dc0, max_idle_ns: 440795202592 ns
[    0.000414] sched_clock: 64 bits at 24MHz, resolution 41ns, wraps every 4398046511097ns
[    0.015706] Console: colour dummy device 80x25
[    0.022046] printk: console [hvc0] enabled
[    0.022046] printk: console [hvc0] enabled
[    0.032187] printk: bootconsole [sbi0] disabled
[    0.032187] printk: bootconsole [sbi0] disabled
[    0.043779] Calibrating delay loop (skipped), value calculated using timer frequency.. 48.00 BogoMIPS (lpj=96000)
[    0.056471] pid_max: default: 32768 minimum: 301
[    0.073064] Mount-cache hash table entries: 1024 (order: 0, 4096 bytes)
[    0.081864] Mountpoint-cache hash table entries: 1024 (order: 0, 4096 bytes)
[    0.166697] rcu: Hierarchical SRCU implementation.
[    0.203691] smp: Bringing up secondary CPUs ...
[    0.210160] smp: Brought up 1 node, 1 CPU
[    0.236948] devtmpfs: initialized
[    0.328948] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 7645041785100000 ns
[    0.341212] futex hash table entries: 256 (order: 2, 16384 bytes)
[    0.729317] clocksource: Switched to clocksource riscv_clocksource
[    1.332541] workingset: timestamp_bits=30 max_order=11 bucket_order=0
[    1.898670] Block layer SCSI generic (bsg) driver version 0.4 loaded (major 253)
[    1.908745] io scheduler mq-deadline registered
[    1.915133] io scheduler kyber registered
[    1.958348] spinal_lib_gpio 10000000.gpio: Spinal lib GPIO chip registered 32 GPIOs
[    5.614460] m25p80 spi0.0: unrecognized JEDEC id bytes: 00, 00, 00
[    5.624328] m25p80: probe of spi0.0 failed with error -2
[    5.645791] spinal-lib,spi-1.0 10020000.spi: base (ptrval), irq -6
[    5.715147] mmc_spi spi0.1: SD/MMC host mmc0, no WP, no poweroff, cd polling
[    5.764230] ledtrig-cpu: registered to indicate activity on CPUs
[    5.818016] random: get_random_bytes called from init_oops_id+0x4c/0x60 with crng_init=0
[    5.948272] mmc0: host does not support reading read-only switch, assuming write-enable
[    5.958970] mmc0: new SDHC card on SPI
[    6.012772] mmcblk0: mmc0:0000 SA04G 3.68 GiB 
[    6.100667]  mmcblk0: p1 p2
^Cdfdfd[    6.260991] VFS: Mounted root (ext2 filesystem) readonly on device 179:2.
[    6.305977] devtmpfs: mounted
[    6.317137] Freeing unused kernel memory: 144K
[    6.324353] This architecture does not have kernel memory protection.
[    6.332992] Run /sbin/init as init process
[  203.282742] EXT2-fs (mmcblk0p2): warning: mounting unchecked fs, running e2fsck is recommended
mkdir: can't create directory '/dev/pts': No space left on device
mkdir: can't create directory '/dev/shm': No space left on device
mount: mounting devpts on /dev/pts failed: No such file or directory
mount: mounting tmpfs on /dev/shm failed: No such file or directory
Starting syslogd: OK
Starting klogd: OK
Running sysctl: [ 5201.325838] klogd invoked oom-killer: gfp_mask=0x6200ca(GFP_HIGHUSER_MOVABLE), order=0, oom_score_adj=0
[ 5201.338258] CPU: 0 PID: 50 Comm: klogd Not tainted 5.0.9 #1
[ 5201.344765] Call Trace:
[ 5201.348287] [<c002677c>] walk_stackframe+0x0/0xfc
[ 5201.354211] [<c00269b0>] show_stack+0x3c/0x50
[ 5201.359824] [<c0283238>] dump_stack+0x84/0xb0
[ 5201.365388] [<c00a37d4>] dump_header+0x60/0x270
[ 5201.371129] [<c00a2ac8>] oom_kill_process+0x124/0x484
[ 5201.377408] [<c00a3420>] out_of_memory+0xc8/0x3a4
[ 5201.383378] [<c00a80e4>] __alloc_pages_nodemask+0x67c/0xb14
[ 5201.390207] [<c009f494>] filemap_fault+0x378/0x5e4
[ 5201.396241] [<c00ca960>] __do_fault+0x48/0x100
[ 5201.401922] [<c00cebe8>] handle_mm_fault+0x810/0xa38
[ 5201.408167] [<c0027978>] do_page_fault+0x104/0x3a8
[ 5201.414173] [<c00254ec>] ret_from_exception+0x0/0x10
[ 5201.428377] Mem-Info:
[ 5201.432976] active_anon:142 inactive_anon:2 isolated_anon:0
[ 5201.432976]  active_file:0 inactive_file:0 isolated_file:9
[ 5201.432976]  unevictable:0 dirty:0 writeback:0 unstable:0
[ 5201.432976]  slab_reclaimable:41 slab_unreclaimable:605
[ 5201.432976]  mapped:1 shmem:2 pagetables:33 bounce:0
[ 5201.432976]  free:62 free_pcp:0 free_cma:0
[ 5201.470622] Node 0 active_anon:568kB inactive_anon:8kB active_file:0kB inactive_file:0kB unevictable:0kB isolated(anon):0kB isolated(file):36kB mapped:4kB dirty:0kB writeback:0kB shmem:8kB writeback_tmp:0kB unstable:0kB all_unreclaimable? no
[ 5201.498214] Normal free:248kB min:256kB low:320kB high:384kB active_anon:568kB inactive_anon:8kB active_file:0kB inactive_file:0kB unevictable:0kB writepending:0kB present:8192kB managed:4280kB mlocked:0kB kernel_stack:280kB pagetables:132kB bounce:0kB free_pcp:0kB local_pcp:0kB free_cma:0kB
[ 5201.529862] lowmem_reserve[]: 0 0
[ 5201.536073] Normal: 0*4kB 1*8kB (U) 1*16kB (U) 1*32kB (U) 1*64kB (U) 1*128kB (U) 0*256kB 0*512kB 0*1024kB 0*2048kB 0*4096kB = 248kB
[ 5201.553244] 12 total pagecache pages
[ 5201.558556] 0 pages in swap cache
[ 5201.564229] Swap cache stats: add 0, delete 0, find 0/0
[ 5201.572420] Free swap  = 0kB
[ 5201.576911] Total swap = 0kB
[ 5201.581428] 2048 pages RAM
[ 5201.585728] 0 pages HighMem/MovableOnly
[ 5201.592111] 978 pages reserved
[ 5201.596784] Unreclaimable slab info:
[ 5201.602000] Name                      Used          Total
[ 5201.609760] request_queue             15KB         15KB
[ 5201.617378] biovec-max                30KB         30KB
[ 5201.624973] biovec-64                  7KB          7KB
[ 5201.632467] shmem_inode_cache        202KB        202KB
[ 5201.640058] proc_dir_entry             8KB          8KB
[ 5201.647272] seq_file                   3KB          3KB
[ 5201.656181] sigqueue                   3KB          3KB
[ 5201.664263] kernfs_node_cache        622KB        622KB
[ 5201.672283] filp                      11KB         11KB
[ 5201.680294] names_cache               32KB         32KB
[ 5201.688334] vm_area_struct            19KB         19KB
[ 5201.696339] mm_struct                  7KB          7KB
[ 5201.704340] signal_cache              22KB         22KB
[ 5201.712346] sighand_cache             47KB         47KB
[ 5201.720350] task_struct               68KB         68KB
[ 5201.728229] cred_jar                   8KB          8KB
[ 5201.736259] anon_vma_chain            12KB         12KB
[ 5201.744251] anon_vma                   7KB          7KB
[ 5201.752249] pid                        4KB          4KB
[ 5201.760246] pool_workqueue             8KB          8KB
[ 5201.768314] kmalloc-8k                32KB         32KB
[ 5201.776329] kmalloc-4k               800KB        800KB
[ 5201.784349] kmalloc-2k                16KB         16KB
[ 5201.792254] kmalloc-1k                40KB         40KB
[ 5201.800269] kmalloc-512               24KB         24KB
[ 5201.808265] kmalloc-256              168KB        168KB
[ 5201.816269] kmalloc-192                7KB          7KB
[ 5201.824278] kmalloc-128                8KB          8KB
[ 5201.832295] kmalloc-96                70KB         70KB
[ 5201.840292] kmalloc-64                20KB         20KB
[ 5201.848283] kmalloc-32                 8KB          8KB
[ 5201.856185] kmalloc-16                 8KB          8KB
[ 5201.864223] kmalloc-8                 24KB         24KB
[ 5201.872253] kmem_cache_node            4KB          4KB
[ 5201.880268] kmem_cache                15KB         15KB
[ 5201.888130] Tasks state (memory values in pages):
[ 5201.894649] [  pid  ]   uid  tgid total_vm      rss pgtables_bytes swapents oom_score_adj name
[ 5201.906500] [     38]     0    38      662       21    12288        0             0 rcS
[ 5201.917593] [     50]     0    50      663       20    12288        0             0 klogd
[ 5201.929003] [     52]     0    52      663       19    12288        0             0 S02sysctl
[ 5201.940805] [     57]     0    57      663       20    12288        0             0 S02sysctl
[ 5201.952594] [     58]     0    58      663       20    12288        0             0 S02sysctl
[ 5201.964289] [     59]     0    59      663       20    12288        0             0 S02sysctl
[ 5201.976411] [     60]     0    60      663       20    12288        0             0 S02sysctl
[ 5201.988227] [     61]     0    61      663       20    12288        0             0 S02sysctl
[ 5202.000454] [     63]     0    63      663       20    12288        0             0 S02sysctl
[ 5202.012205] [     64]     0    64      663       20    12288        0             0 S02sysctl
[ 5202.024114] oom-kill:constraint=CONSTRAINT_NONE,nodemask=(null),task=rcS,pid=38,uid=0
[ 5202.034788] Out of memory: Kill process 38 (rcS) score 22 or sacrifice child
[ 5202.045438] Killed process 52 (S02sysctl) total-vm:2652kB, anon-rss:76kB, file-rss:0kB, shmem-rss:0kB
[ 5202.691116] oom_reaper: reaped process 52 (S02sysctl), now anon-rss:0kB, file-rss:0kB, shmem-rss:0kB

setenv bootargs rootwait console=hvc0 earlycon=sbi root=/dev/mmcblk0p2 init=/linuxrc mmc_core.use_spi_crc=0 loglevel=7