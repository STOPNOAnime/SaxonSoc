# This file is generated by Anlogic Timing Wizard. 05 01 2021

#Created Clock
create_clock -name MainClk -period 42 -waveform {0 21} [get_ports {MainClk}] -add
create_clock -name jtag_tck -period 250 -waveform {0 125} [get_ports {jtag_tck}] -add

