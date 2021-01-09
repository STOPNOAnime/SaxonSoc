#ROOT shall point to location of build.sbt
ROOT=../../../..

TOP=TangSmpLinux
TOPV=../../../netlist/$(TOP).v

all : build/latest.bit

build/latest.bit : adc.adc sdc.sdc top.v $(TOPV)
	./make_project

flash : build/latest.bit
	./write_flash

.PHONY: clean
clean :
	@rm -rf build
