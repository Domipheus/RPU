----------------------------------------------------------------------------------
-- Project Name:  RISC-V CPU
-- Description: CSR unit RV32I
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

entity csr_unit is
    Port ( I_clk : in STD_LOGIC;
           I_en : in STD_LOGIC;
           I_dataIn : in STD_LOGIC_VECTOR (XLENM1 downto 0);
           O_dataOut : out STD_LOGIC_VECTOR (XLENM1 downto 0);
           I_csrOp : in STD_LOGIC_VECTOR (4 downto 0);
           I_csrAddr : in STD_LOGIC_VECTOR (11 downto 0);
           O_int : out STD_LOGIC;
           O_int_data : out STD_LOGIC_VECTOR (31 downto 0);
           I_instRetTick : in STD_LOGIC;
           O_csr_status : out STD_LOGIC_VECTOR (XLENM1 downto 0);
           O_csr_tvec : out STD_LOGIC_VECTOR (XLENM1 downto 0)
           );
end csr_unit;

architecture Behavioral of csr_unit is

constant CSR_ADDR_USTATUS:     STD_LOGIC_VECTOR (11 downto 0) := X"000";
constant CSR_ADDR_UIE:         STD_LOGIC_VECTOR (11 downto 0) := X"004";
constant CSR_ADDR_UTVEC:       STD_LOGIC_VECTOR (11 downto 0) := X"005";

constant CSR_ADDR_USCRATCH:    STD_LOGIC_VECTOR (11 downto 0) := X"040";
constant CSR_ADDR_UEPC:        STD_LOGIC_VECTOR (11 downto 0) := X"041";
constant CSR_ADDR_UCAUSE:      STD_LOGIC_VECTOR (11 downto 0) := X"042";
constant CSR_ADDR_UTVAL:       STD_LOGIC_VECTOR (11 downto 0) := X"043";
constant CSR_ADDR_UIP:         STD_LOGIC_VECTOR (11 downto 0) := X"044";

constant CSR_ADDR_CYCLE:       STD_LOGIC_VECTOR (11 downto 0) := X"C00";
constant CSR_ADDR_TIME:        STD_LOGIC_VECTOR (11 downto 0) := X"C01";
constant CSR_ADDR_INSTRET:     STD_LOGIC_VECTOR (11 downto 0) := X"C02";

constant CSR_ADDR_CYCLEH:      STD_LOGIC_VECTOR (11 downto 0) := X"C80";
constant CSR_ADDR_TIMEH:       STD_LOGIC_VECTOR (11 downto 0) := X"C81";
constant CSR_ADDR_INSTRETH:    STD_LOGIC_VECTOR (11 downto 0) := X"C82";

constant CSR_ADDR_MSTATUS:     STD_LOGIC_VECTOR (11 downto 0) := X"300";
constant CSR_ADDR_MISA:        STD_LOGIC_VECTOR (11 downto 0) := X"301";
constant CSR_ADDR_MEDELEG:     STD_LOGIC_VECTOR (11 downto 0) := X"302";
constant CSR_ADDR_MIDELEG:     STD_LOGIC_VECTOR (11 downto 0) := X"303";
constant CSR_ADDR_MIE:         STD_LOGIC_VECTOR (11 downto 0) := X"304";
constant CSR_ADDR_MTVEC:       STD_LOGIC_VECTOR (11 downto 0) := X"305";
constant CSR_ADDR_MCOUNTEREN:  STD_LOGIC_VECTOR (11 downto 0) := X"306";

constant CSR_ADDR_MSCRATCH:    STD_LOGIC_VECTOR (11 downto 0) := X"340";
constant CSR_ADDR_MEPC:        STD_LOGIC_VECTOR (11 downto 0) := X"341";
constant CSR_ADDR_MCAUSE:      STD_LOGIC_VECTOR (11 downto 0) := X"342";
constant CSR_ADDR_MTVAL:       STD_LOGIC_VECTOR (11 downto 0) := X"343";
constant CSR_ADDR_MIP:         STD_LOGIC_VECTOR (11 downto 0) := X"344";

