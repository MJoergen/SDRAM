# Signal mapping for MEGA65 platform revision 6
#
# Created by Michael Jørgensen in 2024 (mjoergen.github.io/SDRAM).


#############################################################################################################
# Pin locations and I/O standards
#############################################################################################################

# Onboard crystal oscillator = 100 MHz
set_property -dict {PACKAGE_PIN V13  IOSTANDARD LVCMOS33} [get_ports {sys_clk_i}];              # CLOCK_FPGA_MRCC

# Reset button on the side of the machine
set_property -dict {PACKAGE_PIN J19  IOSTANDARD LVCMOS33} [get_ports {sys_rst_i}];              # RESET

# SDRAM - 32M x 16 bit, 3.3V VCC. U44 = IS42S16320F-6BL
set_property -dict {PACKAGE_PIN T4   IOSTANDARD LVCMOS33} [get_ports {sdram_a_o[0]}];           # SDRAM_A0
set_property -dict {PACKAGE_PIN R2   IOSTANDARD LVCMOS33} [get_ports {sdram_a_o[1]}];           # SDRAM_A1
set_property -dict {PACKAGE_PIN R3   IOSTANDARD LVCMOS33} [get_ports {sdram_a_o[2]}];           # SDRAM_A2
set_property -dict {PACKAGE_PIN T3   IOSTANDARD LVCMOS33} [get_ports {sdram_a_o[3]}];           # SDRAM_A3
set_property -dict {PACKAGE_PIN Y4   IOSTANDARD LVCMOS33} [get_ports {sdram_a_o[4]}];           # SDRAM_A4
set_property -dict {PACKAGE_PIN W6   IOSTANDARD LVCMOS33} [get_ports {sdram_a_o[5]}];           # SDRAM_A5
set_property -dict {PACKAGE_PIN W4   IOSTANDARD LVCMOS33} [get_ports {sdram_a_o[6]}];           # SDRAM_A6
set_property -dict {PACKAGE_PIN U7   IOSTANDARD LVCMOS33} [get_ports {sdram_a_o[7]}];           # SDRAM_A7
set_property -dict {PACKAGE_PIN AA8  IOSTANDARD LVCMOS33} [get_ports {sdram_a_o[8]}];           # SDRAM_A8
set_property -dict {PACKAGE_PIN Y2   IOSTANDARD LVCMOS33} [get_ports {sdram_a_o[9]}];           # SDRAM_A9
set_property -dict {PACKAGE_PIN R6   IOSTANDARD LVCMOS33} [get_ports {sdram_a_o[10]}];          # SDRAM_A10
set_property -dict {PACKAGE_PIN Y7   IOSTANDARD LVCMOS33} [get_ports {sdram_a_o[11]}];          # SDRAM_A11
set_property -dict {PACKAGE_PIN Y9   IOSTANDARD LVCMOS33} [get_ports {sdram_a_o[12]}];          # SDRAM_A12
set_property -dict {PACKAGE_PIN U3   IOSTANDARD LVCMOS33} [get_ports {sdram_ba_o[0]}];          # SDRAM_BA0
set_property -dict {PACKAGE_PIN R4   IOSTANDARD LVCMOS33} [get_ports {sdram_ba_o[1]}];          # SDRAM_BA1
set_property -dict {PACKAGE_PIN V3   IOSTANDARD LVCMOS33} [get_ports {sdram_cas_n_o}];          # SDRAM_CAS#
set_property -dict {PACKAGE_PIN U5   IOSTANDARD LVCMOS33} [get_ports {sdram_cke_o}];            # SDRAM_CKE
set_property -dict {PACKAGE_PIN V8   IOSTANDARD LVCMOS33} [get_ports {sdram_clk_o}];            # SDRAM_CLK
set_property -dict {PACKAGE_PIN G3   IOSTANDARD LVCMOS33} [get_ports {sdram_cs_n_o}];           # SDRAM_CS#
set_property -dict {PACKAGE_PIN V5   IOSTANDARD LVCMOS33} [get_ports {sdram_dq_io[0]}];         # SDRAM_DQ0
set_property -dict {PACKAGE_PIN AA4  IOSTANDARD LVCMOS33} [get_ports {sdram_dq_io[10]}];        # SDRAM_DQ10
set_property -dict {PACKAGE_PIN V7   IOSTANDARD LVCMOS33} [get_ports {sdram_dq_io[11]}];        # SDRAM_DQ11
set_property -dict {PACKAGE_PIN AA6  IOSTANDARD LVCMOS33} [get_ports {sdram_dq_io[12]}];        # SDRAM_DQ12
set_property -dict {PACKAGE_PIN W5   IOSTANDARD LVCMOS33} [get_ports {sdram_dq_io[13]}];        # SDRAM_DQ13
set_property -dict {PACKAGE_PIN AB6  IOSTANDARD LVCMOS33} [get_ports {sdram_dq_io[14]}];        # SDRAM_DQ14
set_property -dict {PACKAGE_PIN Y3   IOSTANDARD LVCMOS33} [get_ports {sdram_dq_io[15]}];        # SDRAM_DQ15
set_property -dict {PACKAGE_PIN T1   IOSTANDARD LVCMOS33} [get_ports {sdram_dq_io[1]}];         # SDRAM_DQ1
set_property -dict {PACKAGE_PIN V4   IOSTANDARD LVCMOS33} [get_ports {sdram_dq_io[2]}];         # SDRAM_DQ2
set_property -dict {PACKAGE_PIN U2   IOSTANDARD LVCMOS33} [get_ports {sdram_dq_io[3]}];         # SDRAM_DQ3
set_property -dict {PACKAGE_PIN V2   IOSTANDARD LVCMOS33} [get_ports {sdram_dq_io[4]}];         # SDRAM_DQ4
set_property -dict {PACKAGE_PIN U1   IOSTANDARD LVCMOS33} [get_ports {sdram_dq_io[5]}];         # SDRAM_DQ5
set_property -dict {PACKAGE_PIN U6   IOSTANDARD LVCMOS33} [get_ports {sdram_dq_io[6]}];         # SDRAM_DQ6
set_property -dict {PACKAGE_PIN T6   IOSTANDARD LVCMOS33} [get_ports {sdram_dq_io[7]}];         # SDRAM_DQ7
set_property -dict {PACKAGE_PIN W7   IOSTANDARD LVCMOS33} [get_ports {sdram_dq_io[8]}];         # SDRAM_DQ8
set_property -dict {PACKAGE_PIN AA3  IOSTANDARD LVCMOS33} [get_ports {sdram_dq_io[9]}];         # SDRAM_DQ9
set_property -dict {PACKAGE_PIN Y6   IOSTANDARD LVCMOS33} [get_ports {sdram_dqmh_o}];           # SDRAM_DQMH
set_property -dict {PACKAGE_PIN W2   IOSTANDARD LVCMOS33} [get_ports {sdram_dqml_o}];           # SDRAM_DQML
set_property -dict {PACKAGE_PIN T5   IOSTANDARD LVCMOS33} [get_ports {sdram_ras_n_o}];          # SDRAM_RAS#
set_property -dict {PACKAGE_PIN G1   IOSTANDARD LVCMOS33} [get_ports {sdram_we_n_o}];           # SDRAM_WE#
set_property -dict {PULLUP FALSE  SLEW FAST  DRIVE 16}    [get_ports {sdram_*}];

