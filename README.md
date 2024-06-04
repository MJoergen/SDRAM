# SDRAM

This repository contains a portable open-source SDRAM controller for FPGAs written in VHDL.
I'm writing my own implementation because I've looked at several other implementations, and
they all seemed lacking in various regards (features, stability, portability, etc.)

The SDRAM controller in this repository is a complete rewrite from scratch,
and is provided with a [MIT license](LICENSE).

Learn more by reading the documentation in this repository or by browsing the companion
website: https://mjoergen.github.io/SDRAM/

## Features

This implementation has support for:

* Maximum SDRAM clock speed of 166 MHz.
* 16-bit [Avalon Memory Map interface](doc/Avalon_Interface_Specifications.pdf).
* Written for VHDL-2008.

Currently, burst mode is not supported.

All the source files for the SDRAM controller are in the
[src/sdram](src/sdram) directory, and all files needed for simulation are
in the [src/sim](src/sim) directory.

Porting to another platform may require hand-tuning of some clock parameters,
see the section on [porting](PORTING.md).

## Example Design

I'm testing this SDRAM controller on the [MEGA65](https://mega65.org/)
hardware platform (Revision 6).  It contains the 64 MB SDRAM chip ([link to
datasheet](doc/66-67WVH8M8ALL-BLL-938852.pdf)) from ISSI (Integrated Silicon
Solution Inc.).  Specifically, the part number of the SDRAM device on the
MEGA65 is `IS42S16320F-6BL`.

I've written a complete Example Design to test the SDRAM controller on this
MEGA65 platform. The additional source files needed for this are placed in the
[src/Example_Design](src/Example_Design) directory.

## Getting started

The [SDRAM controller](src/sdram/sdram.vhd) has just two interfaces,
one for the external SDRAM device and one for the client (user) of the
SDRAM. For the client interface I've chosen the [Avalon Memory
Map](doc/Avalon_Interface_Specifications.pdf) protocol. This is an industry
standard and is easy to use. The interface width is 16 bits corresponding to
one word of the SDRAM. The addressing is in units of words, not bytes.

The Avalon interface supports burst mode, where you can read or write multiple
words in a single SDRAM transaction. Section 3.5.5 in the Avalon Memory Map
specification describes burst mode in detail.

To see an example of how to use the SDRAM controller and how to connect it
to the internal FPGA logic and to the external SDRAM device, have a look at
the [Example_Design](src/Example_Design), specifically at the [top level
file](src/Example_Design/sdram_mega65r6.vhd) and the [trafic
generator](src/Example_Design/trafic_gen.vhd).

Make sure that you are aware of the necessity of
[Tri-State-Buffering](PORTING.md#tri-state-buffering). It is good design practice
to infer the tri-state buffers from the top-level file.

### Avalon Memory Map interface

Here is a brief summary of the signals involved in the Avalon Memory Map
interface.  For full details, refer to Section 3 of the
[specification](doc/Avalon_Interface_Specifications.pdf).
The SDRAM controller uses "Pipelined Read Transfer with Variable Latency",
see section 3.5.4 and Figure 12.
It does not use the "waitrequestAllowance" property and it does not support burst mode.

Signal          | Description
--------------: | :---------
`write`         | Asserted by client for one clock cycle when writing data to the SDRAM
`read`          | Asserted by client for one clock cycle when reading data from the SDRAM
`address`       | Address (in units of 16-bit words)
`writedata`     | Data to write
`byteenable`    | 1-bit for each byte of `writedata` to the SDRAM
`burstcount`    | Number of words to transfer. Must be 1.
`readdata`      | Data received from the SDRAM
`readdatavalid` | Asserted when data from the SDRAM is valid
`waitrequest`   | Asserted by the device when it is busy

## Further reading

The following links provide additional information:

* [Example Design](src/Example_Design/README.md)
* [Porting guideline](PORTING.md)
* [Detailed design description](src/sdram/README.md)
* [Simulation](simulation/README.md)

