----------------------------------------------------------------------------------
-- Project Name:  RISC-V CPU
-- Description: decoder unit RV32I
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
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.constants.all;

entity decoder_RV32 is
    port (
        I_clk : in STD_LOGIC;
        I_en : in STD_LOGIC;
        I_dataInst : in STD_LOGIC_VECTOR (31 downto 0); -- Instruction to be decoded
        O_selRS1 : out STD_LOGIC_VECTOR (4 downto 0);   -- Selection out for regrs1
        O_selRS2 : out STD_LOGIC_VECTOR (4 downto 0);   -- Selection out for regrs2
        O_selD : out STD_LOGIC_VECTOR (4 downto 0);     -- Selection out for regD
        O_dataIMM : out STD_LOGIC_VECTOR (31 downto 0); -- Immediate value out
        O_regDwe : out STD_LOGIC;                       -- RegD wrtite enable
        O_aluOp : out STD_LOGIC_VECTOR (6 downto 0);    -- ALU opcode
        O_aluFunc : out STD_LOGIC_VECTOR (15 downto 0); -- ALU function
        O_memOp : out STD_LOGIC_VECTOR(4 downto 0);     -- Memory operation 
        O_csrOP : out STD_LOGIC_VECTOR(4 downto 0);     -- CSR operations
        O_csrAddr : out STD_LOGIC_VECTOR(11 downto 0);  -- CSR address
        O_trapExit : out STD_LOGIC;                     -- request to exit trap handler
        O_multycyAlu : out STD_LOGIC;                   -- is this a multi-cycle alu op?
        O_int : out STD_LOGIC;                          -- is there a trap?
        O_int_data : out STD_LOGIC_VECTOR (31 downto 0);-- trap descriptor
        I_int_ack : in STD_LOGIC                        -- our int is now being serviced
    );
end decoder_RV32;

architecture Behavioral of decoder_RV32 is
    signal s_trapExit : STD_LOGIC := '0';
    signal s_csrOP : STD_LOGIC_VECTOR(4 downto 0) := (others => '0');
    signal s_csrAddr : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
    signal s_int : STD_LOGIC := '0';
    signal s_intdata : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal s_multicy : std_logic := '0';
