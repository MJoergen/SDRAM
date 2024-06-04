# This Makefile is used to build the complete Example Design for the MEGA65 R6 platform
# To build, just type `make`.

XILINX_DIR = /opt/Xilinx/Vivado/2023.1

PROJECT = sdram
PLATFORM = mega65r6
PART = xc7a200tfbg484-2

TOP = $(PROJECT)_$(PLATFORM)

SRCS  = $(TOP).vhd
SRCS += core/avm_decrease.vhd
SRCS += core/avm_master3.vhd
SRCS += core/avm_pause.vhd
SRCS += core/avm_verifier.vhd
SRCS += core/bytewrite_tdp_ram_wf.vhd
SRCS += core/lfsr.vhd
SRCS += core/random.vhd
SRCS += core/trafic_gen.vhd
SRCS += core_wrapper.vhd
SRCS += controller/axi_merger.vhd
SRCS += controller/merginator.vhd
SRCS += controller/serializer.vhd
SRCS += controller_wrapper.vhd
SRCS += mega65/clk.vhd
SRCS += mega65/uart/uart.vhd
SRCS += mega65/video/font.vhd
SRCS += mega65/video/video_chars.vhd
SRCS += mega65/video/video_modes_pkg.vhd
SRCS += mega65/video/video_sync.vhd
SRCS += mega65/video_wrapper.vhd
SRCS += mega65/keyboard/kb_matrix_ram.vhd
SRCS += mega65/keyboard/m2m_keyb.vhd
SRCS += mega65/keyboard/matrix_to_keynum.vhd
SRCS += mega65/keyboard/mega65kbd_to_matrix.vhd
SRCS += mega65/keyboard_wrapper.vhd
SRCS += mega65_wrapper.vhd
SRCS += ../sdram/sdram.vhd

XDC = $(PLATFORM).xdc

$(TOP).bit: $(TOP).tcl $(SRCS) $(XDC) Makefile
	bash -c "source $(XILINX_DIR)/settings64.sh ; vivado -mode tcl -source $<"

$(TOP).tcl: Makefile
	echo "# This is an auto-generated tcl command script for the Vivado tool chain" > $@
	echo "read_vhdl -vhdl2008 { $(SRCS) }" >> $@
	echo "read_xdc $(XDC)" >> $@
	echo "set_property XPM_LIBRARIES {XPM_CDC XPM_FIFO} [current_project]" >> $@
	echo "synth_design -top $(TOP) -part $(PART) -flatten_hierarchy none $(GENERICS)" >> $@
	echo "write_checkpoint -force post_synth.dcp" >> $@
	echo "source debug.tcl" >> $@
	echo "opt_design" >> $@
	echo "place_design" >> $@
	echo "phys_opt_design" >> $@
	echo "route_design" >> $@
	echo "write_checkpoint -force $(TOP).dcp" >> $@
	echo "write_bitstream -force $(TOP).bit" >> $@
	echo "exit" >> $@

clean:
	rm -rf usage_statistics_webtalk.*
	rm -rf vivado*
	rm -rf post_synth.dcp
	rm -rf .Xil
	rm -rf .cache
	rm -rf debug.ltx
	rm -rf $(TOP).tcl
	rm -rf $(TOP).bit
	rm -rf $(TOP).dcp
	rm -rf $(TOP).cache
	rm -rf $(TOP).hw
	rm -rf $(TOP).runs
	rm -rf $(TOP).srcs

