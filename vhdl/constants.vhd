----------------------------------------------------------------------------------
-- Project Name: RISC-V CPU
-- Description: Constants for instruction forms, opcodes, conditional flags, etc.
-- 
----------------------------------------------------------------------------------
-- Copyright 2016 Colin Riley
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;

package constants is


constant XLEN: integer := 32;
constant XLENM1: integer := XLEN - 1;

constant XLEN32: integer:= 32;
constant XLEN32M1: integer:= XLEN32 -1;


constant BWIDTH: integer:= 32;
constant BWIDTHM1: integer:= BWIDTH -1;


constant ADDR_RESET:    std_logic_vector(XLEN32M1 downto 0) :=  X"00000000";
constant ADDR_INTVEC:   std_logic_vector(XLEN32M1 downto 0) :=  X"00000100";


-- PC unit opcodes
constant PCU_OP_NOP: std_logic_vector(1 downto 0):= "00";
constant PCU_OP_INC: std_logic_vector(1 downto 0):= "01";
constant PCU_OP_ASSIGN: std_logic_vector(1 downto 0):= "10";
constant PCU_OP_RESET: std_logic_vector(1 downto 0):= "11";

-- Instruction Form Offsets
constant OPCODE_START: integer := 6;
constant OPCODE_END: integer := 0;
constant OPCODE_END_2: integer := 2;

constant RD_START: integer := 11;
constant RD_END: integer := 7;

constant FUNCT3_START: integer := 14;
constant FUNCT3_END: integer := 12;

constant R1_START: integer := 19;
constant R1_END: integer := 15;

constant R2_START: integer := 24;
constant R2_END: integer := 20;

constant FUNCT7_START: integer := 31;
constant FUNCT7_END: integer := 25;

constant IMM_I_START: integer := 31;
constant IMM_I_END: integer := 20;

constant IMM_U_START: integer := 31;
constant IMM_U_END: integer := 12;

constant IMM_S_A_START: integer := 31;
constant IMM_S_A_END: integer := 25;

constant IMM_S_B_START: integer := 11;
constant IMM_S_B_END: integer := 7;

-- Opcodes
constant OPCODE_LOAD: std_logic_vector(4 downto 0) := "00000";
constant OPCODE_STORE: std_logic_vector(4 downto 0) := "01000";
constant OPCODE_MADD: std_logic_vector(4 downto 0) := "10000";
constant OPCODE_BRANCH: std_logic_vector(4 downto 0) := "11000";
constant OPCODE_JALR: std_logic_vector(4 downto 0) := "11001";
constant OPCODE_JAL: std_logic_vector(4 downto 0) := "11011";
constant OPCODE_SYSTEM: std_logic_vector(4 downto 0) := "11100";
constant OPCODE_OP: std_logic_vector(4 downto 0) := "01100";
constant OPCODE_OPIMM: std_logic_vector(4 downto 0) := "00100";
constant OPCODE_MISCMEM: std_logic_vector(4 downto 0) := "00011";
constant OPCODE_AUIPC: std_logic_vector(4 downto 0) := "00101";
constant OPCODE_LUI: std_logic_vector(4 downto 0) := "01101";

-- Flags
constant F3_BRANCH_BEQ: std_logic_vector(2 downto 0) := "000";
constant F3_BRANCH_BNE: std_logic_vector(2 downto 0) := "001";
constant F3_BRANCH_BLT: std_logic_vector(2 downto 0) := "100";
constant F3_BRANCH_BGE: std_logic_vector(2 downto 0) := "101";
constant F3_BRANCH_BLTU: std_logic_vector(2 downto 0) := "110";
constant F3_BRANCH_BGEU: std_logic_vector(2 downto 0) := "111";

constant F3_JALR: std_logic_vector(2 downto 0) := "000";

constant F3_LOAD_LB: std_logic_vector(2 downto 0) := "000";
constant F3_LOAD_LH: std_logic_vector(2 downto 0) := "001";
constant F3_LOAD_LW: std_logic_vector(2 downto 0) := "010";
constant F3_LOAD_LBU: std_logic_vector(2 downto 0) := "100";
constant F3_LOAD_LHU: std_logic_vector(2 downto 0) := "101";

