----------------------------------------------------------------------------------
-- Project Name: RPU
-- Description: RPU core glue entity
--
--  Brings all core components together with a little logic.
--  This is the CPU interface required.
-- 
----------------------------------------------------------------------------------
-- Copyright 2018,2019,2020 Colin Riley
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

library work;
use work.constants.all;

entity core is
    port (
        I_clk : in STD_LOGIC;
        I_reset : in STD_LOGIC;
        I_halt : in STD_LOGIC;

        -- External Interrupt interface
        I_int_data : in STD_LOGIC_VECTOR(31 downto 0);
        I_int : in STD_LOGIC;
        O_int_ack : out STD_LOGIC;

        -- memory interface
        MEM_I_ready : in std_logic;
        MEM_O_cmd : out std_logic;
        MEM_O_we : out std_logic;
        -- fixme: this is not a true byteEnable and so is confusing.
        -- Will be fixed when memory swizzling is brought core-size
        MEM_O_byteEnable : out std_logic_vector(1 downto 0);
        MEM_O_addr : out std_logic_vector(XLEN32M1 downto 0);
        MEM_O_data : out std_logic_vector(XLEN32M1 downto 0);
        MEM_I_data : in std_logic_vector(XLEN32M1 downto 0);
        MEM_I_dataReady : in std_logic

        ; -- This debug output contains some internal state for debugging
        O_halted : out std_logic;
        O_DBG : out std_logic_vector(63 downto 0)
    );
end core;

