import_device eagle_s20.db -package BG256

read_verilog top.v TangSmpLinux.v -top top

read_sdc sdc.sdc
read_adc adc.adc
optimize_rtl
map_macro
map
pack
place
route
report_area -io_info -file top_phy.area
bitgen -bit top.bit -version 0X0000 -svf top.svf -svf_comment_on -g ucode:00000000000000000000000000000000