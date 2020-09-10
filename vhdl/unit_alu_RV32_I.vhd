----------------------------------------------------------------------------------
-- Project Name: RISC-V CPU
-- Description: ALU unit suitable for RV32I operational use
-- 
----------------------------------------------------------------------------------
-- Copyright 2016,2018,2019,2020  Colin Riley
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

entity alu_RV32I is
    port (
        I_clk : in STD_LOGIC;
        I_en : in STD_LOGIC;
        I_dataA : in STD_LOGIC_VECTOR (XLEN32M1 downto 0);
        I_dataB : in STD_LOGIC_VECTOR (XLEN32M1 downto 0);
        I_dataDwe : in STD_LOGIC;
        I_aluop : in STD_LOGIC_VECTOR (4 downto 0);
        I_aluFunc : in STD_LOGIC_VECTOR (15 downto 0);
        I_PC : in STD_LOGIC_VECTOR (XLEN32M1 downto 0);
        I_epc : in STD_LOGIC_VECTOR (XLENM1 downto 0);
        I_dataIMM : in STD_LOGIC_VECTOR (XLEN32M1 downto 0);
        I_clear : in STD_LOGIC;
        O_dataResult : out STD_LOGIC_VECTOR (XLEN32M1 downto 0);
        O_branchTarget : out STD_LOGIC_VECTOR (XLEN32M1 downto 0);
        O_dataWriteReg : out STD_LOGIC;
        O_lastPC : out STD_LOGIC_VECTOR(XLEN32M1 downto 0);
        O_shouldBranch : out std_logic;
        O_wait : out std_logic
    );
end alu_RV32I;

architecture Behavioral of alu_RV32I is
    -- The internal register for results of operations. 
    -- 32 bit + carry/overflow
    signal s_aluFunc : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
    signal s_branchTarget : STD_LOGIC_VECTOR (XLEN32M1 downto 0) := (others => '0');

    signal s_result : STD_LOGIC_VECTOR(63 downto 0) := (others => '0');
    signal s_resultms : STD_LOGIC_VECTOR(63 downto 0) := (others => '0');
    signal s_resultmu : STD_LOGIC_VECTOR(63 downto 0) := (others => '0');
    signal s_resultmsu : STD_LOGIC_VECTOR(65 downto 0) := (others => '0'); -- result has 66 bits to accomodate mulhsu with it's additional-bit-fakery
    signal s_shouldBranch : STD_LOGIC := '0';
    signal s_lastPC : STD_LOGIC_VECTOR(XLEN32M1 downto 0) := (others => '0');
    signal s_wait : std_logic := '0';
    component alu_int32_div is
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
    end component;
    signal s_div_exec : std_logic := '0';
    signal s_div_dividend : std_logic_vector(31 downto 0) := (others => '0');
    signal s_div_divisor : std_logic_vector(31 downto 0) := (others => '0');
    signal s_div_op : std_logic_vector(1 downto 0) := (others => '0');
    signal s_div_dataResult : std_logic_vector(31 downto 0) := (others => '0');
    signal s_div_done : std_logic := '0';
    signal s_div_int : std_logic := '0';
    constant DIVUNIT_STATE_IDLE : integer := 0;
    constant DIVUNIT_STATE_INFLIGHT : integer := 1;
    constant DIVUNIT_STATE_COMPLETE : integer := 2;

    constant MUL_STATE_IDLE : integer := 0;
    constant MUL_STATE_COMPLETE : integer := 2;

    signal s_mul_state : integer := 0;
    signal s_divunit_state : integer := 0;

