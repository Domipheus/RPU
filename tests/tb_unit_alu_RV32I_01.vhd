--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:43:32 12/10/2016
-- Design Name:   
-- Module Name:   C:/Users/colin/Desktop/riscy/ise/tb_unit_alu_RV32I_01.vhd
-- Project Name:  riscv32_v1
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: alu_RV32I
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

use work.constants.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_unit_alu_RV32I_01 IS
END tb_unit_alu_RV32I_01;
 
ARCHITECTURE behavior OF tb_unit_alu_RV32I_01 IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT alu_RV32I
    PORT(
         I_clk : IN  std_logic;
         I_en : IN  std_logic;
         I_dataA : IN  std_logic_vector(31 downto 0);
         I_dataB : IN  std_logic_vector(31 downto 0);
         I_dataDwe : IN  std_logic;
         I_aluop : IN  std_logic_vector(4 downto 0);
         I_aluFunc : IN  std_logic_vector(15 downto 0);
         I_PC : IN  std_logic_vector(31 downto 0);
         I_dataIMM : IN  std_logic_vector(31 downto 0);
         O_dataResult : OUT  std_logic_vector(31 downto 0);
         O_branchTarget : OUT  std_logic_vector(31 downto 0);
         O_dataWriteReg : OUT  std_logic;
         O_shouldBranch : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal I_clk : std_logic := '0';
   signal I_en : std_logic := '0';
   signal I_dataA : std_logic_vector(31 downto 0) := (others => '0');
   signal I_dataB : std_logic_vector(31 downto 0) := (others => '0');
   signal I_dataDwe : std_logic := '0';
   signal I_aluop : std_logic_vector(4 downto 0) := (others => '0');
   signal I_aluFunc : std_logic_vector(15 downto 0) := (others => '0');
   signal I_PC : std_logic_vector(31 downto 0) := (others => '0');
   signal I_dataIMM : std_logic_vector(31 downto 0) := (others => '0');

 	--Outputs
   signal O_dataResult : std_logic_vector(31 downto 0);
   signal O_branchTarget : std_logic_vector(31 downto 0);
   signal O_dataWriteReg : std_logic := '0';
   signal O_shouldBranch : std_logic := '0';

   -- Clock period definitions
   constant I_clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: alu_RV32I PORT MAP (
          I_clk => I_clk,
          I_en => I_en,
          I_dataA => I_dataA,
          I_dataB => I_dataB,
          I_dataDwe => I_dataDwe,
          I_aluop => I_aluop,
          I_aluFunc => I_aluFunc,
          I_PC => I_PC,
          I_dataIMM => I_dataIMM,
          O_dataResult => O_dataResult,
          O_branchTarget => O_branchTarget,
          O_dataWriteReg => O_dataWriteReg,
          O_shouldBranch => O_shouldBranch
        );

   -- Clock process definitions
   I_clk_process :process
   begin
		I_clk <= '0';
		wait for I_clk_period/2;
		I_clk <= '1';
		wait for I_clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for I_clk_period*10;
      -- insert stimulus here 

      I_dataA <= X"00001000";
		I_dataB <= X"01A01001";
		I_aluOp <= OPCODE_OP;
		I_aluFunc <= "000000" & F7_OP_ADD & F3_OP_ADD;
		I_dataImm <= X"00000000";
		I_PC <= X"A0000000";
		I_dataDwe <= '1';
		I_en <= '1';
		
      wait for I_clk_period*2;

      I_dataA <= X"00000001";
		I_dataB <= X"00000006";
		I_aluOp <= OPCODE_OP;
		I_aluFunc <= "000000" & F7_OP_ADD & F3_OP_ADD;
		I_dataImm <= X"00000000";
		I_PC <= X"A0000004";
		I_dataDwe <= '1';
		I_en <= '1';
		
      wait for I_clk_period*2;

      I_dataA <= X"00346A00";
		I_dataB <= X"120000B6";
		I_aluOp <= OPCODE_OP;
		I_aluFunc <= "000000" & F7_OP_OR & F3_OP_OR;
		I_dataImm <= X"00000000";
		I_PC <= X"A0000008";
		I_dataDwe <= '1';
		I_en <= '1';
		
      wait;
   end process;

END;