# USB-RS232 Interface
set_property -dict {PACKAGE_PIN L14  IOSTANDARD LVCMOS33} [get_ports {uart_rx_i}];              # DBG_UART_RX
set_property -dict {PACKAGE_PIN L13  IOSTANDARD LVCMOS33} [get_ports {uart_tx_o}];              # DBG_UART_TX

# VGA via VDAC. U3 = ADV7125BCPZ170
set_property -dict {PACKAGE_PIN W11  IOSTANDARD LVCMOS33} [get_ports {vdac_blank_n_o}];         # VDAC_BLANK_N
set_property -dict {PACKAGE_PIN AA9  IOSTANDARD LVCMOS33} [get_ports {vdac_clk_o}];             # VDAC_CLK
set_property -dict {PACKAGE_PIN W16  IOSTANDARD LVCMOS33} [get_ports {vdac_psave_n_o}];         # VDAC_PSAVE_N
set_property -dict {PACKAGE_PIN V10  IOSTANDARD LVCMOS33} [get_ports {vdac_sync_n_o}];          # VDAC_SYNC_N
set_property -dict {PACKAGE_PIN W10  IOSTANDARD LVCMOS33} [get_ports {vga_blue_o[0]}];          # B0
set_property -dict {PACKAGE_PIN Y12  IOSTANDARD LVCMOS33} [get_ports {vga_blue_o[1]}];          # B1
set_property -dict {PACKAGE_PIN AB12 IOSTANDARD LVCMOS33} [get_ports {vga_blue_o[2]}];          # B2
set_property -dict {PACKAGE_PIN AA11 IOSTANDARD LVCMOS33} [get_ports {vga_blue_o[3]}];          # B3
set_property -dict {PACKAGE_PIN AB11 IOSTANDARD LVCMOS33} [get_ports {vga_blue_o[4]}];          # B4
set_property -dict {PACKAGE_PIN Y11  IOSTANDARD LVCMOS33} [get_ports {vga_blue_o[5]}];          # B5
set_property -dict {PACKAGE_PIN AB10 IOSTANDARD LVCMOS33} [get_ports {vga_blue_o[6]}];          # B6
set_property -dict {PACKAGE_PIN AA10 IOSTANDARD LVCMOS33} [get_ports {vga_blue_o[7]}];          # B7
set_property -dict {PACKAGE_PIN Y14  IOSTANDARD LVCMOS33} [get_ports {vga_green_o[0]}];         # G0
set_property -dict {PACKAGE_PIN W14  IOSTANDARD LVCMOS33} [get_ports {vga_green_o[1]}];         # G1
set_property -dict {PACKAGE_PIN AA15 IOSTANDARD LVCMOS33} [get_ports {vga_green_o[2]}];         # G2
set_property -dict {PACKAGE_PIN AB15 IOSTANDARD LVCMOS33} [get_ports {vga_green_o[3]}];         # G3
set_property -dict {PACKAGE_PIN Y13  IOSTANDARD LVCMOS33} [get_ports {vga_green_o[4]}];         # G4
set_property -dict {PACKAGE_PIN AA14 IOSTANDARD LVCMOS33} [get_ports {vga_green_o[5]}];         # G5
set_property -dict {PACKAGE_PIN AA13 IOSTANDARD LVCMOS33} [get_ports {vga_green_o[6]}];         # G6
set_property -dict {PACKAGE_PIN AB13 IOSTANDARD LVCMOS33} [get_ports {vga_green_o[7]}];         # G7
set_property -dict {PACKAGE_PIN W12  IOSTANDARD LVCMOS33} [get_ports {vga_hs_o}];               # HSYNC
set_property -dict {PACKAGE_PIN U15  IOSTANDARD LVCMOS33} [get_ports {vga_red_o[0]}];           # R0
set_property -dict {PACKAGE_PIN V15  IOSTANDARD LVCMOS33} [get_ports {vga_red_o[1]}];           # R1
set_property -dict {PACKAGE_PIN T14  IOSTANDARD LVCMOS33} [get_ports {vga_red_o[2]}];           # R2
set_property -dict {PACKAGE_PIN Y17  IOSTANDARD LVCMOS33} [get_ports {vga_red_o[3]}];           # R3
set_property -dict {PACKAGE_PIN Y16  IOSTANDARD LVCMOS33} [get_ports {vga_red_o[4]}];           # R4
set_property -dict {PACKAGE_PIN AB17 IOSTANDARD LVCMOS33} [get_ports {vga_red_o[5]}];           # R5
set_property -dict {PACKAGE_PIN AA16 IOSTANDARD LVCMOS33} [get_ports {vga_red_o[6]}];           # R6
set_property -dict {PACKAGE_PIN AB16 IOSTANDARD LVCMOS33} [get_ports {vga_red_o[7]}];           # R7
set_property -dict {PACKAGE_PIN V14  IOSTANDARD LVCMOS33} [get_ports {vga_vs_o}];               # VSYNC

