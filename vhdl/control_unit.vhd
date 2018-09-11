----------------------------------------------------------------------------------
-- Project Name: RPU
-- Description: control unit
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.constants.all;

entity control_unit is
    Port ( 
        I_clk : in  STD_LOGIC;
        I_reset : in  STD_LOGIC;
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
	
begin

	O_execute <= mem_execute;
	mem_ready <= I_ready;
	mem_dataReady <= I_dataReady;
	O_int_ack <= interrupt_ack;
	O_set_idata <= set_idata;
	O_set_irpc <= set_idata;
	O_set_ipc <= set_ipc;

	process(I_clk)
	begin
		if rising_edge(I_clk) then
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
			else
				if I_int = '0' then
					interrupt_was_inactive <= '1';
				end if;
				case s_state is
					when "0000001" => -- fetch
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
						s_state <= "0001000"; --E "0000100"; --R
					when "0000100" => -- read -- DEPRECATED STAGE
						s_state <= "0001000"; --E
					when "0001000" => -- execute
						--MEM/WB
						-- if it's not a memory alu op, goto writeback
						if (I_aluop(6 downto 2) = OPCODE_LOAD or
							 I_aluop(6 downto 2) = OPCODE_STORE) then
							 s_state <= "0010000"; -- MEM
						else
							s_state <= "0100000"; -- WB
						end if;
					when "0010000" => -- mem
					-- sometimes memory can be busy, if so we need to relook here
						if mem_cycles = 0 and mem_ready = '1' then
								mem_execute <= '1';
								mem_cycles <= 1;
							
						elsif mem_cycles = 1 then
							mem_execute <= '0';
							-- if it's a write, go through
							if I_aluop(6 downto 2) = OPCODE_STORE then
								mem_cycles <= 0;
								s_state <= "0100001";-- "0100000"; -- WB
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
							s_state <= "0000001"; --F
						end if;
					
					when "1000000" => --  stalls
						-- interrupt stall
						if interrupt_state = "001" then 
							-- give a cycle of latency
							interrupt_state <= "010";
						elsif interrupt_state = "010" then 
							-- sample input data for state?
							O_idata <= I_int_mem_data;
							set_idata <= '1';
							interrupt_state <= "100";
						elsif interrupt_state = "100" then 
							set_idata <= '0';
							-- set PC to interrupt vector.
							set_ipc <= '1';
							interrupt_state <= "101";
						elsif interrupt_state = "101" then
							set_ipc <= '0';
							interrupt_ack <= '0';
							interrupt_state <= "000";
							s_state <= "0000001"; --F
						end if;
					
					when others =>
						s_state <= "0000001";
				end case;
			end if;
		end if;
	end process;

	O_state <= s_state;
end Behavioral;



