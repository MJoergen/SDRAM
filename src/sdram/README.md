# SDRAM controller

All files necessary for the SDRAM controller are in this directory.

## Architecture

The controller connects to the SDRAM device and to the internal FPGA design.
The internal FPGA interface is using the Avalon Memory Map protocol.
You have to supply a 166 MHz (or slower) clock to this module. The controller
runs in one clock domain only.

