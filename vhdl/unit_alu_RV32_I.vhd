----------------------------------------------------------------------------------
-- Project Name: RISC-V CPU
-- Description: ALU unit suitable for RV32I operational use
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

entity alu_RV32I is
    Port ( 
        I_clk : in  STD_LOGIC;
        I_en : in  STD_LOGIC;
        I_dataA : in  STD_LOGIC_VECTOR (XLEN32M1 downto 0);
        I_dataB : in  STD_LOGIC_VECTOR (XLEN32M1 downto 0);
        I_dataDwe : in STD_LOGIC;
        I_aluop : in  STD_LOGIC_VECTOR (4 downto 0);
        I_aluFunc : in STD_LOGIC_VECTOR (15 downto 0);
        I_PC : in STD_LOGIC_VECTOR (XLEN32M1 downto 0);
        I_epc : in STD_LOGIC_VECTOR (XLENM1 downto 0);
        I_dataIMM : in  STD_LOGIC_VECTOR (XLEN32M1 downto 0);
        O_dataResult : out  STD_LOGIC_VECTOR (XLEN32M1 downto 0);
        O_branchTarget : out  STD_LOGIC_VECTOR (XLEN32M1 downto 0);
        O_dataWriteReg : out STD_LOGIC;
        O_shouldBranch : out std_logic
    );
end alu_RV32I;

architecture Behavioral of alu_RV32I is
    -- The internal register for results of operations. 
    -- 32 bit + carry/overflow
    
    signal s_branchTarget : STD_LOGIC_VECTOR (XLEN32M1 downto 0) := (others => '0');
    signal s_result: STD_LOGIC_VECTOR(XLEN32M1+2 downto 0) := (others => '0');
    signal s_shouldBranch: STD_LOGIC := '0';
