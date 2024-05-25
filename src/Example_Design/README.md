# Example Design

This directory contains the source files needed for a complete Example Design for the
MEGA65 revision 6 hardware platform.

The are two different ways to build the design.
* Batch mode : Type `make` will generate a `tcl` script and start Vivado in non-project
  mode.
* GUI mode : Start Vivado and open the project file `sdram_mega65r6.xpr`.

The source files are grouped as follows:

* sdram\_mega65r6.vhd : Top level file
* mega65r6.xdc : Constraint file for the MEGA65 R6 board.
* core\_wrapper.vhd : Contains SDRAM controller and RAM test
* mega65\_wrapper.vhd : Contains generic MEGA65 platform code.
* controller\_wrapper.vhd : Interfaces between the core and the mega65.

The non-project flow additionally uses `debug.tcl`, which is a useful helper script when
debugging using Vivado's ILA.