constant F2_MEM_LS_SIZE_B: std_logic_vector(1 downto 0) := "00";
constant F2_MEM_LS_SIZE_H: std_logic_vector(1 downto 0) := "01";
constant F2_MEM_LS_SIZE_W: std_logic_vector(1 downto 0) := "10";

constant F3_STORE_SB: std_logic_vector(2 downto 0) := "000";
constant F3_STORE_SH: std_logic_vector(2 downto 0) := "001";
constant F3_STORE_SW: std_logic_vector(2 downto 0) := "010";

constant F3_OPIMM_ADDI: std_logic_vector(2 downto 0) := "000";
constant F3_OPIMM_SLTI: std_logic_vector(2 downto 0) := "010";
constant F3_OPIMM_SLTIU: std_logic_vector(2 downto 0) := "011";
constant F3_OPIMM_XORI: std_logic_vector(2 downto 0) := "100";
constant F3_OPIMM_ORI: std_logic_vector(2 downto 0) := "110";
constant F3_OPIMM_ANDI: std_logic_vector(2 downto 0) := "111";

constant F3_OPIMM_SLLI: std_logic_vector(2 downto 0) := "001";
constant F7_OPIMM_SLLI: std_logic_vector(6 downto 0) := "0000000";
constant F3_OPIMM_SRLI: std_logic_vector(2 downto 0) := "101";
constant F7_OPIMM_SRLI: std_logic_vector(6 downto 0) := "0000000";
constant F3_OPIMM_SRAI: std_logic_vector(2 downto 0) := "101";
constant F7_OPIMM_SRAI: std_logic_vector(6 downto 0) := "0100000";

constant F3_OP_ADD: std_logic_vector(2 downto 0) := "000";
constant F7_OP_ADD: std_logic_vector(6 downto 0) := "0000000";
constant F3_OP_SUB: std_logic_vector(2 downto 0) := "000";
constant F7_OP_SUB: std_logic_vector(6 downto 0) := "0100000";
constant F3_OP_SLL: std_logic_vector(2 downto 0) := "001";
constant F7_OP_SLL: std_logic_vector(6 downto 0) := "0000000";
constant F3_OP_SLT: std_logic_vector(2 downto 0) := "010";
constant F7_OP_SLT: std_logic_vector(6 downto 0) := "0000000";
constant F3_OP_SLTU: std_logic_vector(2 downto 0) := "011";
constant F7_OP_SLTU: std_logic_vector(6 downto 0) := "0000000";
constant F3_OP_XOR: std_logic_vector(2 downto 0) := "100";
constant F7_OP_XOR: std_logic_vector(6 downto 0) := "0000000";
constant F3_OP_SRL: std_logic_vector(2 downto 0) := "101";
constant F7_OP_SRL: std_logic_vector(6 downto 0) := "0000000";
constant F3_OP_SRA: std_logic_vector(2 downto 0) := "101";
constant F7_OP_SRA: std_logic_vector(6 downto 0) := "0100000";
constant F3_OP_OR: std_logic_vector(2 downto 0) := "110";
constant F7_OP_OR: std_logic_vector(6 downto 0) := "0000000";
constant F3_OP_AND: std_logic_vector(2 downto 0) := "111";
constant F7_OP_AND: std_logic_vector(6 downto 0) := "0000000";

constant F3_MISCMEM_FENCE: std_logic_vector(2 downto 0) := "000";
constant F3_MISCMEM_FENCEI: std_logic_vector(2 downto 0) := "001";

constant F3_SYSTEM_ECALL: std_logic_vector(2 downto 0) := "000";
constant IMM_I_SYSTEM_ECALL: std_logic_vector(11 downto 0) := "000000000000";
constant F3_SYSTEM_EBREAK: std_logic_vector(2 downto 0) := "000";
constant IMM_I_SYSTEM_EBREAK: std_logic_vector(11 downto 0) := "000000000001";
constant F3_SYSTEM_CSRRW: std_logic_vector(2 downto 0) := "001";
constant F3_SYSTEM_CSRRS: std_logic_vector(2 downto 0) := "010";
constant F3_SYSTEM_CSRRC: std_logic_vector(2 downto 0) := "011";
constant F3_SYSTEM_CSRRWI: std_logic_vector(2 downto 0) := "101";
constant F3_SYSTEM_CSRRSI: std_logic_vector(2 downto 0) := "110";
constant F3_SYSTEM_CSRRCI: std_logic_vector(2 downto 0) := "111";