# HDMI output
set_property -dict {PACKAGE_PIN Y1   IOSTANDARD TMDS_33}  [get_ports {hdmi_clk_n_o}]
set_property -dict {PACKAGE_PIN W1   IOSTANDARD TMDS_33}  [get_ports {hdmi_clk_p_o}]
set_property -dict {PACKAGE_PIN AB1  IOSTANDARD TMDS_33}  [get_ports {hdmi_data_n_o[0]}]
set_property -dict {PACKAGE_PIN AA1  IOSTANDARD TMDS_33}  [get_ports {hdmi_data_p_o[0]}]
set_property -dict {PACKAGE_PIN AB2  IOSTANDARD TMDS_33}  [get_ports {hdmi_data_n_o[1]}]
set_property -dict {PACKAGE_PIN AB3  IOSTANDARD TMDS_33}  [get_ports {hdmi_data_p_o[1]}]
set_property -dict {PACKAGE_PIN AB5  IOSTANDARD TMDS_33}  [get_ports {hdmi_data_n_o[2]}]
set_property -dict {PACKAGE_PIN AA5  IOSTANDARD TMDS_33}  [get_ports {hdmi_data_p_o[2]}]

## Keyboard interface (connected to MAX10)
set_property -dict {PACKAGE_PIN A14  IOSTANDARD LVCMOS33} [get_ports {kb_io0_o}];               # KB_IO1
set_property -dict {PACKAGE_PIN A13  IOSTANDARD LVCMOS33} [get_ports {kb_io1_o}];               # KB_IO2
set_property -dict {PACKAGE_PIN C13  IOSTANDARD LVCMOS33} [get_ports {kb_io2_i}];               # KB_IO3


