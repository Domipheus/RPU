----------------------------------------------------------------------------------
-- Project Name:  RISC-V CPU
-- Description: Local Interrupt unit
-- 
----------------------------------------------------------------------------------
-- Copyright 2018,2019,2020  Colin Riley
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
use IEEE.NUMERIC_STD.all;

library work;
use work.constants.all;

entity lint_unit is
    port (
        I_clk : in STD_LOGIC;
        I_reset : in STD_LOGIC;
        I_nextPc : in STD_LOGIC_VECTOR (31 downto 0);
        I_pc : in STD_LOGIC_VECTOR (31 downto 0);
        I_enMask : in STD_LOGIC_VECTOR (3 downto 0);
        I_int0 : in STD_LOGIC;
        I_int_data0 : in STD_LOGIC_VECTOR (31 downto 0);
        O_int0_ack : out STD_LOGIC;
        I_int1 : in STD_LOGIC;
        I_int_data1 : in STD_LOGIC_VECTOR (31 downto 0);
        O_int1_ack : out STD_LOGIC;
        I_int2 : in STD_LOGIC;
        I_int_data2 : in STD_LOGIC_VECTOR (31 downto 0);
        O_int2_ack : out STD_LOGIC;
        I_int3 : in STD_LOGIC;
        I_int_data3 : in STD_LOGIC_VECTOR (31 downto 0);
        O_int3_ack : out STD_LOGIC;
        O_int : out STD_LOGIC;
        O_int_data : out STD_LOGIC_VECTOR (31 downto 0);
        O_int_epc : out STD_LOGIC_VECTOR (31 downto 0)
    );
end lint_unit;

architecture Behavioral of lint_unit is

    signal actual_int : std_logic := '0';
    signal actual_int_data : std_logic_vector (31 downto 0) := X"00000000";
    signal actual_int_epc : std_logic_vector (31 downto 0) := X"00000000";

    signal int0_ack : std_logic := '0';
    signal int1_ack : std_logic := '0';
    signal int2_ack : std_logic := '0';
    signal int3_ack : std_logic := '0';

    signal reset_counter : integer := 0;

begin

    O_int <= actual_int;
    O_int_data <= actual_int_data;
    O_int_epc <= actual_int_epc;

    O_int0_ack <= int0_ack;
    O_int1_ack <= int1_ack;
    O_int2_ack <= int2_ack;
    O_int3_ack <= int3_ack;

    -- This simply filters one of the 4 int sources to a single one in
    -- decreasing priority, latching the data until a reset.
    arb : process (I_clk)
    begin
        if rising_edge(I_clk) then
            if I_reset = '1' then
                reset_counter <= 1;
                int0_ack <= '0';
                int1_ack <= '0';
                int2_ack <= '0';
                int3_ack <= '0';
            elsif reset_counter = 1 then
                reset_counter <= 2;
            elsif reset_counter = 2 then
                reset_counter <= 3;
            elsif reset_counter = 3 then
                actual_int <= '0';
                reset_counter <= 0;
            elsif reset_counter = 0 and actual_int = '0' then

                if I_enMask(0) = '1' and I_int0 = '1' and int0_ack = '0' then
                    actual_int <= '1';
                    actual_int_data <= I_int_data0;
                    int0_ack <= '1';
                elsif I_enMask(1) = '1' and I_int1 = '1' and int1_ack = '0'then
                    actual_int <= '1';
                    actual_int_data <= I_int_data1;
                    int1_ack <= '1';
                elsif I_enMask(2) = '1' and I_int2 = '1' and int2_ack = '0' then
                    actual_int <= '1';
                    actual_int_data <= I_int_data2;
                    int2_ack <= '1';
                elsif I_enMask(3) = '1' and I_int3 = '1' and int3_ack = '0'then
                    actual_int <= '1';
                    actual_int_data <= I_int_data3;
                    int3_ack <= '1';
                end if;
            end if;
        end if;
    end process;
end Behavioral;