----------------------------------------------------------------------------------
-- Project Name: RISC-V CPU
-- Description: Constants for instruction forms, opcodes, conditional flags, etc.
-- 
-- Revision: 1
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

end constants;

package body constants is
 
end constants;
