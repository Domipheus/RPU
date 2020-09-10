----------------------------------------------------------------------------------
-- Project Name: RISC-V CPU
-- Description: ALU unit for 32-bit integer division ops
-- 
----------------------------------------------------------------------------------
-- Copyright 2020  Colin Riley
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.all;
library work;
use work.constants.all;

entity alu_int32_div is
    port (
        I_clk : in STD_LOGIC;
        I_exec : in STD_LOGIC;
        I_dividend : in STD_LOGIC_VECTOR (XLEN32M1 downto 0);
        I_divisor : in STD_LOGIC_VECTOR (XLEN32M1 downto 0);
        I_op : in STD_LOGIC_VECTOR (1 downto 0);
        O_dataResult : out STD_LOGIC_VECTOR (XLEN32M1 downto 0);
        O_done : out STD_LOGIC;
        O_int : out std_logic
    );
end alu_int32_div;

architecture Behavioral of alu_int32_div is
    signal s_done : std_logic := '0';
    signal s_int : std_logic := '0';
    signal s_op : std_logic_vector(1 downto 0) := (others => '0');
    signal s_result : std_logic_vector(XLEN32M1 downto 0) := (others => '0');
    signal s_outsign : std_logic := '0';
    signal s_ur : unsigned(XLEN32M1 downto 0) := (others => '0');

    signal s_i : integer := 0;
    signal s_N : unsigned(XLEN32M1 downto 0) := (others => '0');
    signal s_D : unsigned(XLEN32M1 downto 0) := (others => '0');
    signal s_R : unsigned(XLEN32M1 downto 0) := (others => '0');
    signal s_Q : unsigned(XLEN32M1 downto 0) := (others => '0');
    constant STATE_IDLE : integer := 0;
    constant STATE_INFLIGHTU : integer := 1;
    constant STATE_COMPLETE : integer := 2;

    signal s_state : integer := 0;
begin

    process (I_clk)
    begin
        if rising_edge(I_clk) then
            if s_state = STATE_IDLE then
                s_done <= '0';
                if I_exec = '1' then
                    s_op <= I_op;
                    s_done <= '0';

                    if (I_divisor = X"00000000") then
                        s_state <= STATE_COMPLETE;
                        s_Q <= X"ffffffff";

                        if I_dividend(31) = '1' then
                            s_R <= unsigned(-signed(I_dividend));
                        else
                            s_R <= unsigned(I_dividend);
                        end if;

                        if (I_op = ALU_INT32_DIV_OP_DIV) or (I_op = ALU_INT32_DIV_OP_DIVU) then
                            s_outsign <= '0';
                        else
                            s_outsign <= I_dividend(31);
                        end if;
                        
                    elsif (I_divisor = X"00000001") and (I_op = ALU_INT32_DIV_OP_DIV) then
                        s_state <= STATE_COMPLETE;
                        s_R <= X"00000000";
                        if I_dividend(31) = '1' then
                            s_Q <= unsigned(-signed(I_dividend));
                        else
                            s_Q <= unsigned(I_dividend);
                        end if;
                        s_outsign <= I_dividend(31);
                        
                    else
                        if I_op(ALU_INT32_DIV_OP_UNSIGNED_BIT) = '1' then
                            s_state <= STATE_INFLIGHTU;
                            s_N <= unsigned(I_dividend);
                            s_D <= unsigned(I_divisor);
                            s_ur <= X"00000000";
                            s_Q <= X"00000000";
                            s_R <= X"00000000";

                            s_i <= 31;
                            s_outsign <= '0';
                        else
                            s_state <= STATE_INFLIGHTU;

                            if (I_op = ALU_INT32_DIV_OP_DIV) then
                                s_outsign <= I_dividend(31) xor I_divisor(31);
                            else
                                s_outsign <= I_dividend(31);
                            end if;

                            if I_dividend(31) = '1' then
                                s_N <= unsigned(-signed(I_dividend));
                            else
                                s_N <= unsigned(I_dividend);
                            end if;

                            if I_divisor(31) = '1' then
                                s_D <= unsigned(-signed(I_divisor));
                            else
                                s_D <= unsigned(I_divisor);
                            end if;

                            s_ur <= X"00000000";

                            s_Q <= X"00000000";
                            s_R <= X"00000000";

                            s_i <= 31;

                        end if;
                    end if;
                end if;
                
                
            elsif s_state = STATE_INFLIGHTU then
                -- binary integer long division loop
                if (s_R(30 downto 0) & s_N(s_i)) >= s_D then
                    s_R <= (s_R(30 downto 0) & s_N(s_i)) - s_D;
                    s_Q(s_i) <= '1';
                else
                    s_R <= s_R(30 downto 0) & s_N(s_i);
                end if;
                
                if s_i = 0 then
                    s_state <= STATE_COMPLETE;
                else
                    s_i <= s_i - 1;
                end if;
                
                
            elsif s_state = STATE_COMPLETE then

                if (s_op = ALU_INT32_DIV_OP_DIV) or (s_op = ALU_INT32_DIV_OP_DIVU) then
                    if (s_outsign = '1') then
                        s_result <= std_logic_vector(-signed(std_logic_vector(s_Q)));
                    else
                        s_result <= std_logic_vector(s_Q);
                    end if;
                else
                    if (s_outsign = '1') then
                        s_result <= std_logic_vector(-signed(std_logic_vector(s_R)));
                    else
                        s_result <= std_logic_vector(s_R);
                    end if;
                end if;

                s_done <= '1';
                s_state <= STATE_IDLE;
            end if;
        end if;
    end process;

    O_dataResult <= s_result;
    O_done <= s_done;
    O_int <= s_int;
end Behavioral;