begin
    O_multycyAlu <= s_multicy;
    O_int <= s_int;
    O_int_data <= s_intdata;
    O_csrOP <= s_csrOP;
    O_csrAddr <= s_csrAddr;
    O_trapExit <= s_trapExit;

    -- Register selects for reads are async
    O_selRS1 <= I_dataInst(R1_START downto R1_END);
    O_selRS2 <= I_dataInst(R2_START downto R2_END);

    process (I_clk, I_en)
    begin

        if rising_edge(I_clk) then
            if I_en = '1' then

                O_selD <= I_dataInst(RD_START downto RD_END);

                O_aluOp <= I_dataInst(OPCODE_START downto OPCODE_END);

                O_aluFunc <= "000000" & I_dataInst(FUNCT7_START downto FUNCT7_END)
                              & I_dataInst(FUNCT3_START downto FUNCT3_END);

                case I_dataInst(OPCODE_START downto OPCODE_END_2) is
                    when OPCODE_LUI =>
                        s_multicy <= '0';
                        s_trapExit <= '0';
                        s_csrOP <= "00000";
                        s_int <= '0';
                        O_regDwe <= '1';
                        O_memOp <= "00000";
                        O_dataIMM <= I_dataInst(IMM_U_START downto IMM_U_END)
                            & "000000000000";
                            
                    when OPCODE_AUIPC =>
                        s_multicy <= '0';
                        s_trapExit <= '0';
                        s_csrOP <= "00000";
                        s_int <= '0';
                        O_regDwe <= '1';
                        O_memOp <= "00000";
                        O_dataIMM <= I_dataInst(IMM_U_START downto IMM_U_END)
                            & "000000000000";
                            
                    when OPCODE_JAL =>
                        s_multicy <= '0';
                        s_trapExit <= '0';
                        s_csrOP <= "00000";
                        s_int <= '0';
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
                        s_multicy <= '0';
                        s_trapExit <= '0';
                        s_csrOP <= "00000";
                        s_int <= '0';
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
                        s_multicy <= '0';
                        s_trapExit <= '0';
                        s_csrOP <= "00000";
                        s_int <= '0';
                        O_regDwe <= '1';
                        O_memOp <= "00000";
                        if I_dataInst(IMM_U_START) = '1' then
                            O_dataIMM <= X"FFFF" & "1111" & I_dataInst(IMM_I_START downto IMM_I_END);
                        else
                            O_dataIMM <= X"0000" & "0000" & I_dataInst(IMM_I_START downto IMM_I_END);
                        end if;

                    when OPCODE_OP =>
                        s_trapExit <= '0';
                        s_csrOP <= "00000";
                        O_memOp <= "00000";

                        -- M based extension ops are multicycle, otherwise they are single-cycle
                        if (I_dataInst(FUNCT7_START downto FUNCT7_END) = F7_OP_M_EXT) then
                            s_multicy <= '1';
                        else
                            s_multicy <= '0';
                        end if;

                        s_int <= '0';
                        O_regDwe <= '1';

                    when OPCODE_LOAD =>
                        s_multicy <= '0';
                        -- Load's opcode is all 0s - but the first two bits of the word should be '11'
                        -- we check this here, because if we do not, null instructions will be treated as loads...
                        if I_dataInst(1 downto 0) = "11" then
                            s_trapExit <= '0';
                            s_csrOP <= "00000";
                            s_int <= '0';
                            O_regDwe <= '1';
                            O_memOp <= "10" & I_dataInst(FUNCT3_START downto FUNCT3_END);
                            if I_dataInst(IMM_U_START) = '1' then
                                O_dataIMM <= X"FFFF" & "1111" & I_dataInst(IMM_I_START downto IMM_I_END);
                            else
                                O_dataIMM <= X"0000" & "0000" & I_dataInst(IMM_I_START downto IMM_I_END);
                            end if;
                        else
                            -- likely a null instruction - fault!
                            s_trapExit <= '0';
                            s_csrOP <= "00000";
                            s_int <= '1'; ---------------
                            s_intdata <= EXCEPTION_INSTRUCTION_ILLEGAL;
                            O_memOp <= "00000";
                            O_regDwe <= '0';
                            O_dataIMM <= I_dataInst(IMM_I_START downto IMM_S_B_END)
                                & "0000000";
                        end if;
                        
                    when OPCODE_STORE =>
                        s_multicy <= '0';
                        s_trapExit <= '0';
                        s_csrOP <= "00000";
                        s_int <= '0';
                        O_regDwe <= '0';
                        O_memOp <= "11" & I_dataInst(FUNCT3_START downto FUNCT3_END);
                        if I_dataInst(IMM_U_START) = '1' then
                            O_dataIMM <= X"FFFF" & "1111" & I_dataInst(IMM_S_A_START downto IMM_S_A_END) & I_dataInst(IMM_S_B_START downto IMM_S_B_END);
                        else
                            O_dataIMM <= X"0000" & "0000" & I_dataInst(IMM_S_A_START downto IMM_S_A_END) & I_dataInst(IMM_S_B_START downto IMM_S_B_END);
                        end if;
                        
                    when OPCODE_BRANCH =>
                        s_multicy <= '0';
                        s_trapExit <= '0';
                        s_csrOP <= "00000";
                        s_int <= '0';
                        O_regDwe <= '0';
                        O_memOp <= "00000";
                        if I_dataInst(IMM_U_START) = '1' then
                            O_dataIMM <= X"FFFF" & "1111" & I_dataInst(7) & I_dataInst(30 downto 25) & I_dataInst(11 downto 8) & '0';
                        else
                            O_dataIMM <= X"0000" & "0000" & I_dataInst(7) & I_dataInst(30 downto 25) & I_dataInst(11 downto 8) & '0';
                        end if;
                        
                    when OPCODE_MISCMEM =>
                        s_multicy <= '0';
                        s_trapExit <= '0';
                        s_csrOP <= "00000";
                        s_int <= '0';
                        O_regDwe <= '0';
                        O_memOp <= "01000";
                        O_dataIMM <= I_dataInst;
                        
                    when OPCODE_SYSTEM =>
                        s_multicy <= '0';
                        O_memOp <= "00000";
                        if I_dataInst(FUNCT3_START downto FUNCT3_END) = F3_PRIVOP then
                            -- ECALL or EBREAK
                            case I_dataInst(IMM_I_START downto IMM_I_END) is
                                when IMM_I_SYSTEM_ECALL =>
                                    -- raise trap, save pc, perform requiredCSR operations
                                    s_trapExit <= '0';
                                    s_csrOP <= "00000";
                                    s_int <= '1';
                                    O_regDwe <= '0';
                                    s_intdata <= EXCEPTION_ENVIRONMENT_CALL_FROM_MMODE;
                                    --todo:  Priv level needs checked as to mask this to user/supervisor/machine level
                                when IMM_I_SYSTEM_EBREAK =>
                                    s_trapExit <= '0';
                                    s_csrOP <= "00000";
                                    s_int <= '1';
                                    s_intdata <= EXCEPTION_BREAKPOINT;
                                    O_regDwe <= '0';
                                when F7_PRIVOP_MRET & R2_PRIV_RET =>
                                    s_trapExit <= '1';
                                    s_csrOP <= "00000";
                                    s_int <= '0';
                                    O_regDwe <= '0';
                                    -- return from interrupt. implement as a branch - alu will branch to epc.
                                when others =>
                            end case;
                        else
                            s_trapExit <= '0';
                            s_int <= '0';
                            -- CSR
                            -- The immediate output is the zero-extended R1 value for Imm-form CSR ops
                            O_dataIMM <= X"000000" & "000" & I_dataInst(R1_START downto R1_END);

                            -- The 12bit immediate in the instruction forms the csr address.
                            s_csrAddr <= I_dataInst(IMM_I_START downto IMM_I_END);

                            -- is there a destination? if not, CSR is not read
                            if I_dataInst(RD_START downto RD_END) = "00000" then
                                s_csrOP(0) <= '0';
                                O_regDwe <= '0';
                            else
                                O_regDwe <= '1';
                                s_csrOP(0) <= '1';
                            end if;

                            -- is there source data? if not, CSR value is not written
                            -- is it's CSRRS/CSRRC/CSRRSI/CSRRCI ONLY! I.E (Func3 and 010) != 0
                            if (I_dataInst(FUNCT3_END + 1) = '1') and I_dataInst(R1_START downto R1_END) = "00000" then
                                s_csrOP(1) <= '0';
                            else
                                s_csrOP(1) <= '1';
                            end if;

                            s_csrOp(4 downto 2) <= I_dataInst(FUNCT3_START downto FUNCT3_END);

                        end if;
                    when others =>
                        s_multicy <= '0';
                        s_trapExit <= '0';
                        s_csrOP <= "00000";
                        s_int <= '1'; ---------------
                        s_intdata <= EXCEPTION_INSTRUCTION_ILLEGAL;
                        O_memOp <= "00000";
                        O_regDwe <= '0';
                        O_dataIMM <= I_dataInst(IMM_I_START downto IMM_S_B_END)
                            & "0000000";
                end case;
            elsif I_int_ack = '1' then
                s_int <= '0';
            end if;
        end if;
    end process;

end Behavioral;