----------------------------------------------------------------------------------
-- Project Name:  RISC-V CPU
-- Description: decoder unit RV32I
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

entity decoder_RV32 is
    Port ( 
        I_clk    : in STD_LOGIC;
        I_en : in  STD_LOGIC;
        I_dataInst : in  STD_LOGIC_VECTOR (31 downto 0); -- Instruction to be decoded
        O_selRS1 : out  STD_LOGIC_VECTOR (4 downto 0);   -- Selection out for regrs1
        O_selRS2 : out  STD_LOGIC_VECTOR (4 downto 0);   -- Selection out for regrs2
        O_selD : out  STD_LOGIC_VECTOR (4 downto 0);     -- Selection out for regD
        O_dataIMM : out  STD_LOGIC_VECTOR (31 downto 0); -- Immediate value out
        O_regDwe : out  STD_LOGIC;                       -- RegD wrtite enable
        O_aluOp : out  STD_LOGIC_VECTOR (6 downto 0);    -- ALU opcode
        O_aluFunc : out STD_LOGIC_VECTOR (15 downto 0);  -- ALU function
        O_memOp : out STD_LOGIC_VECTOR(4 downto 0);      -- Memory operation 
        O_csrOP : out STD_LOGIC_VECTOR(4 downto 0);      -- CSR operations
        O_csrAddr : out STD_LOGIC_VECTOR(11 downto 0);   -- CSR address
        O_int : out STD_LOGIC;                           -- is there a trap?
        O_int_data : out STD_LOGIC_VECTOR (31 downto 0); -- trap descriptor
        I_int_ack: in STD_LOGIC                          -- our int is now being serviced
    );
end decoder_RV32;

