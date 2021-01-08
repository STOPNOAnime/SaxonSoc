import_device eagle_s20.db -package BG256

read_verilog top.v TangLinux.v -top top

read_sdc sdc.adc
read_adc adc.adc
optimize_rtl
map_macro
map
pack
place
route
report_area -io_info -file top_phy.area
bitgen -bit top.bit -version 0X0000 -svf top.svf -svf_comment_on -g ucode:00000000000000000000000000000000

#download -bit top.bit
download -mode program_spi -bit top.bit
