----------------------------------------------------------------------------------
-- Project Name:  RISC-V CPU
-- Description: Register file unit
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
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.constants.all;

entity register_set is
    Port ( 
        I_clk    : in STD_LOGIC;
        I_en     : in STD_LOGIC;
        I_dataD  : in STD_LOGIC_VECTOR (XLENM1 downto 0); -- Data to write to regD
        I_selRS1 : in STD_LOGIC_VECTOR (4 downto 0);      -- Select line for regRS1
        I_selRS2 : in STD_LOGIC_VECTOR (4 downto 0);      -- Select line for regRS2
        I_selD   : in STD_LOGIC_VECTOR (4 downto 0);      -- Select line for regD
        I_we     : in STD_LOGIC;                          -- Write enable for regD
        O_dataA  : out STD_LOGIC_VECTOR (XLENM1 downto 0);-- regRS1 data out
        O_dataB  : out STD_LOGIC_VECTOR (XLENM1 downto 0) -- regRS2 data out
    );
end register_set;

architecture Behavioral of register_set is
    type store_t is array (0 to 31) of std_logic_vector(XLENM1 downto 0);
    signal regs: store_t := (others => X"00000000");
    signal dataAout: STD_LOGIC_VECTOR (XLENM1 downto 0) := (others=>'0');
    signal dataBout: STD_LOGIC_VECTOR (XLENM1 downto 0) := (others=>'0');
begin

	process(I_clk, I_en)
	begin
		if rising_edge(I_clk) and I_en='1' then
			dataAout <= regs(to_integer(unsigned(I_selRS1)));
			dataBout <= regs(to_integer(unsigned(I_selRS2)));
			if (I_we = '1') then
				regs(to_integer(unsigned(I_selD))) <= I_dataD;
			end if;
		end if;
	end process;
	
	O_dataA <= dataAout;
	O_dataB <= dataBout;

end Behavioral;

