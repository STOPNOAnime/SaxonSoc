#!/bin/sh


# cleanup
rm -rf obj_dir
rm -f  wave.vcd
rm -f TangSmpLinux*
cp ../../../../netlist/TangSmpLinux* .

# run Verilator to translate Verilog into C++, include C++ testbench
verilator -Wall --cc --trace  top.v TangSmpLinux.v --exe tb.cpp
# build C++ project
make -j -C obj_dir/ -f Vtop.mk
# run executable simulation
obj_dir/Vtop
# view waveforms
gtkwave wave.vcd wave.sav &