constant CSR_ADDR_MCYCLE:      STD_LOGIC_VECTOR (11 downto 0) := X"B00";
constant CSR_ADDR_MINSTRET:    STD_LOGIC_VECTOR (11 downto 0) := X"B02";

constant CSR_ADDR_MCYCLEH:     STD_LOGIC_VECTOR (11 downto 0) := X"B80";
constant CSR_ADDR_MINSTRETH:   STD_LOGIC_VECTOR (11 downto 0) := X"B82";

constant CSR_ADDR_MVENDORID:   STD_LOGIC_VECTOR (11 downto 0) := X"F11";
constant CSR_ADDR_MARCHID:     STD_LOGIC_VECTOR (11 downto 0) := X"F12";
constant CSR_ADDR_MIMPID:      STD_LOGIC_VECTOR (11 downto 0) := X"F13";
constant CSR_ADDR_MHARDID:     STD_LOGIC_VECTOR (11 downto 0) := X"F14";

signal csr_cycles: STD_LOGIC_VECTOR(63 downto 0) := (others => '0');
signal csr_instret: STD_LOGIC_VECTOR(63 downto 0) := (others => '0');


signal csr_status : STD_LOGIC_VECTOR (XLENM1 downto 0) := (others => '0');
signal csr_tvec : STD_LOGIC_VECTOR (XLENM1 downto 0) := (others => '0');
           
begin

    O_csr_status <= csr_status;
    O_csr_tvec <= csr_tvec;

    cycles: process (I_clk)
    begin
        if rising_edge(I_clk) then
            csr_cycles <= std_logic_vector(unsigned(csr_cycles) + 1);
        end if;
    end process;
    
    instret: process (I_clk)
    begin
        if rising_edge(I_clk) and I_instRetTick='1' then
            csr_instret <= std_logic_vector(unsigned(csr_instret) + 1);
        end if;
    end process;
    
    protection: process (I_clk, I_en) 
    begin
        if rising_edge(I_clk) and I_en = '1' then
            if (I_csrAddr(CSR_ADDR_ACCESS_BIT_START downto CSR_ADDR_ACCESS_BIT_END) = CSR_ADDR_ACCESS_READONLY) and
               (I_csrOp(CSR_OP_BITS_WRITTEN) = '1') then
               --todo: raise exception
            end if;
        end if;
    end process;
        
    datamain: process (I_clk, I_en) 
    begin
        if rising_edge(I_clk) and I_en = '1' then
            case I_csrAddr is
                when CSR_ADDR_MVENDORID =>
                    O_dataOut <= X"00000000"; -- JEDEC non-commercial
                when CSR_ADDR_MARCHID =>
                    O_dataOut <= X"00000000";
                when CSR_ADDR_MIMPID =>
                    O_dataOut <= X"52505530"; -- "RPU0"
                when CSR_ADDR_MHARDID =>
                    O_dataOut <= X"00000000";
                    
                when CSR_ADDR_MISA =>
                    O_dataOut <= X"40000080";  -- XLEN 32, RV32I
                    
                    
                when CSR_ADDR_CYCLE =>
                    O_dataOut <= csr_cycles(31 downto 0);
                when CSR_ADDR_CYCLEH =>
                    O_dataOut <= csr_cycles(63 downto 32);
                    
                when CSR_ADDR_INSTRET =>
                    O_dataOut <= csr_cycles(31 downto 0);
                when CSR_ADDR_INSTRETH =>
                    O_dataOut <= csr_cycles(63 downto 32);
                    
                when CSR_ADDR_MCYCLE =>
                    O_dataOut <= csr_cycles(31 downto 0);
                when CSR_ADDR_MCYCLEH =>
                    O_dataOut <= csr_cycles(63 downto 32);
                    
                when CSR_ADDR_MINSTRET =>
                    O_dataOut <= csr_cycles(31 downto 0);
                when CSR_ADDR_MINSTRETH =>
                    O_dataOut <= csr_cycles(63 downto 32);
                when others =>
            end case;
        end if;
    end process;

end Behavioral;
