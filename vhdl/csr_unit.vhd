----------------------------------------------------------------------------------
-- Project Name:  RISC-V CPU
-- Description: CSR unit RV32I
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
           
           -- interrupt handling causes many data dependencies
           -- mcause has a fast path in from other units
           I_int_cause: in STD_LOGIC_VECTOR (XLENM1 downto 0);
           I_int_pc: in STD_LOGIC_VECTOR (XLENM1 downto 0);
           -- We need to know when an interrupt occurs as to perform the
           -- relevant csr modifications. Same with exit.
           I_int_entry: IN STD_LOGIC;
           I_int_exit: IN STD_LOGIC;
           
           -- Currently just feeds machine level CSR values
           O_csr_status : out STD_LOGIC_VECTOR (XLENM1 downto 0);
           O_csr_cause : out STD_LOGIC_VECTOR (XLENM1 downto 0);
           O_csr_ie : out STD_LOGIC_VECTOR (XLENM1 downto 0);
           O_csr_tvec : out STD_LOGIC_VECTOR (XLENM1 downto 0);
           O_csr_epc : out STD_LOGIC_VECTOR (XLENM1 downto 0)
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


constant CSR_ADDR_TEST_400:     STD_LOGIC_VECTOR (11 downto 0) := X"400";
constant CSR_ADDR_TEST_401:     STD_LOGIC_VECTOR (11 downto 0) := X"401";

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

-- Will allow some other CSRS to make for easier running of third party sw
constant CSR_ADDR_VEXRISC_IRQ_MASK:     STD_LOGIC_VECTOR (11 downto 0) := X"bc0";
constant CSR_ADDR_VEXRISC_IRQ_PENDING:     STD_LOGIC_VECTOR (11 downto 0) := X"fc0";

signal csr_cycles: STD_LOGIC_VECTOR(63 downto 0) := (others => '0');
signal csr_instret: STD_LOGIC_VECTOR(63 downto 0) := (others => '0');

signal csr_mstatus : STD_LOGIC_VECTOR (XLENM1 downto 0) := X"00000000";-- X"00001800"; -- MIE default 1
signal csr_mie : STD_LOGIC_VECTOR (XLENM1 downto 0) := (others => '0');
signal csr_mtvec : STD_LOGIC_VECTOR (XLENM1 downto 0) := X"00000004";-- X"00000010";
signal csr_mscratch : STD_LOGIC_VECTOR (XLENM1 downto 0) := (others => '0');
signal csr_mepc : STD_LOGIC_VECTOR (XLENM1 downto 0) := (others => '0');
signal csr_mcause : STD_LOGIC_VECTOR (XLENM1 downto 0) := (others => '0');
signal csr_mtval : STD_LOGIC_VECTOR (XLENM1 downto 0) := (others => '0');
signal csr_mip : STD_LOGIC_VECTOR (XLENM1 downto 0) := (others => '0');

signal csr_vexrisc_irq_mask : STD_LOGIC_VECTOR (XLENM1 downto 0) := (others => '0');
signal csr_vexrisc_irq_pending : STD_LOGIC_VECTOR (XLENM1 downto 0) := (others => '0');
           
signal curr_csr_value: STD_LOGIC_VECTOR(XLENM1 downto 0) := (others=> '0');
signal next_csr_value: STD_LOGIC_VECTOR(XLENM1 downto 0) := (others=> '0');

signal test0_CSR: STD_LOGIC_VECTOR(XLENM1 downto 0) := X"FEFbbEF0";
signal test1_CSR: STD_LOGIC_VECTOR(XLENM1 downto 0) := X"FEFbbEF1";

signal csr_op: STD_LOGIC_VECTOR(4 downto 0) := (others=>'0');
signal opState: integer := 0;

signal raise_int: std_logic := '0';