architecture Behavioral of decoder_RV32 is
begin
  -- Register selects for reads are async
	O_selRS1 <= I_dataInst(R1_START downto R1_END);
	O_selRS2 <= I_dataInst(R2_START downto R2_END);
	
	process (I_clk, I_en)
	begin
	    if rising_edge(I_clk) and I_int_ack = '1' then
	       O_int <= '0';
	    end if;
		if rising_edge(I_clk) and I_en = '1' then
		
            O_selD <= I_dataInst(RD_START downto RD_END);
            
            O_aluOp <= I_dataInst(OPCODE_START downto OPCODE_END);
                
            O_aluFunc <= "000000" & I_dataInst(FUNCT7_START downto FUNCT7_END) 
                           & I_dataInst(FUNCT3_START downto FUNCT3_END);

			case I_dataInst(OPCODE_START downto OPCODE_END_2) is
			  when OPCODE_LUI =>
			     O_int <= '0';
				 O_regDwe <= '1';
				 O_memOp <= "00000";
				 O_dataIMM <= I_dataInst(IMM_U_START downto IMM_U_END) 
								& "000000000000";
			  when OPCODE_AUIPC =>
			     O_int <= '0';
				 O_regDwe <= '1';
				 O_memOp <= "00000";
				 O_dataIMM <= I_dataInst(IMM_U_START downto IMM_U_END) 
								& "000000000000";
			  when OPCODE_JAL =>
			     O_int <= '0';
			     if I_dataInst(RD_START downto RD_END) = "00000" then 
					O_regDwe <= '0';
				 else
					O_regDwe <= '1';
				 end if;
				 O_memOp <= "00000";
				 if I_dataInst(IMM_U_START) = '1' then
					O_dataIMM <= "111111111111" & I_dataInst(19 downto 12) & I_dataInst(20) & I_dataInst(30 downto 21) & '0';
				 else
					O_dataIMM <= "000000000000" & I_dataInst(19 downto 12) & I_dataInst(20) & I_dataInst(30 downto 21) & '0';
				 end if;
			  when OPCODE_JALR =>
			     O_int <= '0';
			     if I_dataInst(RD_START downto RD_END) = "00000" then 
					O_regDwe <= '0';
				 else
					O_regDwe <= '1';
				 end if;
				 O_memOp <= "00000";
				 if I_dataInst(IMM_U_START) = '1' then
					O_dataIMM <= X"FFFF" & "1111" & I_dataInst(IMM_I_START downto IMM_I_END);
				 else
					O_dataIMM <= X"0000" & "0000" & I_dataInst(IMM_I_START downto IMM_I_END);
				 end if;
			  when OPCODE_OPIMM =>
			     O_int <= '0'; 
				 O_regDwe <= '1';
				 O_memOp <= "00000";
				 if I_dataInst(IMM_U_START) = '1' then
					O_dataIMM <= X"FFFF" & "1111" & I_dataInst(IMM_I_START downto IMM_I_END);
				 else
					O_dataIMM <= X"0000" & "0000" & I_dataInst(IMM_I_START downto IMM_I_END);
				 end if;
			  
              when OPCODE_OP =>
                 O_int <= '0'; 
                 O_regDwe <= '1';
                 O_memOp <= "00000";
			  when OPCODE_LOAD =>
			     O_int <= '0'; 
				 O_regDwe <= '1';
			     O_memOp <= "10" & I_dataInst(FUNCT3_START downto FUNCT3_END);
				 if I_dataInst(IMM_U_START) = '1' then
					O_dataIMM <= X"FFFF" & "1111" & I_dataInst(IMM_I_START downto IMM_I_END);
				 else
					O_dataIMM <= X"0000" & "0000" & I_dataInst(IMM_I_START downto IMM_I_END);
				 end if;
			  when OPCODE_STORE => 
			     O_int <= '0';
				 O_regDwe <= '0';
			     O_memOp <= "11" & I_dataInst(FUNCT3_START downto FUNCT3_END);
				 if I_dataInst(IMM_U_START) = '1' then
					O_dataIMM <= X"FFFF" & "1111" & I_dataInst(IMM_S_A_START downto IMM_S_A_END) & I_dataInst(IMM_S_B_START downto IMM_S_B_END);
				 else
					O_dataIMM <= X"0000" & "0000" & I_dataInst(IMM_S_A_START downto IMM_S_A_END) & I_dataInst(IMM_S_B_START downto IMM_S_B_END);
				 end if;
			  when OPCODE_BRANCH => 
			     O_int <= '0';
				 O_regDwe <= '0';
				 O_memOp <= "00000";
				 if I_dataInst(IMM_U_START) = '1' then
					O_dataIMM <= X"FFFF" & "1111" & I_dataInst(7) & I_dataInst(30 downto 25) & I_dataInst(11 downto 8) & '0';
				 else
					O_dataIMM <= X"0000" & "0000" & I_dataInst(7) & I_dataInst(30 downto 25) & I_dataInst(11 downto 8) & '0';
				 end if;
			  when OPCODE_MISCMEM => 
			      O_int <= '0';
					O_regDwe <= '0';
				  O_memOp <= "01000";
					O_dataIMM <= I_dataInst;
			  when OPCODE_SYSTEM =>
			       O_memOp <= "00000";
			       if I_dataInst(FUNCT3_START downto FUNCT3_END) = F3_PRIVOP then
			           -- ECALL or EBREAK
			          case I_dataInst(IMM_I_START downto IMM_I_END) is
			             when IMM_I_SYSTEM_ECALL =>
			                 -- raise trap, save pc, perform requiredCSR operations
			                 O_int <= '1';
			                 O_int_data <= EXCEPTION_INT_MACHINE_SOFTWARE; 
			                 --todo:  Priv level needs checked as to mask this to user/supervisor/machine level
			             when IMM_I_SYSTEM_EBREAK =>
			                 O_int <= '1';
                             O_int_data <= EXCEPTION_BREAKPOINT;
                             
                         when F7_PRIVOP_MRET & R2_PRIV_RET =>
                             O_int <= '0';
                             O_regDwe <= '0';
                             -- return from interrupt. implement as a branch - alu will branch to epc.
			             when others =>
			          end case;
			       else
			           O_int <= '0';
			           -- CSR
			           -- The immediate output is the zero-extended R1 value for Imm-form CSR ops
                       O_dataIMM <= X"000000" & "000" &  I_dataInst(R1_START downto R1_END);
                       
                       -- The 12bit immediate in the instruction forms the csr address.
                       O_csrAddr <= I_dataInst(IMM_I_START downto IMM_I_END);
                       
                       -- is there a destination? if not, CSR is not read
                       if I_dataInst(RD_START downto RD_END) = "00000" then
                          O_csrOP(0) <= '0';
                          O_regDwe <= '0';
                       else
                          O_regDwe <= '1';
                          O_csrOP(0) <= '1';
                       end if;
                       
                       -- is there source data? if not, CSR value is not written
                      if I_dataInst(R1_START downto R1_END) = "00000" then
                         O_csrOP(1) <= '0';
                      else
                         O_csrOP(1) <= '1';
                      end if;
                           
                      O_csrOp(4 downto 2) <=  I_dataInst(FUNCT3_START downto FUNCT3_END);

			       end if;
              when others =>
                  O_int <= '1';
                  O_int_data <= EXCEPTION_INSTRUCTION_ILLEGAL; 
                  O_memOp <= "00000";
                  O_regDwe  <= '0';
                  O_dataIMM <= I_dataInst(IMM_I_START downto IMM_S_B_END) 
                                    & "0000000";
			end case;
		end if;
	end process;

end Behavioral;

