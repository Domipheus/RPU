----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.11.2018 22:51:11
-- Design Name: 
-- Module Name: rpu_core_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library work;
use work.constants.all;

entity alu_int32_div_tb is
--  Port ( );
end alu_int32_div_tb;

architecture Behavioral of alu_int32_div_tb is


    -- The RPU core definition
  component alu_int32_div is
    Port ( 
        I_clk : in  STD_LOGIC;
        I_exec : in  STD_LOGIC;
        I_dividend : in  STD_LOGIC_VECTOR (XLEN32M1 downto 0);
        I_divisor : in  STD_LOGIC_VECTOR (XLEN32M1 downto 0);
        I_op : in  STD_LOGIC_VECTOR (1 downto 0);
        O_dataResult : out  STD_LOGIC_VECTOR (XLEN32M1 downto 0);
        O_done : out STD_LOGIC;
        O_int : out std_logic
    );
  end component;
    
   signal I_clk : std_logic := '0';
   signal I_exec : std_logic := '0';
   signal I_dividend : std_logic_vector(31 downto 0) := (others => '0');
   signal I_divisor : std_logic_vector(31 downto 0) := (others => '0');
   signal I_op : std_logic_vector(1 downto 0) := (others => '0');
   signal O_dataResult : std_logic_vector(31 downto 0) := (others => '0');
   signal O_done : std_logic := '0';
   signal O_int : std_logic := '0';


   -- Clock period definitions
   constant I_clk_period : time := 10 ns;
BEGIN

	-- Instantiate the Unit Under Test (UUT)
   uut: alu_int32_div PORT MAP (
          I_clk => I_clk,
          I_exec => I_exec,
          I_dividend => I_dividend,
          I_divisor => I_divisor, 
          I_op => I_op,
          O_dataResult => O_dataResult,
          O_done => O_done,
          O_int => O_int
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

        I_dividend <= X"ffffffff";
		I_divisor <= X"00000000";
		I_op <= ALU_INT32_DIV_OP_DIVU;
		I_exec <= '1';
      wait for I_clk_period;
		I_exec <= '0';
		
      wait for I_clk_period*500;

      
              I_dividend <= X"0000000a";
              I_divisor <= X"0000000a";
              I_op <= ALU_INT32_DIV_OP_REMU;
              I_exec <= '1';
            wait for I_clk_period;
              I_exec <= '0';
              
            wait for I_clk_period*500;
		
          I_dividend <= X"00001001";
          I_divisor <= X"00000111";
          I_op <= ALU_INT32_DIV_OP_REM;
          I_exec <= '1';
        wait for I_clk_period;
          I_exec <= '0';
                     
       wait for I_clk_period*500;
                  
                    I_dividend <= X"ffff0001";
                    I_divisor <= X"00000111";
                    I_op <= ALU_INT32_DIV_OP_DIV;
                    I_exec <= '1';
                  wait for I_clk_period;
                    I_exec <= '0';
                               
                 wait for I_clk_period*500;
                           
                                      
--                                        I_dividend <= X"ffff0001";
--                                        I_divisor <= X"00000111";
--                                        I_op <= ALU_INT32_DIV_OP_DIVU;
--                                        I_exec <= '1';
--                                      wait for I_clk_period;
--                                        I_exec <= '0';             
--        wait for I_clk_period*500;
                  
            I_dividend <= X"00011101";
            I_divisor <= X"00000001";
            I_op <= ALU_INT32_DIV_OP_DIV;
            I_exec <= '1';
          wait for I_clk_period;
            I_exec <= '0';
            
          wait for I_clk_period*500;
          
            I_dividend <= X"00010001";
            I_divisor <= X"00000111";
            I_op <= ALU_INT32_DIV_OP_DIV;
            I_exec <= '1';
          wait for I_clk_period;
            I_exec <= '0';
      wait;
   end process;


end Behavioral;
