#
#	Makefile for ModelSim simulation
#


PATMOSDIR=../vhdl
SDRAMDIR=../../sdram/vhdl
#OPTIONS=-93 -quiet -check_synthesis -lint -pedanticerrors
OPTIONS=-93 -quiet

ifeq ($(WINDIR),)
	S=:
else
	S=\;
endif

# Use Wine on OSX
# I would like to use a better way, but some shell variables
# are not set within make.... Don't know why...
ifeq ($(TERM_PROGRAM),Apple_Terminal)
	WINE=wine
else
	WINE=
endif


all: clean base
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/core/patmos_testbench.vhd
	$(WINE) vsim -do sim.do patmos_testbench

batch: clean base
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/core/patmos_testbench.vhd
	$(WINE) vsim -c -do batch.do patmos_testbench

# MS: SDRAM shall not be the base of Patmos
base:
	$(WINE) vlib work
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/top/patmos_config_global.vhd
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/top/patmos_config_ml605.vhd
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/top/patmos_config_de2.vhd
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/core/patmos_type_package.vhd
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/core/sc_pack.vhd
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/generated/patmos_rom.vhd
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/core/patmos_register_file.vhd
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/core/patmos_alu.vhd
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/core/patmos_data_memory.vhd
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/core/patmos_stack_cache.vhd
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/io/uart.vhd
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/core/patmos_fetch.vhd
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/core/patmos_decode.vhd
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/core/patmos_mem_stage.vhd
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/core/patmos_stack_cache.vhd
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/core/patmos_core.vhd
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/core/patmos_io.vhd
	$(WINE) vcom $(OPTIONS) $(PATMOSDIR)/core/patmos.vhd


todo_build_a_sdram_version:
	$(WINE) vcom $(OPTIONS) $(SDRAMDIR)/sdram_controller_interface.vhd
	$(WINE) vcom $(OPTIONS) $(SDRAMDIR)/sdram_config.vhd
	$(WINE) vcom $(OPTIONS) $(SDRAMDIR)/sdram_config-IS42S16160B-7TLI.vhd
	$(WINE) vcom $(OPTIONS) $(SDRAMDIR)/sdr_dram.vhd
	$(WINE) vcom $(OPTIONS) $(SDRAMDIR)/../simulation/mt48lc2m32b2_2.vhd


clean:
	-rm -f transcript
	-rm -f *.wlf
	-rm -rf work

