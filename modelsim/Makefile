#
#	Makefile for ModelSim simulation
#


PATMOSDIR=../vhdl
#OPTIONS=-93 -quiet -check_synthesis -lint -pedanticerrors
OPTIONS=-93 -quiet

ifeq ($(WINDIR),)
	WINE=wine
	S=:
else
	WINE=
	S=\;
endif

all: clean base
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/core/patmos_testbench.vhd
	$(WINE) vsim -do sim.do pc_tester

base:
	$(WINE) vlib work
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/core/patmos_type_package.vhd
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/core/patmos_register_file.vhd
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/core/patmos_pc_generator.vhd
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/core/patmos_clock_input.vhd
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/core/patmos_fetch.vhd
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/core/patmos_decode.vhd
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/core/patmos_execute.vhd
clean:
	-rm *.wlf
