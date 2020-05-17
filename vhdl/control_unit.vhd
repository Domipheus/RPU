----------------------------------------------------------------------------------
-- Project Name: RPU
-- Description: control unit
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

library work;
use work.constants.all;

entity control_unit is
    Port ( 
        I_clk : in  STD_LOGIC;
        I_reset : in  STD_LOGIC;
        I_halt: in STD_LOGIC;
        I_aluop : in  STD_LOGIC_VECTOR (6 downto 0);
        
        -- interrupts
        I_int_enabled: in std_logic;
        I_int: in STD_LOGIC;
        O_int_ack: out STD_LOGIC;
        I_int_mem_data: in STD_LOGIC_VECTOR(XLENM1 downto 0);
        O_idata: out STD_LOGIC_VECTOR(XLENM1 downto 0);  
        O_set_idata:out STD_LOGIC;
        O_set_ipc: out STD_LOGIC;
        O_set_irpc: out STD_LOGIC;
        O_instTick: out STD_LOGIC;
        
        -- mem controller state and control
        I_ready: in STD_LOGIC;
        O_execute: out STD_LOGIC;
        I_dataReady: in STD_LOGIC;
        
        O_state : out  STD_LOGIC_VECTOR (6 downto 0)
    );
end control_unit;

architecture Behavioral of control_unit is
	signal s_state: STD_LOGIC_VECTOR(6 downto 0) := "0000001";
	
	signal mem_ready: std_logic;
	signal mem_execute: std_logic:='0';
	signal mem_dataReady: std_logic;
	
	signal mem_cycles : integer := 0;
	
	signal next_s_state: STD_LOGIC_VECTOR(6 downto 0) := "0000001";
	
	signal interrupt_state: STD_LOGIC_VECTOR(2 downto 0) := "000"; 
	signal interrupt_ack: STD_LOGIC := '0';
	signal interrupt_was_inactive: STD_LOGIC := '1';
	signal set_idata:  STD_LOGIC := '0';
	signal set_ipc:   STD_LOGIC := '0';
	signal instTick: STD_LOGIC := '0';
begin

	O_execute <= mem_execute;
	mem_ready <= I_ready;
	mem_dataReady <= I_dataReady;
	O_int_ack <= interrupt_ack;
	O_set_idata <= set_idata;
	O_set_irpc <= set_idata;
	O_set_ipc <= set_ipc;
	O_instTick <= instTick;

	process(I_clk)
	begin
		if rising_edge(I_clk) and I_halt = '0' then
			if I_reset = '1' then
				s_state <= "0000001";
				next_s_state <= "0000001";
				mem_cycles <= 0;
				mem_execute <= '0';
				interrupt_was_inactive <= '1';
				interrupt_ack <= '0';
				interrupt_state <= "000";
				set_ipc <= '0';
				O_idata <= X"00000000";
				set_idata <= '0';
				instTick <= '0';
			else
				case s_state is
					when "0000001" => -- fetch
					     if I_int = '0' then
                            interrupt_was_inactive <= '1';
                        end if;
					    instTick <= '0';
						if mem_cycles = 0 and mem_ready = '1' then
							mem_execute <= '1';
							mem_cycles <= 1;
							
						elsif mem_cycles = 1 then
							mem_execute <= '0';
							mem_cycles <= 2;
							
						elsif mem_cycles = 2 then
							if mem_dataReady = '1' then
								mem_cycles <= 0;
								s_state <= "0000010"; 
							end if;
						end if;
					when "0000010" => --- decode
                                                 if I_int = '0' then
                                                    interrupt_was_inactive <= '1';
                                                end if;
						s_state <= "0001000"; --E "0000100"; --R
					when "0000100" => -- read -- DEPRECATED STAGE
						s_state <= "0001000"; --E
					when "0001000" => -- execute
                                                 if I_int = '0' then
                                                    interrupt_was_inactive <= '1';
                                                end if;
						--MEM/WB
						-- if it's not a memory alu op, goto writeback
						if (I_aluop(6 downto 2) = OPCODE_LOAD or
							 I_aluop(6 downto 2) = OPCODE_STORE) then
							 s_state <= "0010000"; -- MEM
						else
							s_state <= "0100000"; -- WB
						end if;
					when "0010000" => -- mem
                                                 if I_int = '0' then
                                                    interrupt_was_inactive <= '1';
                                                end if;
					-- sometimes memory can be busy, if so we need to relook here
						if mem_cycles = 0 and mem_ready = '1' then
								mem_execute <= '1';
								mem_cycles <= 1;
							
						elsif mem_cycles = 1 then
							mem_execute <= '0';
							-- if it's a write, go through
							if I_aluop(6 downto 2) = OPCODE_STORE then
								mem_cycles <= 0;
								s_state <=  "0100000"; -- WB
							elsif mem_dataReady = '1' then
								-- if read, wait for data
								mem_cycles <= 0;
								s_state <= "0100000"; -- WB
							end if;
						end if;
					when "0100000" => -- writeback
						-- check interrupt?
						if I_int_enabled='1' and interrupt_was_inactive = '1' and I_int = '1' then
							interrupt_ack <= '1';
							interrupt_was_inactive <= '0';
							interrupt_state <= "001";
							next_s_state <= "0000001"; --F
							s_state <= "1000000"; --F
						else
                            if I_int = '0' then
                                interrupt_was_inactive <= '1';
                            end if;
							s_state <= "0000001"; --F
						end if;
					   instTick <= '1';
					when "1000000" => --  stalls
                                                if I_int = '0' then
                                                   interrupt_was_inactive <= '1';
                                               end if;
					   instTick <= '0';
						-- interrupt stall
						if interrupt_state = "001" then 
							-- give a cycle of latency
							-- set PC to interrupt vector.
							
							set_ipc <= '1';
                            interrupt_state <= "101";
                            
                         --   interrupt_ack <= '0';
                        elsif interrupt_state = "101" then
                            set_ipc <= '0';
                            interrupt_ack <= '0';
							interrupt_state <= "111";
						elsif interrupt_state = "111" then
							interrupt_state <= "000";
							s_state <= "0000001"; --F
						end if;
					when "1001000" =>
					   -- alu 1 cycle stall
					   s_state <= "0100000"; -- WB
					when others =>
						s_state <= "0000001";
				end case;
			end if;
		end if;
	end process;

	O_state <= s_state;
end Behavioral;