constant F3_PRIVOP: std_logic_vector(2 downto 0) := "000";

constant F7_PRIVOP_URET: std_logic_vector(6 downto 0)       := "0000000";
constant F7_PRIVOP_SRET_WFI: std_logic_vector(6 downto 0)   := "0001000";
constant F7_PRIVOP_MRET: std_logic_vector(6 downto 0)       := "0011000";
constant F7_PRIVOP_SFENCE_VMA: std_logic_vector(6 downto 0) := "0001001";

constant RD_PRIVOP: std_logic_vector(4 downto 0) := "00000";

constant R2_PRIV_RET: std_logic_vector(4 downto 0) := "00010";
constant R2_PRIV_WFI: std_logic_vector(4 downto 0) := "00101";


constant EXCEPTION_INT_USER_SOFTWARE:       std_logic_vector(XLEN32M1 downto 0):=  X"80000000";
constant EXCEPTION_INT_SUPERVISOR_SOFTWARE: std_logic_vector(XLEN32M1 downto 0):=  X"80000001";
--constant EXCEPTION_INT_RESERVED:          std_logic_vector(XLEN32M1 downto 0):=  X"80000002";
constant EXCEPTION_INT_MACHINE_SOFTWARE:    std_logic_vector(XLEN32M1 downto 0):=  X"80000003";
constant EXCEPTION_INT_USER_TIMER:          std_logic_vector(XLEN32M1 downto 0):=  X"80000004";
constant EXCEPTION_INT_SUPERVISOR_TIMER:    std_logic_vector(XLEN32M1 downto 0):=  X"80000005";
--constant EXCEPTION_INT_RESERVED:          std_logic_vector(XLEN32M1 downto 0):=  X"80000006";
constant EXCEPTION_INT_MACHINE_TIMER:       std_logic_vector(XLEN32M1 downto 0):=  X"80000007";
constant EXCEPTION_INT_USER_EXTERNAL:       std_logic_vector(XLEN32M1 downto 0):=  X"80000008";
constant EXCEPTION_INT_SUPERVISOR_EXTERNAL: std_logic_vector(XLEN32M1 downto 0):=  X"80000009";
--constant EXCEPTION_INT_RESERVED:          std_logic_vector(XLEN32M1 downto 0):=  X"8000000a";
constant EXCEPTION_INT_MACHINE_EXTERNAL:    std_logic_vector(XLEN32M1 downto 0):=  X"8000000b";

constant EXCEPTION_INSTRUCTION_ADDR_MISALIGNED: std_logic_vector(XLEN32M1 downto 0):=  X"00000000";
constant EXCEPTION_INSTRUCTION_ACCESS_FAULT:    std_logic_vector(XLEN32M1 downto 0):=  X"00000001";
constant EXCEPTION_INSTRUCTION_ILLEGAL:         std_logic_vector(XLEN32M1 downto 0):=  X"00000002";
constant EXCEPTION_BREAKPOINT:                  std_logic_vector(XLEN32M1 downto 0):=  X"00000003";
constant EXCEPTION_LOAD_ADDRESS_MISALIGNED:     std_logic_vector(XLEN32M1 downto 0):=  X"00000004";
constant EXCEPTION_LOAD_ACCESS_FAULT:           std_logic_vector(XLEN32M1 downto 0):=  X"00000005";
constant EXCEPTION_STORE_AMO_ADDRESS_MISALIGNED:std_logic_vector(XLEN32M1 downto 0):=  X"00000006";
constant EXCEPTION_STORE_AMO_ACCESS_FAULT:      std_logic_vector(XLEN32M1 downto 0):=  X"00000007";
constant EXCEPTION_ENVIRONMENT_CALL_FROM_UMODE: std_logic_vector(XLEN32M1 downto 0):=  X"00000008";
constant EXCEPTION_ENVIRONMENT_CALL_FROM_SMODE: std_logic_vector(XLEN32M1 downto 0):=  X"00000009";
--constant EXCEPTION_RESERVED:                  std_logic_vector(XLEN32M1 downto 0):=  X"0000000a";
constant EXCEPTION_ENVIRONMENT_CALL_FROM_MMODE: std_logic_vector(XLEN32M1 downto 0):=  X"0000000b";
constant EXCEPTION_INSTRUCTION_PAGE_FAULT:      std_logic_vector(XLEN32M1 downto 0):=  X"0000000c";
constant EXCEPTION_LOAD_PAGE_FAULT:             std_logic_vector(XLEN32M1 downto 0):=  X"0000000d";
--constant EXCEPTION_RESERVED:                  std_logic_vector(XLEN32M1 downto 0):=  X"0000000e";
constant EXCEPTION_STORE_AMO_PAGE_FAULT:        std_logic_vector(XLEN32M1 downto 0):=  X"0000000f";

