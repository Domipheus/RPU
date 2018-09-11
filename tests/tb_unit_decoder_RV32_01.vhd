--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   22:43:26 12/08/2016
-- Design Name:   
-- Module Name:   C:/Users/colin/Desktop/riscy/ise/tb_unit_decoder_RV32_01.vhd
-- Project Name:  riscv32_v1
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: decoder_RV32
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
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_unit_decoder_RV32_01 IS
END tb_unit_decoder_RV32_01;
 
ARCHITECTURE behavior OF tb_unit_decoder_RV32_01 IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT decoder_RV32
    PORT(
         I_clk : IN  std_logic;
         I_en : IN  std_logic;
         I_dataInst : IN  std_logic_vector(31 downto 0);
         O_selRS1 : OUT  std_logic_vector(4 downto 0);
         O_selRS2 : OUT  std_logic_vector(4 downto 0);
         O_selD : OUT  std_logic_vector(4 downto 0);
         O_dataIMM : OUT  std_logic_vector(31 downto 0);
         O_regDwe : OUT  std_logic;
         O_aluOp : OUT  std_logic_vector(6 downto 0);
         O_aluFunc : OUT  std_logic_vector(15 downto 0);  -- ALU function
			O_memOp : out STD_LOGIC_VECTOR(4 downto 0)  
        );
    END COMPONENT;
    

   --Inputs
   signal I_clk : std_logic := '0';
   signal I_en : std_logic := '0';
   signal I_dataInst : std_logic_vector(31 downto 0) := (others => '0');

 	--Outputs
   signal O_selRS1 : std_logic_vector(4 downto 0);
   signal O_selRS2 : std_logic_vector(4 downto 0);
   signal O_selD : std_logic_vector(4 downto 0);
   signal O_dataIMM : std_logic_vector(31 downto 0);
   signal O_regDwe : std_logic;
   signal O_aluOp : std_logic_vector(6 downto 0);
   signal O_aluFunc : std_logic_vector(15 downto 0);
	signal O_memOp : STD_LOGIC_VECTOR(4 downto 0);

   -- Clock period definitions
   constant I_clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: decoder_RV32 PORT MAP (
          I_clk => I_clk,
          I_en => I_en,
          I_dataInst => I_dataInst,
          O_selRS1 => O_selRS1,
          O_selRS2 => O_selRS2,
          O_selD => O_selD,
          O_dataIMM => O_dataIMM,
          O_regDwe => O_regDwe,
          O_aluOp => O_aluOp,
          O_aluFunc => O_aluFunc,
			 O_memOp => O_memOp
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
		I_dataInst <= "0000000" & "00001" & "00010" & "000" & "01001" &  "0110011";
		I_en <= '1';
		
		wait for I_clk_period*2;
		
		I_dataInst <= "000000000001" & "00010" & "000" & "01001" &  "0010011";
		I_en <= '1';
		
		wait for I_clk_period*2;
		
		I_dataInst <= "100000000001" & "00010" & "000" & "01001" &  "0010011";
		I_en <= '1';
		
		wait for I_clk_period*2;
		
		I_dataInst <= "100001000001" & "00000" & "010" & "00001" &  "0000011";
		I_en <= '1';
		
		wait for I_clk_period*2;

      wait;
   end process;

END;
