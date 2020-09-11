# RPU
Basic RISC-V CPU implementation in VHDL.

This is a RV32IMZcsr ISA CPU implementation, based off of my TPU CPU design. It is very simple, but has run rv32i-compiled GCC toolchain binaries at over 200MHz on a Digilent Arty S7-50 board, built with Xilinx Spartan 7 tools. 

When used in the ArtyS7-RPU-SoC @ 100MHZ it can run DooM timedemo3 at ~8fps, and boot operating systems such as Zephyr RTOS.

The Wiki will have more in depth information: https://github.com/Domipheus/RPU/wiki

Please let me know if you are using any of the RPU design in your own projects! I am contactable on twitter @domipheus.

# Implementation

Diagram does not include recently added CSR & LINT units, or the fact that interrupts are supported.

![RPU Core overview](https://raw.githubusercontent.com/Domipheus/RPU/master/rpu_core_diagram.png)

Implementation detail is written about via blogs available at http://labs.domipheus.com/blog/designing-a-cpu-in-vhdl-part-15-introducing-rpu/

The tests in the repo are incredibly old and basic, and included only as a baseline to help. They will be expanded upon in time. The core_tb should work for basic simulator use and could be expanded for more complex debugging.

Currently working on: Privilege modes, memory system overhaul, mmu support