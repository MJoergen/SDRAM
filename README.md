# WORK-IN-PROGRESS !!

# SDRAM

This repository contains a portable OpenSource SDRAM controller for FPGAs written in VHDL.
I'm writing my own implementation because I've looked at several other implementations, and
they all seemed lacking in various regards (features, stability, portability, etc.)

The SDRAM controller in this repository is a complete rewrite from scratch,
and is provided with a [MIT license](LICENSE).

Learn more by reading the documentation in this repository or by browsing the companion website: https://mjoergen.github.io/SDRAM/

## Features

This implementation has support for:

* Maximum SDRAM clock speed of 166 MHz.
* 16-bit [Avalon Memory Map interface](doc/Avalon_Interface_Specifications.pdf) including burst mode.
* Written for VHDL-2008

All the source files for the SDRAM controller are in the
[src/sdram](src/sdram) directory, and all files needed for simulation are
in the [simulation](simulation) directory.

Porting to another platform may require hand-tuning of some clock parameters,
see the section on [porting](PORTING.md).

## Example Design

I'm testing this SDRAM controller on the [MEGA65](https://mega65.org/)
hardware platform (Revision 6).  It contains the 8 MB SDRAM chip ([link to
datasheet](doc/66-67WVH8M8ALL-BLL-938852.pdf)) from ISSI (Integrated Silicon
Solution Inc.).  Specifically, the part number of the SDRAM device on the
MEGA65 is `IS66WVH8M8BLL-100B1LI`, which indicates a 64 Mbit, 100 MHz version
with 3.0 V supply and a single-ended clock.

Link to [datasheet](https://www.issi.com/WW/pdf/42-45R-S_86400F-16320F.pdf).

The version I'm targetting is: "IS42S16320F-6BL",
which is the one used on the MEGA65 platform.


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
file](src/Example_Design/top.vhd) and the [trafic
generator](src/Example_Design/trafic_gen.vhd).

Make sure that you are aware of the necessity of
[Tri-State-Buffering](PORTING.md#tri-state-buffering). It is good design practice
to infer the tri-state buffers from the top-level file. 

The SDRAM configuration and identification registers can be accessed through
the same Avalon Memory Map interface via the following addresses:

* `0x80000000` : Identification Register 0 (Read-only)
* `0x80000001` : Identification Register 1 (Read-only)
* `0x80000800` : Configuration Register 0  (Read-write)
* `0x80000801` : Configuration Register 1  (Read-write)

### Avalon Memory Map interface

Here is a brief summary of the signals involved in the Avalon Memory Map
interface.  For full details, refer to Section 3 of the
[specification](doc/Avalon_Interface_Specifications.pdf).
The SDRAM controller uses "Pipelined Read Transfer with Variable Latency",
see section 3.5.4 and Figure 12, and supports burst mode, see section 3.5.5.
It does not use the "waitrequestAllowance" property.

Signal          | Description
--------------: | :---------
`write`         | Asserted by client for one clock cycle when writing data to the SDRAM
`read`          | Asserted by client for one clock cycle when reading data from the SDRAM
`address`       | Address (in units of 16-bit words)
`writedata`     | Data to write
`byteenable`    | 1-bit for each byte of `writedata` to the SDRAM
`burstcount`    | Number of words to transfer
`readdata`      | Data received from the SDRAM
`readdatavalid` | Asserted when data from the SDRAM is valid
`waitrequest`   | Asserted by the device when it is busy

## Further reading

The following links provide additional information:

* [Example Design](src/Example_Design/README.md)
* [Porting guideline](PORTING.md)
* [Detailed design description](src/sdram/README.md)
* [Simulation](simulation/README.md)

