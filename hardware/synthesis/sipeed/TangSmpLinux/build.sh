#!/bin/bash
TD_HOME=/opt/TD
set -ex

cp ../../netlist/TangLinux* .
#cp ../../../software/standalone/machineModeSbi/build/machineModeSbi.bin .

$TD_HOME/bin/td build.tcl