################################
## TIMING CONSTRAINTS
################################

## System board clock (100 MHz)
create_clock -period 10.000 -name sys_clk [get_ports {sys_clk_i}]

## Name Autogenerated Clocks
create_generated_clock -name ctrl_clk  [get_pins mega65_wrapper_inst/clk_inst/plle2_base_inst/CLKOUT0];      # 166.67 MHz
create_generated_clock -name video_clk [get_pins mega65_wrapper_inst/clk_inst/mmcme2_base_inst/CLKOUT0];     #  74.25 MHz
create_generated_clock -name hdmi_clk  [get_pins mega65_wrapper_inst/clk_inst/mmcme2_base_inst/CLKOUT1];     # 371.25 MHz


################################
## Placement constraints
################################

# Place KBD close to I/O pins
startgroup
create_pblock pblock_keyboard
resize_pblock pblock_keyboard -add {SLICE_X0Y225:SLICE_X7Y237}
add_cells_to_pblock pblock_keyboard [get_cells [list mega65_wrapper_inst/keyboard_wrapper_inst/m2m_keyb_inst]]
endgroup


#############################################################################################################
# Configuration and Bitstream properties
#############################################################################################################

set_property CONFIG_VOLTAGE                  3.3   [current_design]
set_property CFGBVS                          VCCO  [current_design]
set_property BITSTREAM.GENERAL.COMPRESS      TRUE  [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE     66    [current_design]
set_property CONFIG_MODE                     SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES   [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH   4     [current_design]

