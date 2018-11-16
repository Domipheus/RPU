# RPU
Basic RISC-V CPU implementation in VHDL.

This is a RV32I ISA CPU implementation, based off of my TPU CPU design. It is very simple, is missing several features, but can run rv32i-compiled GCC toolchain binaries at over 200MHz on a Digilent Arty S7-50 board, built with Xilinx Spartan 7 tools. 

Please let me know if you are using any of the RPU design in your own projects! I am contactable on twitter @domipheus.

# Implementation

Diagram does not include recently added CSR unit.

![RPU Core overview](https://raw.githubusercontent.com/Domipheus/RPU/master/rpu_core_diagram.png)

Implementation detail is written about via blogs available at http://labs.domipheus.com/blog/designing-a-cpu-in-vhdl-part-15-introducing-rpu/

The tests in the repo are incredibly old and basic, and included only as a baseline to help. They will be expanded upon in time. The core_tb should work for basic simulator use and could be expanded for more complex debugging.

Currently working on: CSRs, Interrupts