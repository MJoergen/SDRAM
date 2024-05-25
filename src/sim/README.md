# Simulation files

This directory contains testbenches and simulation models for testing the SDRAM
controller.

The main files in this directory are:
* sdram\_sim.vhd : Simulation model of an SDRAM device
* tb\_sdram.vhd : Testbench for the SDRAM controller
* tb\_sdram.gtkw : Configuration for gtkwave.
* Makefile : Convenient way to run the simulation

To run the simulation, simply type `make`. To view the results in gtkwave, type `make
show`.

The testbench instantiates the SDRAM controller and the SDRAM simulation model, as well as
a RAM test generator.

Additionally, the following files are provided as well
* tb\_sdram\_mega65r6.vhd : Testbench for the complete example design
* tb\_sdram\_mega65r6.gtkw : Configuration for gtkwave.