constant CSR_ADDR_PRIVILEGE_BIT_START:  integer := 9;
constant CSR_ADDR_PRIVILEGE_BIT_END:    integer := 8;
constant CSR_ADDR_PRIVILEGE_USER:       std_logic_vector(1 downto 0):= "00";
constant CSR_ADDR_PRIVILEGE_SUPERVISOR: std_logic_vector(1 downto 0):= "01";
constant CSR_ADDR_PRIVILEGE_RESERVED:   std_logic_vector(1 downto 0):= "10";
constant CSR_ADDR_PRIVILEGE_MACHINE:    std_logic_vector(1 downto 0):= "11";

constant CSR_ADDR_ACCESS_BIT_START: integer := 11;
constant CSR_ADDR_ACCESS_BIT_END:   integer := 10;
constant CSR_ADDR_ACCESS_READONLY:  std_logic_vector(1 downto 0):= "11";


-- CSR Opcodes:
-- 0 - CSR Written
-- 1 - CSR Read
-- 2..3 0 operation
--    01 - read or write whole XLEN
--    10 - Set bits
--    11 - clear bits
-- 4 - immediate or register

constant CSR_OP_BITS_READ: integer := 0;
constant CSR_OP_BITS_WRITTEN: integer := 1;
constant CSR_OP_BITS_OPA: integer := 2;
constant CSR_OP_BITS_OPB: integer := 3;
constant CSR_OP_BITS_IMM: integer := 4;

constant CSR_MAINOP_WR: std_logic_vector(1 downto 0) := "01";
constant CSR_MAINOP_SET: std_logic_vector(1 downto 0) := "10";
constant CSR_MAINOP_CLEAR: std_logic_vector(1 downto 0) := "11";

constant CSR_OP_WR: std_logic_vector(4 downto 0) := "00100";
constant CSR_OP_W:  std_logic_vector(4 downto 0) := "00101";
constant CSR_OP_R:  std_logic_vector(4 downto 0) := "00110";

constant CSR_OP_SET_WR: std_logic_vector(4 downto 0) := "01000";
constant CSR_OP_SET_W:  std_logic_vector(4 downto 0) := "01001";
constant CSR_OP_SET_R:  std_logic_vector(4 downto 0) := "01010";

constant CSR_OP_CLEAR_WR: std_logic_vector(4 downto 0) := "01100";
constant CSR_OP_CLEAR_W:  std_logic_vector(4 downto 0) := "01101";
constant CSR_OP_CLEAR_R:  std_logic_vector(4 downto 0) := "01110";

constant CSR_OP_IMM_WR: std_logic_vector(4 downto 0) := "10100";
constant CSR_OP_IMM_W:  std_logic_vector(4 downto 0) := "10101";
constant CSR_OP_IMM_R:  std_logic_vector(4 downto 0) := "10110";

constant CSR_OP_IMM_SET_WR: std_logic_vector(4 downto 0) := "11000";
constant CSR_OP_IMM_SET_W:  std_logic_vector(4 downto 0) := "11001";
constant CSR_OP_IMM_SET_R:  std_logic_vector(4 downto 0) := "11010";

constant CSR_OP_IMM_CLEAR_WR: std_logic_vector(4 downto 0) := "11100";
constant CSR_OP_IMM_CLEAR_W:  std_logic_vector(4 downto 0) := "11101";
constant CSR_OP_IMM_CLEAR_R:  std_logic_vector(4 downto 0) := "11110";

end constants;

package body constants is
 
end constants;
