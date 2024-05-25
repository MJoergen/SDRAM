# Simulation is done using the program ghdl. It may be available
# in your OS repository, otherwise it may be downloaded from here:
# https://github.com/ghdl/ghdl

XILINX_DIR = /opt/Xilinx/Vivado/2023.1
XPM_DIR = ../../../../fransschreuder/xpm_vhdl

#PROJECT = sdram_mega65r6
PROJECT = sdram

TB       = tb_$(PROJECT)
SOURCES += ../Example_Design/core/avm_decrease.vhd
SOURCES += ../Example_Design/core/avm_master3.vhd
SOURCES += ../Example_Design/core/avm_pause.vhd
SOURCES += ../Example_Design/core/avm_verifier.vhd
SOURCES += ../Example_Design/core/bytewrite_tdp_ram_wf.vhd
SOURCES += ../Example_Design/core/lfsr.vhd
SOURCES += ../Example_Design/core/random.vhd
SOURCES += ../Example_Design/core/trafic_gen.vhd
SOURCES += ../Example_Design/core_wrapper.vhd
SOURCES += ../Example_Design/controller/axi_merger.vhd
SOURCES += ../Example_Design/controller/merginator.vhd
SOURCES += ../Example_Design/controller/serializer.vhd
SOURCES += ../Example_Design/controller_wrapper.vhd
SOURCES += ../Example_Design/sdram_mega65r6.vhd
SOURCES += ../Example_Design/mega65/clk.vhd
SOURCES += ../Example_Design/mega65/uart/uart.vhd
SOURCES += ../Example_Design/mega65/video/font.vhd
SOURCES += ../Example_Design/mega65/video/video_chars.vhd
SOURCES += ../Example_Design/mega65/video/video_modes_pkg.vhd
SOURCES += ../Example_Design/mega65/video/video_sync.vhd
SOURCES += ../Example_Design/mega65/video_wrapper.vhd
SOURCES += ../Example_Design/mega65/keyboard/kb_matrix_ram.vhd
SOURCES += ../Example_Design/mega65/keyboard/m2m_keyb.vhd
SOURCES += ../Example_Design/mega65/keyboard/matrix_to_keynum.vhd
SOURCES += ../Example_Design/mega65/keyboard/mega65kbd_to_matrix.vhd
SOURCES += ../Example_Design/mega65/keyboard_wrapper.vhd
SOURCES += ../Example_Design/mega65_wrapper.vhd
SOURCES += ../sdram/sdram.vhd
SOURCES += sdram_sim.vhd
SOURCES += $(TB).vhd
SAVE     = $(TB).gtkw
WAVE     = $(TB).ghw


#####################################
# Simulation
#####################################

.PHONY: sim
sim: $(SOURCES) unisim-obj08.cf xpm-obj08.cf
	ghdl -i --std=08 -frelaxed-rules -fsynopsys $(SOURCES)
	ghdl -m --std=08 -frelaxed-rules -fsynopsys $(TB)
	ghdl -r --std=08 -frelaxed-rules -fsynopsys $(TB) $(GENERICS) --wave=$(WAVE) --stop-time=20us

unisim-obj08.cf:
	ghdl -i --std=08 --work=unisim -frelaxed-rules -fsynopsys $(XILINX_DIR)/data/vhdl/src/unisims/unisim_VCOMP.vhd
	ghdl -i --std=08 --work=unisim -frelaxed-rules -fsynopsys $(XILINX_DIR)/data/vhdl/src/unisims/unisim_VPKG.vhd
	ghdl -i --std=08 --work=unisim -frelaxed-rules -fsynopsys $(XILINX_DIR)/data/vhdl/src/unisims/primitive/*.vhd

xpm-obj08.cf:
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_VCOMP.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_cdc/hdl/xpm_cdc_single.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_cdc/hdl/xpm_cdc_array_single.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_cdc/hdl/xpm_cdc_async_rst.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_cdc/hdl/xpm_cdc_gray.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_cdc/hdl/xpm_cdc_handshake.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_cdc/hdl/xpm_cdc_low_latency_handshake.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_cdc/hdl/xpm_cdc_pulse.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_cdc/hdl/xpm_cdc_sync_rst.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_memory/hdl/xpm_memory_base.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_memory/hdl/xpm_memory_dpdistram.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_memory/hdl/xpm_memory_dprom.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_memory/hdl/xpm_memory_sdpram.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_memory/hdl/xpm_memory_spram.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_memory/hdl/xpm_memory_sprom.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_memory/hdl/xpm_memory_tdpram.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_fifo/hdl/xpm_fifo_rst.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_fifo/hdl/xpm_fifo_reg_bit.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_fifo/hdl/xpm_counter_updn.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_fifo/hdl/xpm_fifo_reg_vec.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_fifo/hdl/xpm_reg_pipe_bit.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_fifo/hdl/xpm_fifo_base.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_fifo/hdl/xpm_fifo_async.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_fifo/hdl/xpm_fifo_axi_reg_slice.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_fifo/hdl/xpm_fifo_axif.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_fifo/hdl/xpm_fifo_axil.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_fifo/hdl/xpm_fifo_axis.vhd
	ghdl -i --std=08 --work=xpm ${XPM_DIR}/src/xpm/xpm_fifo/hdl/xpm_fifo_sync.vhd


$WAVE): sim

show: $(WAVE) $(SAVE)
	gtkwave $(WAVE) $(SAVE)


#####################################
# Cleanup
#####################################

clean:
	rm -rf *.o
	rm -rf work-obj08.cf
	rm -rf unisim-obj08.cf
	rm -rf xpm-obj08.cf
	rm -rf $(TB)
	rm -rf $(WAVE)