begin

    O_int <= raise_int;
    O_int_data <= X"00000000";
    O_csr_status <= csr_mstatus;
    O_csr_tvec <= csr_mtvec;
    O_csr_cause <= csr_mcause;
    O_csr_ie <= csr_mie;
    O_csr_epc <= csr_mepc;
    
    O_dataOut <= curr_csr_value;

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
        if rising_edge(I_clk)  then
            if (I_csrAddr(CSR_ADDR_ACCESS_BIT_START downto CSR_ADDR_ACCESS_BIT_END) = CSR_ADDR_ACCESS_READONLY) and
               (I_csrOp(CSR_OP_BITS_WRITTEN) = '1') then
               --todo: raise exception
               raise_int <= '1';
            else
               raise_int <= '0';  
            end if;
        end if;
    end process;
        
    -- Read data is available next cycle, with an additional cycle before another op can be processed
    -- Write to CSR occurs 3 cycles later.
    -- cycle 1: read of existing csr available
    -- cycle 2: update value calculates (whole write, set/clear bit read-modify-write)
    -- cycle 3: actual write to csr occurs.
    datamain: process (I_clk, I_en) 
    begin
        if rising_edge(I_clk) then
        
            if I_int_entry = '1' then
                -- on entry:
                -- mstatus.mpie = mstatus.mie
                csr_mstatus(7) <= csr_mstatus(3);
                -- mstatus.mie = 0
                csr_mstatus(3) <= '0';
                -- mstatus.mpp = current privilege mode 
                csr_mstatus(12 downto 11) <= "11";
                
                csr_mcause <= I_int_cause;
                csr_mepc <= I_int_pc;
                
            elsif I_int_exit = '1' then
                -- privilege set to mstatus.mpp
                -- mstatus.mie = mstatus.mpie
                csr_mstatus(3) <= csr_mstatus(7);
                csr_mstatus(7) <= '1';
                csr_mstatus(12 downto 11) <= "00";
                
            -- interrupt data changes take all priority
            elsif I_en = '1' and opState = 0 then             
                csr_op <= I_csrOp;
                case I_csrAddr is
                    when CSR_ADDR_MVENDORID =>
                        curr_csr_value <= X"00000000"; -- JEDEC non-commercial
                    when CSR_ADDR_MARCHID =>
                        curr_csr_value <= X"00000000";
                    when CSR_ADDR_MIMPID =>
                        curr_csr_value <= X"52505530"; -- "RPU0"
                    when CSR_ADDR_MHARDID =>
                        curr_csr_value <= X"00000000";
                    when CSR_ADDR_MISA =>
                        curr_csr_value <= X"40000080";  -- XLEN 32, RV32I
                        
                    when CSR_ADDR_MSTATUS =>
                        curr_csr_value <= csr_mstatus;
                    when CSR_ADDR_MTVEC =>
                        curr_csr_value <= csr_mtvec;
                    when CSR_ADDR_MIE =>
                        curr_csr_value <= csr_mie;
                    when CSR_ADDR_MIP =>
                        curr_csr_value <= csr_mip;
                    when CSR_ADDR_MCAUSE =>
                        curr_csr_value <= csr_mcause;  
                    when CSR_ADDR_MEPC =>
                        curr_csr_value <= csr_mepc;                           
                                
                    when CSR_ADDR_VEXRISC_IRQ_PENDING =>
                        curr_csr_value <= csr_vexrisc_irq_pending;  
                    when CSR_ADDR_VEXRISC_IRQ_MASK =>
                        curr_csr_value <= csr_vexrisc_irq_mask;   
                        
                    when CSR_ADDR_CYCLE =>
                        curr_csr_value <= csr_cycles(31 downto 0);
                    when CSR_ADDR_CYCLEH =>
                        curr_csr_value <= csr_cycles(63 downto 32);
                        
                    when CSR_ADDR_INSTRET =>
                        curr_csr_value <= csr_instret(31 downto 0);
                    when CSR_ADDR_INSTRETH =>
                        curr_csr_value <= csr_instret(63 downto 32);
                        
                    when CSR_ADDR_MCYCLE =>
                        curr_csr_value <= csr_cycles(31 downto 0);
                    when CSR_ADDR_MCYCLEH =>
                        curr_csr_value <= csr_cycles(63 downto 32);
                        
                    when CSR_ADDR_MINSTRET =>
                        curr_csr_value <= csr_instret(31 downto 0);
                    when CSR_ADDR_MINSTRETH =>
                        curr_csr_value <= csr_instret(63 downto 32);
                        
                    when CSR_ADDR_TEST_400 =>
                        curr_csr_value <= test0_CSR;
                    when CSR_ADDR_TEST_401 =>
                        curr_csr_value <= test1_CSR;

                    when others => 
                        -- raise exception for unsupported CSR
                end case;
                opState <= 1;
                
            elsif opState = 1 then
                -- update stage for sets, clears and writes
                case csr_op(3 downto 2) is
                    when CSR_MAINOP_WR =>
                        next_csr_value <= I_dataIn;
                    when CSR_MAINOP_SET =>
                        next_csr_value <= curr_csr_value or I_dataIn;
                    when CSR_MAINOP_CLEAR =>
                        next_csr_value <= curr_csr_value and (not I_dataIn);
                    when others =>
                end case;
                
                if I_csrOp(CSR_OP_BITS_WRITTEN) = '1' then
                   opState <= 2;
                else 
                   opState <= 0;
                end if;
                
            elsif opState = 2 then
                -- write stage
                opState <= 0;
                case I_csrAddr is
                      when CSR_ADDR_TEST_400 =>
                          test0_CSR <= next_csr_value;
                      when CSR_ADDR_TEST_401 =>
                          test1_CSR <= next_csr_value;
                          
                      when CSR_ADDR_MSTATUS =>
                          csr_mstatus <= next_csr_value;
                      when CSR_ADDR_MTVEC =>
                          csr_mtvec <= next_csr_value;
                      when CSR_ADDR_MIE =>
                          csr_mie <= next_csr_value;   
                      when CSR_ADDR_MIP =>
                          csr_mip <= next_csr_value;       
                      when CSR_ADDR_MEPC =>
                          csr_mepc <= next_csr_value;        
                          
                          
                      when CSR_ADDR_VEXRISC_IRQ_PENDING =>
                          csr_vexrisc_irq_pending <= next_csr_value;  
                      when CSR_ADDR_VEXRISC_IRQ_MASK =>
                          csr_vexrisc_irq_mask <= next_csr_value;           
                    when others =>
                end case;
            end if;
          end if;
 
    end process;

end Behavioral;