architecture Behavioral of core is
    component pc_unit
        port (
            I_clk : in std_logic;
            I_nPC : in std_logic_vector(XLENM1 downto 0);
            I_nPCop : in std_logic_vector(1 downto 0);
            I_intVec : in std_logic;
            O_PC : out std_logic_vector(XLENM1 downto 0)
        );
    end component;

    component control_unit
        port (
            I_clk : in STD_LOGIC;
            I_halt : in STD_LOGIC;
            I_reset : in STD_LOGIC;
            I_aluop : in STD_LOGIC_VECTOR (6 downto 0);
            O_state : out STD_LOGIC_VECTOR (6 downto 0);

            I_int : in STD_LOGIC;
            O_int_ack : out STD_LOGIC;

            I_int_enabled : in STD_LOGIC;
            I_int_mem_data : in STD_LOGIC_VECTOR(XLENM1 downto 0);
            O_idata : out STD_LOGIC_VECTOR(XLENM1 downto 0);
            O_set_idata : out STD_LOGIC;
            O_set_ipc : out STD_LOGIC;
            O_set_irpc : out STD_LOGIC;
            O_instTick : out STD_LOGIC;

            I_misalignment : in STD_LOGIC;
            I_ready : in STD_LOGIC;
            O_execute : out STD_LOGIC;
            I_dataReady : in STD_LOGIC;
            I_aluMultiCy : in STD_LOGIC;
            I_aluWait : in STD_LOGIC
        );
    end component;
    component decoder_RV32
        port (
            I_clk : in std_logic;
            I_en : in std_logic;
            I_dataInst : in std_logic_vector(31 downto 0);
            O_selRS1 : out std_logic_vector(4 downto 0);
            O_selRS2 : out std_logic_vector(4 downto 0);
            O_selD : out std_logic_vector(4 downto 0);
            O_dataIMM : out std_logic_vector(31 downto 0);
            O_regDwe : out std_logic;
            O_aluOp : out std_logic_vector(6 downto 0);
            O_aluFunc : out std_logic_vector(15 downto 0);
            O_memOp : out STD_LOGIC_VECTOR(4 downto 0);
            O_csrOP : out STD_LOGIC_VECTOR(4 downto 0);
            O_csrAddr : out STD_LOGIC_VECTOR(11 downto 0);
            O_trapExit : out STD_LOGIC;
            O_multycyAlu : out STD_LOGIC;
            O_int : out STD_LOGIC;
            O_int_data : out STD_LOGIC_VECTOR (31 downto 0);
            I_int_ack : in STD_LOGIC
        );
    end component;
    component alu_RV32I is
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
    end component;

    component register_set
        port (
            I_clk : in std_logic;
            I_en : in std_logic;
            I_dataD : in std_logic_vector(31 downto 0);
            I_selRS1 : in std_logic_vector(4 downto 0);
            I_selRS2 : in std_logic_vector(4 downto 0);
            I_selD : in std_logic_vector(4 downto 0);
            I_we : in std_logic;
            O_dataA : out std_logic_vector(31 downto 0);
            O_dataB : out std_logic_vector(31 downto 0)
        );
    end component;

    component csr_unit
        port (
            I_clk : in STD_LOGIC;
            I_en : in STD_LOGIC;

            I_dataIn : in STD_LOGIC_VECTOR(XLENM1 downto 0);
            O_dataOut : out STD_LOGIC_VECTOR(XLENM1 downto 0);

            I_csrOp : in STD_LOGIC_VECTOR (4 downto 0);
            I_csrAddr : in STD_LOGIC_VECTOR (11 downto 0);

            -- This unit can raise exceptions
            O_int : out STD_LOGIC;
            O_int_data : out STD_LOGIC_VECTOR (31 downto 0);

            I_instRetTick : in STD_LOGIC;
            -- interrupt handling causes many data dependencies
            -- mcause has a fast path in from other units
            I_int_cause : in STD_LOGIC_VECTOR (XLENM1 downto 0);
            I_int_pc : in STD_LOGIC_VECTOR (XLENM1 downto 0);
            I_int_mtval : in STD_LOGIC_VECTOR (XLENM1 downto 0);
            -- We need to know when an interrupt occurs as to perform the
            -- relevant csr modifications. Same with exit.
            I_int_entry : in STD_LOGIC;
            I_int_exit : in STD_LOGIC;

            -- Currently just feeds machine level CSR values
            O_csr_status : out STD_LOGIC_VECTOR (XLENM1 downto 0);
            O_csr_cause : out STD_LOGIC_VECTOR (XLENM1 downto 0);
            O_csr_ie : out STD_LOGIC_VECTOR (XLENM1 downto 0);
            O_csr_tvec : out STD_LOGIC_VECTOR (XLENM1 downto 0);
            O_csr_epc : out STD_LOGIC_VECTOR (XLENM1 downto 0)
        );
    end component;

    component lint_unit
        port (
            I_clk : in STD_LOGIC;
            I_reset : in STD_LOGIC;
            I_nextPc : in STD_LOGIC_VECTOR (31 downto 0);
            I_enMask : in STD_LOGIC_VECTOR (3 downto 0);
            I_pc : in STD_LOGIC_VECTOR (31 downto 0);
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
    end component;

    component mem_controller
        port (
            I_clk : in std_logic;
            I_reset : in std_logic;
            O_ready : out std_logic;
            I_execute : in std_logic;
            I_dataWe : in std_logic;
            I_address : in std_logic_vector(XLENM1 downto 0);
            I_data : in std_logic_vector(XLENM1 downto 0);
            I_dataByteEn : in std_logic_vector(1 downto 0);
            I_signExtend : in STD_LOGIC;
            O_data : out std_logic_vector(XLENM1 downto 0);
            O_dataReady : out std_logic;
            MEM_I_ready : in std_logic;
            MEM_O_cmd : out std_logic;
            MEM_O_we : out std_logic;
            MEM_O_byteEnable : out std_logic_vector(1 downto 0);
            MEM_O_addr : out std_logic_vector(XLENM1 downto 0);
            MEM_O_data : out std_logic_vector(XLENM1 downto 0);
            MEM_I_data : in std_logic_vector(XLENM1 downto 0);
            MEM_I_dataReady : in std_logic
        );
    end component;
    signal state : std_logic_vector(6 downto 0) := (others => '0');
    signal pcop : std_logic_vector(1 downto 0);
    signal in_pc : std_logic_vector(XLENM1 downto 0);

    signal aluFunc : std_logic_vector(15 downto 0);
    signal memOp : std_logic_vector(4 downto 0);
    signal branchTarget : std_logic_vector(XLENM1 downto 0) := (others => '0');

    signal instruction : std_logic_vector(XLENM1 downto 0) := (others => '0');
    signal dataA : std_logic_vector(XLENM1 downto 0) := (others => '0');
    signal dataB : std_logic_vector(XLENM1 downto 0) := (others => '0');
    signal dataDwe : std_logic := '0';
    signal aluop : std_logic_vector(6 downto 0) := (others => '0');
    signal dataIMM : std_logic_vector(XLENM1 downto 0) := (others => '0');
    signal selRS1 : std_logic_vector(4 downto 0) := (others => '0');
    signal selRS2 : std_logic_vector(4 downto 0) := (others => '0');
    signal selD : std_logic_vector(4 downto 0) := (others => '0');
    signal dataregWrite : std_logic := '0';
    signal dataResult : std_logic_vector(XLENM1 downto 0) := (others => '0');
    signal latchedDataResult : std_logic_vector(XLENM1 downto 0) := (others => '0');
    signal dataWriteReg : std_logic := '0';
    signal shouldBranch : std_logic := '0';
    signal memMode : std_logic := '0';
    signal ram_req_size : std_logic := '0';
    signal alu_wait : std_logic := '0';
    signal alutobemulticycle : std_logic := '0';

    signal decoder_int : STD_LOGIC;
    signal decoder_int_data : STD_LOGIC_VECTOR(XLENM1 downto 0);
    signal decoder_int_ack : STD_LOGIC := '0';
    signal decoder_trap_exit : STD_LOGIC := '0';
    signal reg_en : std_logic := '0';
    signal reg_we : std_logic := '0';

    signal registerWriteData : std_logic_vector(XLENM1 downto 0) := (others => '0');
    signal alu_or_csr_output : std_logic_vector(XLENM1 downto 0) := (others => '0');

    signal en_fetch : std_logic := '0';
    signal en_decode : std_logic := '0';
    signal en_alu : std_logic := '0';
    signal en_csru : std_logic := '0';
    signal en_memory : std_logic := '0';
    signal en_regwrite : std_logic := '0';
    signal en_stall : std_logic := '0';

    signal PC : std_logic_vector(XLENM1 downto 0) := (others => '0');
    signal PC_at_int : std_logic_vector(XLENM1 downto 0) := (others => '0');
    signal lastPC_dec : std_logic_vector(XLENM1 downto 0) := (others => '0');
    signal lastPC_alu : std_logic_vector(XLENM1 downto 0) := (others => '0');
    signal nextPC_stall : std_logic_vector(XLENM1 downto 0) := (others => '0');
    signal mtval : std_logic_vector(XLENM1 downto 0) := (others => '0');
    signal memctl_ready : std_logic;
    signal memctl_execute : std_logic := '0';
    signal memctl_dataWe : std_logic;
    signal memctl_address : std_logic_vector(XLENM1 downto 0);
    signal memctl_in_data : std_logic_vector(XLENM1 downto 0);
    signal memctl_dataByteEn : std_logic_vector(1 downto 0);
    signal memctl_out_data : std_logic_vector(XLENM1 downto 0) := (others => '0');
    signal memctl_dataReady : std_logic := '0';
    signal memctl_size : std_logic_vector(1 downto 0);
    signal memctl_signExtend : std_logic := '0';

    signal PCintVec : STD_LOGIC := '0';

    signal int_idata : STD_LOGIC_VECTOR(XLENM1 downto 0);
    signal int_set_idata : STD_LOGIC;
    signal int_enabled : std_logic := '1';
    signal int_set_irpc : STD_LOGIC;

    signal I_int_entry : STD_LOGIC := '0';
    signal I_int_exit : STD_LOGIC := '0';

    signal csru_int : STD_LOGIC;
    signal csru_int_data : STD_LOGIC_VECTOR(XLENM1 downto 0);
    signal csru_int_ack : STD_LOGIC := '0';

    signal csru_dataIn : STD_LOGIC_VECTOR(XLENM1 downto 0);
    signal csru_dataOut : STD_LOGIC_VECTOR(XLENM1 downto 0);

    signal csru_csrOp : STD_LOGIC_VECTOR (4 downto 0);
    signal csru_csrAddr : STD_LOGIC_VECTOR (11 downto 0);

    signal csru_instRetTick : STD_LOGIC;

    -- Some CSRs are needed in various places easily, so they are distributed
    signal csr_status : STD_LOGIC_VECTOR(XLENM1 downto 0);
    signal csr_tvec : STD_LOGIC_VECTOR(XLENM1 downto 0);
    signal csr_cause : STD_LOGIC_VECTOR (XLENM1 downto 0);
    signal csr_ie : STD_LOGIC_VECTOR (XLENM1 downto 0);
    signal csr_epc : STD_LOGIC_VECTOR (XLENM1 downto 0);
    signal core_clock : STD_LOGIC := '0';

    signal lint_reset : STD_LOGIC := '0';

    signal misalign_hint : STD_LOGIC := '0'; -- a signal that is early for use by the control unit to stop the next fetch
    signal misalign_branch_hint : STD_LOGIC := '0'; -- a signal that is early for use by the control unit to stop the next fetch
    signal misalign_mem_hint : STD_LOGIC := '0'; -- a signal that is early for use by the control unit  

    signal misalign_int : STD_LOGIC := '0';
    signal misalign_int_data : STD_LOGIC_VECTOR(XLENM1 downto 0) := (others => '0');
    signal misalign_int_ack : STD_LOGIC := '0';
    signal lint_int : STD_LOGIC;
    signal lint_int_data : STD_LOGIC_VECTOR(XLENM1 downto 0);

    signal lint_enable_mask : STD_LOGIC_VECTOR (3 downto 0) := (others => '0');

    signal external_int_ack : STD_LOGIC := '0';

    signal dbg_data_line : STD_LOGIC_VECTOR(XLENM1 downto 0);

    signal is_illegal : std_logic := '0';

    signal should_halt : STD_LOGIC := '0';
begin

    should_halt <= I_halt;
    O_halted <= should_halt;
    core_clock <= I_clk;

    memctl : mem_controller port map(
        I_clk => I_clk,
        I_reset => I_reset,

        O_ready => memctl_ready,
        I_execute => memctl_execute,
        I_dataWe => memctl_dataWe,
        I_address => memctl_address,
        I_data => memctl_in_data,
        I_dataByteEn => memctl_dataByteEn,
        I_signExtend => memctl_signExtend,
        O_data => memctl_out_data,
        O_dataReady => memctl_dataReady,

        MEM_I_ready => MEM_I_ready,
        MEM_O_cmd => MEM_O_cmd,
        MEM_O_we => MEM_O_we,
        MEM_O_byteEnable => MEM_O_byteEnable,
        MEM_O_addr => MEM_O_addr,
        MEM_O_data => MEM_O_data,
        MEM_I_data => MEM_I_data,
        MEM_I_dataReady => MEM_I_dataReady
    );

    pcunit : pc_unit port map(
        I_clk => core_clock,
        I_nPC => in_pc,
        I_nPCop => pcop,
        I_intVec => PCintVec,
        O_PC => PC
    );

    control : control_unit port map(
        I_clk => core_clock,
        I_reset => I_reset,
        I_halt => should_halt,
        I_aluop => aluop,

        I_int => lint_int,
        O_int_ack => lint_reset,
        I_int_enabled => int_enabled,
        I_int_mem_data => lint_int_data,
        O_idata => int_idata,
        O_set_idata => int_set_idata,
        O_set_ipc => PCintVec,
        O_set_irpc => int_set_irpc,
        O_instTick => csru_instRetTick,
        I_misalignment => misalign_hint,
        I_ready => memctl_ready,
        O_execute => memctl_execute,
        I_dataReady => memctl_dataReady,
        I_aluWait => alu_wait,
        I_aluMultiCy => alutobemulticycle,
        O_state => state

    );

    decoder : decoder_RV32 port map(
        I_clk => core_clock,
        I_en => en_decode,
        I_dataInst => instruction,
        O_selRS1 => selRS1,
        O_selRS2 => selRS2,
        O_selD => selD,
        O_dataIMM => dataIMM,
        O_regDwe => dataDwe,
        O_aluOp => aluOp,
        O_aluFunc => aluFunc,
        O_memOp => memOp,
        O_csrOp => csru_csrOp,
        O_csrAddr => csru_csrAddr,
        O_trapExit => decoder_trap_exit,
        O_multycyAlu => alutobemulticycle,
        -- This unit can raise exceptions
        O_int => decoder_int,
        O_int_data => decoder_int_data,
        I_int_ack => decoder_int_ack
    );

    alu : alu_RV32I port map(
        I_clk => core_clock,
        I_en => en_alu,
        I_dataA => dataA,
        I_dataB => dataB,
        I_dataDwe => dataDwe,
        I_aluop => aluop(6 downto 2),
        I_aluFunc => aluFunc,
        I_PC => PC,
        I_epc => csr_epc,
        I_dataIMM => dataIMM,
        I_clear => misalign_int,
        O_dataResult => dataResult,
        O_branchTarget => branchTarget,
        O_dataWriteReg => dataWriteReg,
        O_lastPC => lastPC_alu,
        O_shouldBranch => shouldBranch,
        O_wait => alu_wait
    );

    reg : register_set port map(
        I_clk => core_clock,
        I_en => reg_en,
        I_dataD => registerWriteData,
        O_dataA => dataA,
        O_dataB => dataB,
        I_selRS1 => selRS1,
        I_selRS2 => selRS2,
        I_selD => selD,
        I_we => reg_we
    );

    csru : csr_unit port map(

        I_clk => core_clock,
        I_en => en_csru,

        I_dataIn => csru_dataIn,
        O_dataOut => csru_dataOut,

        I_csrOp => csru_csrOp,
        I_csrAddr => csru_csrAddr,

        -- This unit can raise exceptions
        O_int => csru_int,
        O_int_data => csru_int_data,
        --I_int_ack => csru_int_ack,

        I_instRetTick => csru_instRetTick,

        I_int_cause => lint_int_data,
        I_int_pc => PC_at_int,
        I_int_mtval => mtval,

        I_int_entry => I_int_entry,
        I_int_exit => I_int_exit,

        O_csr_status => csr_status,
        O_csr_tvec => csr_tvec,
        O_csr_cause => csr_cause,
        O_csr_ie => csr_ie,
        O_csr_epc => csr_epc
    );

    lint : lint_unit port map(
        I_clk => core_clock,
        I_reset => lint_reset,
        I_nextPc => nextPC_stall,

        I_enMask => lint_enable_mask,
        I_pc => lastPC_dec,

        I_int0 => decoder_int,
        I_int_data0 => decoder_int_data,
        O_int0_ack => decoder_int_ack,

        I_int1 => csru_int,
        I_int_data1 => csru_int_data,
        O_int1_ack => csru_int_ack,

        I_int2 => I_int,
        I_int_data2 => I_int_data,
        O_int2_ack => external_int_ack,
        I_int3 => misalign_int, -- this should be used for misaligned jump and misaligned memory op
        I_int_data3 => misalign_int_data,
        O_int3_ack => misalign_int_ack,

        O_int => lint_int,
        O_int_data => lint_int_data--,
        --     O_int_epc => PC_at_int
    );

    O_int_ack <= external_int_ack;


    state_latcher : process (core_clock)
    begin
        if rising_edge(core_clock) then
            if en_decode = '1' then
                lastPC_dec <= PC;
            end if;
            if state(6) = '1' then
                nextPC_stall <= PC;
            end if;
            if state(0) = '1' then
                instruction <= memctl_out_data;
            end if;
        end if;
    end process;

    -- Register file controls
    reg_en <= en_decode or en_regwrite;
    reg_we <= dataWriteReg and en_regwrite;-- and not misalign_mem_hint;

    -- These are the pipeline stage enable bits
    en_fetch <= state(0);
    en_decode <= state(1);
    en_alu <= state(3);
    en_csru <= state(3) when (aluop(6 downto 2) = OPCODE_SYSTEM and aluFunc(2 downto 0) /= "000") else '0';
    en_memory <= state(4);
    en_regwrite <= state(5);
    en_stall <= state(6);

    -- This decides what the next PC should be
    pcop <= PCU_OP_RESET when I_reset = '1' else
        PCU_OP_ASSIGN when shouldBranch = '1' and state(5) = '1' else
        PCU_OP_INC when shouldBranch = '0' and state(5) = '1' else
        PCU_OP_ASSIGN when PCintvec = '1' else
        PCU_OP_NOP;

    -- this is lint interrupt enable for consuming the interrupt		
    -- misalignment/external/crsu/decoder
    -- Only accept external on ALU stage to prevent issues with externals taking decode int's in fetch cycles
    -- externals are also programmable via csr register bit
    lint_enable_mask <= '1' & (csr_status(3)and state(3)) & '1' & '1';
    -- interrupts are controlled by mstatus.mie - this is proper control unit acceptance
    int_enabled <= '1' when (lint_int_data(31) = '0' and lint_int = '1') else csr_status(3);

    PC_at_int <= branchTarget when (shouldBranch = '1' and lint_int_data(31) = '1' and state(6) = '1' and lint_int = '1') else PC when (lint_int_data(31) = '1' and lint_int = '1') else lastPC_dec;

    -- This tries to find misaligned access issues and forward data to the LINT
    -- theres a hacky thing here in that we ignore misaligned memory ops if the
    -- address has first 4 bits set; as this is the mmio space, and I've got some
    -- misaligned legacy devices/code in various places
    -- additionally, misaligned traps can't handle the latency that the LINT incurs whilst
    -- dealing with priorities, so we have hint signals to insert dummy "int stalls" into the pipeline.
    misalign_branch_hint <= lint_enable_mask(3) when (I_reset = '0' and misalign_int = '0' and en_regwrite = '1' and shouldBranch = '1' and branchTarget(1 downto 0) /= "00") else '0';
    misalign_mem_hint <= lint_enable_mask(3) when (I_reset = '0' and en_memory = '1' and memctl_address(31 downto 28) /= X"F" and ((memctl_dataByteEn = F2_MEM_LS_SIZE_H and memctl_address(0) = '1') or (memctl_dataByteEn = F2_MEM_LS_SIZE_W and memctl_address(1 downto 0) /= "00"))) else '0';
    misalign_hint <= misalign_branch_hint or misalign_mem_hint;

    misalign_int_finder : process (core_clock)
    begin
        if rising_edge(core_clock) then
            if I_reset = '0' and misalign_int = '0' and en_regwrite = '1' and shouldBranch = '1' and branchTarget(1 downto 0) /= "00" then
                -- jump misalign
                misalign_int <= lint_enable_mask(3);
                misalign_int_data <= EXCEPTION_INSTRUCTION_ADDR_MISALIGNED;
                mtval <= branchTarget;

            elsif I_reset = '0' and misalign_int = '0' and en_memory = '1' and memctl_dataByteEn = F2_MEM_LS_SIZE_H and memctl_address(0) = '1' and memctl_address(31 downto 28) /= X"F" then -- dont misalign trap on MMIO (Fxxxxxx addr)
                -- half load misalign
                misalign_int <= lint_enable_mask(3);
                if memctl_dataWe = '0' then
                    misalign_int_data <= EXCEPTION_LOAD_ADDRESS_MISALIGNED;
                else
                    misalign_int_data <= EXCEPTION_STORE_AMO_ADDRESS_MISALIGNED;
                end if;
                mtval <= memctl_address;
                
            elsif I_reset = '0' and misalign_int = '0' and en_memory = '1' and memctl_dataByteEn = F2_MEM_LS_SIZE_W and memctl_address(1 downto 0) /= "00" and memctl_address(31 downto 28) /= X"F" then -- dont misalign trap on MMIO (Fxxxxxx addr)
                -- word load misalign
                misalign_int <= lint_enable_mask(3);
                if memctl_dataWe = '0' then
                    misalign_int_data <= EXCEPTION_LOAD_ADDRESS_MISALIGNED;
                else
                    misalign_int_data <= EXCEPTION_STORE_AMO_ADDRESS_MISALIGNED;
                end if;
                mtval <= memctl_address;

            elsif misalign_int = '1' and misalign_int_ack = '1' then
                misalign_int <= '0';
            end if;
        end if;
    end process;
    
    -- On Interrupt service entry, CSRs need some maintenance.
    -- We need to strobe the CSR unit on this event.
    I_int_entry <= PCintvec;
    -- To detect exit, we strobe using the ALU enable with the decoder trap request bit
    I_int_exit <= decoder_trap_exit and en_alu;

    -- The input PC is just always the branch target output from ALU
    -- todo: tvec needs modified for vectored exceptions
    in_pc <= csr_tvec when PCintvec = '1' else branchTarget;

    -- input data from the register file, or use immediate if the OP specifies it
    csru_dataIn <= dataIMM when csru_csrOp(CSR_OP_BITS_IMM) = '1' else dataA;

    --dbg_data_line can be used to aid debugging cpu issues using trace dumps.
    --dbg_data_line <= csr_tvec when memctl_execute = '1' else csru_dataIn when en_csru = '1' else registerWriteData when state(5) = '1' else X"000000" & "000" & selD when state(3) = '1' else instruction when state(1)='1' else memctl_address;
    --dbg_data_line <= memctl_address when memctl_execute = '1' else MEM_I_data;
    dbg_data_line <= X"ABCDEF01" when (decoder_int_data = EXCEPTION_INSTRUCTION_ILLEGAL and X"00000010" = csr_epc) else csru_dataIn when en_csru = '1' else registerWriteData when state(5) = '1' else X"000000" & "000" & selD when state(3) = '1' else instruction when state(1) = '1' else memctl_address;
    --dbg_data_line <= PC_at_int;--registerWriteData when state(5) = '1' else X"000000" & "000" & selD when state(3) = '1' else instruction when state(1)='1' else csr_epc when ( lint_reset  = '1') else memctl_address;

    is_illegal <= '1' when decoder_int_data = EXCEPTION_INSTRUCTION_ILLEGAL else '0';

    -- The debug output just allows some internal state to be visible outside the core black box
    -- byte 1 - memctrl&dataready
    -- byte 2 - dataWriteReg, int_en, lint_reset, lint_int, interrupt_type_ decoder and csru_int
    -- byte 3 - aluop
    -- byte 4 - state
    -- uint32 - data
    O_DBG <= "0000" & "0" & memctl_execute & memctl_ready & memctl_dataReady & --alutobemulticycle & alu_wait & --
        -- dataWriteReg & int_enabled & lint_reset  & lint_int & lint_int_data(31) & PCintvec & decoder_int & decoder_int_ack &--&csru_int & --I_int & -- 
        dataWriteReg & int_enabled & lint_reset & lint_int & I_int & external_int_ack & decoder_int & decoder_int_ack & --&csru_int & --I_int & -- 
        is_illegal & "00" & aluop(6 downto 2) &
        "0" & state &
        dbg_data_line;

    -- Below statements are for memory interface use.
    memctl_address <= dataResult when en_memory = '1' else PC;
    ram_req_size <= memMode when en_memory = '1' else '0';
    memctl_dataByteEn <= memctl_size when en_memory = '1' else F2_MEM_LS_SIZE_W;
    memctl_in_data <= dataB;
    memctl_dataWe <= '1' when en_memory = '1' and memOp(4 downto 3) = "11" else '0';
    memctl_size <= memOp(1 downto 0);
    memctl_signExtend <= not memOp(2);

    -- This chooses to write registers with memory data or ALU/csr data
    registerWriteData <= memctl_out_data when memOp(4 downto 3) = "10" else dataB when (aluop(6 downto 2) = OPCODE_STORE) else csru_dataOut when (aluop(6 downto 2) = OPCODE_SYSTEM and aluFunc(2 downto 0) /= "000") else dataResult;
end Behavioral;