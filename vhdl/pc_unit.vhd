----------------------------------------------------------------------------------
-- Project Name: RPU
-- Description: Program Counter unit of RPU
--
-- Simple black box for holding and manipulating the PC
-- 
----------------------------------------------------------------------------------
-- Copyright 2016,2018,2019,2020 Colin Riley
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
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

library work;
use work.constants.all;

entity pc_unit is
    Port ( 
        I_clk : in  STD_LOGIC;
        I_nPC : in  STD_LOGIC_VECTOR (XLENM1 downto 0);
        I_nPCop : in  STD_LOGIC_VECTOR (1 downto 0);
        I_intVec: in STD_LOGIC;
        O_PC : out  STD_LOGIC_VECTOR (XLENM1 downto 0)
    );
end pc_unit;

architecture Behavioral of pc_unit is
    signal current_pc: std_logic_vector( XLENM1 downto 0) := ADDR_RESET;
begin

	process (I_clk)
	begin
		if rising_edge(I_clk) then
			case I_nPCop is
				when PCU_OP_NOP => 	-- NOP, keep PC the same/halt
				when PCU_OP_INC => 	-- increment
					current_pc <= std_logic_vector(unsigned(current_pc) + 4); -- 32bit byte addressing
				when PCU_OP_ASSIGN => 	-- set from external input
					current_pc <= I_nPC;
				when PCU_OP_RESET => 	-- Reset
					current_pc <= ADDR_RESET;
				when others =>
			end case;
		end if;
	end process;

	O_PC <= current_pc;
	
end Behavioral;