begin
    div_rem_unit : alu_int32_div port map(
        I_clk => I_clk,
        I_exec => s_div_exec,
        I_dividend => s_div_dividend,
        I_divisor => s_div_divisor,
        I_op => s_div_op,
        O_dataResult => s_div_dataResult,
        O_done => s_div_done,
        O_int => s_div_int
    );

    s_div_dividend <= I_dataA;
    s_div_divisor <= I_dataB;

    process (I_clk, I_en)
    begin
        if rising_edge(I_clk) then
            if I_clear = '1' and I_en = '0' then
                s_branchTarget <= X"00000000";
                s_result <= X"0000000000000000";

            elsif I_en = '1' then
                s_lastPC <= I_PC;
                O_dataWriteReg <= I_dataDwe;
                s_aluFunc <= I_aluFunc;
                case I_aluop is
                    when OPCODE_OPIMM =>
                        s_wait <= '0';
                        s_shouldBranch <= '0';
                        case I_aluFunc(2 downto 0) is
                            when F3_OPIMM_ADDI =>
                                s_result(31 downto 0) <= std_logic_vector(signed(I_dataA) + signed(I_dataIMM));

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
                                    when others =>
                                end case;
                            when others =>
                        end case;

                    when OPCODE_OP =>

                        if I_aluFunc(9 downto 3) = F7_OP_M_EXT then

                            if I_aluFunc(2) = '0' then -- mul ops
                                if s_mul_state = MUL_STATE_IDLE then
                                    s_resultms(63 downto 0) <= std_logic_vector(signed(I_dataA) * signed(I_dataB));
                                    s_resultmu(63 downto 0) <= std_logic_vector(unsigned(I_dataA) * unsigned(I_dataB));
                                    s_resultmsu(65 downto 0) <= std_logic_vector(signed(I_dataA(31) & I_dataA) * signed('0' & I_dataB));

                                    s_wait <= '0'; -- there is _always_ a 1 cycle additional wait for a multicycle alu, so immediately flag complete
                                    s_mul_state <= MUL_STATE_COMPLETE;

                                elsif s_mul_state = MUL_STATE_COMPLETE then

                                    if I_aluFunc(2 downto 0) = F3_OP_M_MUL then
                                        s_result(31 downto 0) <= s_resultms(31 downto 0);

                                    elsif I_aluFunc(2 downto 0) = F3_OP_M_MULH then
                                        s_result(31 downto 0) <= s_resultms(63 downto 32);

                                    elsif I_aluFunc(2 downto 0) = F3_OP_M_MULHU then
                                        s_result(31 downto 0) <= s_resultmu(63 downto 32);

                                    elsif I_aluFunc(2 downto 0) = F3_OP_M_MULHSU then
                                        s_result(31 downto 0) <= s_resultmsu(63 downto 32);
                                    end if;

                                    s_mul_state <= MUL_STATE_IDLE;

                                end if;
                            else
                                -- div & rem
                                if s_divunit_state = DIVUNIT_STATE_IDLE then
                                    s_div_exec <= '1';
                                    s_div_op <= I_aluFunc(1 downto 0);
                                    s_divunit_state <= DIVUNIT_STATE_INFLIGHT;

                                    s_wait <= '1'; -- stall the cpu until done
                                elsif s_divunit_state = DIVUNIT_STATE_INFLIGHT then
                                    s_div_exec <= '0';

                                    if s_div_done = '1' then
                                        s_divunit_state <= DIVUNIT_STATE_COMPLETE;
                                        s_wait <= '0';
                                    end if;
                                elsif s_divunit_state = DIVUNIT_STATE_COMPLETE then

                                    s_divunit_state <= DIVUNIT_STATE_IDLE;
                                    s_result(31 downto 0) <= s_div_dataResult;
                                end if;

                            end if;
                        else
                            s_wait <= '0';
                            case I_aluFunc(9 downto 0) is
                                when F7_OP_ADD & F3_OP_ADD =>
                                    s_result(31 downto 0) <= std_logic_vector(signed(I_dataA) + signed(I_dataB));

                                when F7_OP_SUB & F3_OP_SUB =>
                                    s_result(31 downto 0) <= std_logic_vector(signed(I_dataA) - signed(I_dataB));

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

                                when others =>
                                    s_result <= X"00000000" & X"CDC1FEF1";
                            end case;
                        end if;
                        s_shouldBranch <= '0';

                    when OPCODE_LOAD | OPCODE_STORE =>
                        s_wait <= '0';
                        s_shouldBranch <= '0';
                        s_result(31 downto 0) <= std_logic_vector(signed(I_dataA) + signed(I_dataIMM));

                    when OPCODE_JALR =>
                        s_wait <= '0';
                        s_branchTarget <= std_logic_vector(signed(I_dataA) + signed(I_dataIMM)) and X"FFFFFFFE"; -- jalr clears the lowest bit
                        s_shouldBranch <= '1';
                        s_result(31 downto 0) <= std_logic_vector(signed(I_PC) + 4);

                    when OPCODE_JAL =>
                        s_wait <= '0';
                        s_branchTarget <= std_logic_vector(signed(I_PC) + signed(I_dataIMM));
                        s_shouldBranch <= '1';
                        s_result(31 downto 0) <= std_logic_vector(signed(I_PC) + 4);

                    when OPCODE_SYSTEM =>
                        s_wait <= '0';
                        if I_aluFunc(9 downto 0) = F7_PRIVOP_MRET & F3_PRIVOP then
                            s_branchTarget <= I_epc;
                            s_shouldBranch <= '1';
                            s_result(31 downto 0) <= std_logic_vector(signed(I_PC) + 4);
                        elsif I_aluFunc(2 downto 0) /= F3_PRIVOP then
                            -- do not branch on CSR unit work
                            s_shouldBranch <= '0';
                        end if;
                    when OPCODE_LUI =>
                        s_wait <= '0';
                        s_shouldBranch <= '0';
                        s_result(31 downto 0) <= I_dataIMM;

                    when OPCODE_AUIPC =>
                        s_wait <= '0';
                        s_shouldBranch <= '0';
                        s_result(31 downto 0) <= std_logic_vector(signed(I_PC) + signed(I_dataIMM));

                    when OPCODE_BRANCH =>
                        s_wait <= '0';
                        s_branchTarget <= std_logic_vector(signed(I_PC) + signed(I_dataIMM));
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
                        s_result <= X"00000000" & X"CDCDFEFE";
                end case;
            end if;
        end if;
    end process;

    O_wait <= s_wait;

    O_dataResult <= s_result(XLEN32M1 downto 0);
    O_shouldBranch <= s_shouldBranch;
    O_branchTarget <= s_branchTarget;
    O_lastPC <= s_lastPC;

end Behavioral;