begin

	process (I_clk, I_en) 
	begin
		if rising_edge(I_clk) and I_en = '1' then
		   O_dataWriteReg <= I_dataDwe;
			case I_aluop is
			   when OPCODE_OPIMM =>
				  s_shouldBranch <= '0';
				  case I_aluFunc(2 downto 0) is
				    when F3_OPIMM_ADDI =>
					   s_result(31 downto 0) <= std_logic_vector(signed( I_dataA) + signed(  I_dataIMM));
						
					  when F3_OPIMM_XORI =>
						 s_result(31 downto 0) <= I_dataA xor I_dataIMM;
						 
					  when F3_OPIMM_ORI =>
						 s_result(31 downto 0) <= I_dataA or I_dataIMM;
						 
					  when F3_OPIMM_ANDI =>
						 s_result(31 downto 0) <= I_dataA and I_dataIMM;
						 					  
		           when F3_OPIMM_SLTI =>
					    if signed(I_dataA) < signed(I_dataIMM) then
						   s_result(31 downto 0) <= X"00000001";
						 else
   						s_result(31 downto 0) <= X"00000000";
						 end if;
						 
					  when F3_OPIMM_SLTIU =>
					    if unsigned(I_dataA) < unsigned(I_dataIMM) then
						   s_result(31 downto 0) <= X"00000001";
						 else
   						s_result(31 downto 0) <= X"00000000";
						 end if;
						 
					  when F3_OPIMM_SLLI =>
					    s_result(31 downto 0) <= std_logic_vector(shift_left(unsigned(I_dataA), to_integer(unsigned(I_dataIMM(4 downto 0))))); 
						 
					  when F3_OPIMM_SRLI =>
					    case I_aluFunc(9 downto 3) is
						   when F7_OPIMM_SRLI =>
					        s_result(31 downto 0) <= std_logic_vector(shift_right(unsigned(I_dataA), to_integer(unsigned(I_dataIMM(4 downto 0))))); 
						   when F7_OPIMM_SRAI =>
					        s_result(31 downto 0) <= std_logic_vector(shift_right(signed(I_dataA), to_integer(unsigned(I_dataIMM(4 downto 0))))); 
						   when others=>
						 end case;
					 when others =>
				  end case;
						 
	         when OPCODE_OP =>
				  case I_aluFunc(9 downto 0) is
					  when F7_OP_ADD & F3_OP_ADD =>
						 s_result(31 downto 0) <= std_logic_vector(signed( I_dataA) + signed(  I_dataB));
						 
					  when F7_OP_SUB & F3_OP_SUB =>
						 s_result(31 downto 0) <= std_logic_vector(signed(  I_dataA) - signed(  I_dataB));
						 
					  when F7_OP_SLT & F3_OP_SLT =>
					    if signed(I_dataA) < signed(I_dataB) then
						   s_result(31 downto 0) <= X"00000001";
						 else
   						s_result(31 downto 0) <= X"00000000";
						 end if;
						 
					  when F7_OP_SLTU & F3_OP_SLTU =>
					    if unsigned(I_dataA) < unsigned(I_dataB) then
						   s_result(31 downto 0) <= X"00000001";
						 else
   						s_result(31 downto 0) <= X"00000000";
						 end if;
					
					  when F7_OP_XOR & F3_OP_XOR =>
						 s_result(31 downto 0) <= I_dataA xor I_dataB;
						 
					  when F7_OP_OR & F3_OP_OR =>
						 s_result(31 downto 0) <= I_dataA or I_dataB;
						 
					  when F7_OP_AND & F3_OP_AND =>
						 s_result(31 downto 0) <= I_dataA and I_dataB;
					
					  when F7_OP_SLL & F3_OP_SLL =>
					    s_result(31 downto 0) <= std_logic_vector(shift_left(unsigned(I_dataA), to_integer(unsigned(I_dataB(4 downto 0))))); 
						 
					  when F7_OP_SRL & F3_OP_SRL =>
					    s_result(31 downto 0) <= std_logic_vector(shift_right(unsigned(I_dataA), to_integer(unsigned(I_dataB(4 downto 0))))); 
						 
					  when F7_OP_SRA & F3_OP_SRA =>
					    s_result(31 downto 0) <= std_logic_vector(shift_right(signed(I_dataA), to_integer(unsigned(I_dataB(4 downto 0))))); 
						 
					  when others=>
						 s_result <= "00" & X"CDC1FEF1";
				  end case;
					
					s_shouldBranch <= '0';
					
			   when OPCODE_LOAD | OPCODE_STORE =>
				  s_shouldBranch <= '0';
				  s_result(31 downto 0) <= std_logic_vector(signed( I_dataA) + signed( I_dataIMM));
				  
				when OPCODE_JALR =>
				  s_branchTarget <=  std_logic_vector(signed( I_dataA) + signed( I_dataIMM));
				  s_shouldBranch <= '1';
				  s_result(31 downto 0) <= std_logic_vector(signed( I_PC) + 4);
				    
				when OPCODE_JAL =>
				  s_branchTarget <=  std_logic_vector(signed( I_PC) + signed( I_dataIMM));
				  s_shouldBranch <= '1';
				  s_result(31 downto 0) <= std_logic_vector(signed( I_PC) + 4);
				
				when OPCODE_SYSTEM =>
				  if I_aluFunc(9 downto 0) = F7_PRIVOP_MRET&F3_PRIVOP then
				     s_branchTarget <=  I_epc;
                     s_shouldBranch <= '1';
                     s_result(31 downto 0) <= std_logic_vector(signed( I_PC) + 4);
				  end if;
				when OPCODE_LUI =>
				  s_shouldBranch <= '0';
				  s_result(31 downto 0) <= I_dataIMM;
				
				when OPCODE_AUIPC =>
				  s_shouldBranch <= '0';
				  s_result(31 downto 0) <= std_logic_vector( signed( I_PC) + signed(  I_dataIMM));
				
				when OPCODE_BRANCH =>
				  s_branchTarget <=  std_logic_vector(signed( I_PC) + signed( I_dataIMM));
				  case I_aluFunc(2 downto 0) is
				    when F3_BRANCH_BEQ =>
					   if I_dataA = I_dataB then
							s_shouldBranch <= '1';
						else
							s_shouldBranch <= '0';
						end if;
					 
				    when F3_BRANCH_BNE =>
					   if I_dataA /= I_dataB then
							s_shouldBranch <= '1';
						else
							s_shouldBranch <= '0';
						end if;
					 
				    when F3_BRANCH_BLT =>
					   if signed(I_dataA) < signed(I_dataB) then
							s_shouldBranch <= '1';
						else
							s_shouldBranch <= '0';
						end if;
					 
				    when F3_BRANCH_BGE =>
					   if signed(I_dataA) >= signed(I_dataB) then
							s_shouldBranch <= '1';
						else
							s_shouldBranch <= '0';
						end if;
					 
				    when F3_BRANCH_BLTU =>
					   if unsigned(I_dataA) < unsigned(I_dataB) then
							s_shouldBranch <= '1';
						else
							s_shouldBranch <= '0';
						end if;
					 
				    when F3_BRANCH_BGEU =>
					   if unsigned(I_dataA) >= unsigned(I_dataB) then
							s_shouldBranch <= '1';
						else
							s_shouldBranch <= '0';
						end if;
					 
					 when others =>
				  end case;
				  
				when others =>
					s_result <= "00" & X"CDCDFEFE";
			end case;
		end if;
	end process;
	
	O_dataResult <= s_result(XLEN32M1 downto 0);
	O_shouldBranch <= s_shouldBranch;
	O_branchTarget <= s_branchTarget;
	
end Behavioral;