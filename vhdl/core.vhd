----------------------------------------------------------------------------------
-- Project Name: RPU
-- Description: RPU core glue entity
--
--  Brings all core components together with a little logic.
--  This is the CPU interface required.
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
 
library work;
use work.constants.all;
 
entity core is
    Port (
        I_clk : in  STD_LOGIC;
        I_reset : in  STD_LOGIC;
        I_halt : in  STD_LOGIC;
        
        -- External Interrupt interface
        I_int_data: in STD_LOGIC_VECTOR(31 downto 0);
        I_int: in STD_LOGIC;
        O_int_ack: out STD_LOGIC;
        
        -- memory interface
        MEM_I_ready : IN  std_logic;
        MEM_O_cmd : OUT  std_logic;
        MEM_O_we : OUT  std_logic;
        -- fixme: this is not a true byteEnable and so is confusing.
        -- Will be fixed when memory swizzling is brought core-size
        MEM_O_byteEnable : OUT  std_logic_vector(1 downto 0);
        MEM_O_addr : OUT  std_logic_vector(XLEN32M1 downto 0);
        MEM_O_data : OUT  std_logic_vector(XLEN32M1 downto 0);
        MEM_I_data : IN  std_logic_vector(XLEN32M1 downto 0);
        MEM_I_dataReady : IN  std_logic
        
        ; -- This debug output contains some internal state for debugging
        O_DBG:out std_logic_vector(63 downto 0)
	);
end core;

architecture Behavioral of core is
    COMPONENT pc_unit
    PORT(
         I_clk : IN  std_logic;
         I_nPC : IN  std_logic_vector(XLENM1 downto 0);
         I_nPCop : IN  std_logic_vector(1 downto 0);
	     I_intVec: IN std_logic;
         O_PC : OUT std_logic_vector(XLENM1 downto 0)
        );
    END COMPONENT;
	 
    COMPONENT control_unit 
    PORT ( 
        I_clk : in  STD_LOGIC;
        I_reset : in  STD_LOGIC;
        I_aluop : in  STD_LOGIC_VECTOR (6 downto 0);
        O_state : out  STD_LOGIC_VECTOR (6 downto 0);
        
        I_int: in STD_LOGIC;
        O_int_ack: out STD_LOGIC;
        
        I_int_enabled: in STD_LOGIC;
        I_int_mem_data: in STD_LOGIC_VECTOR(XLENM1 downto 0);  
        O_idata: out STD_LOGIC_VECTOR(XLENM1 downto 0);  
        O_set_idata:out STD_LOGIC;
        O_set_ipc: out STD_LOGIC;
        O_set_irpc: out STD_LOGIC;  
        O_instTick: out STD_LOGIC;
        
        I_ready: in STD_LOGIC;
        O_execute: out STD_LOGIC;
        I_dataReady: in STD_LOGIC
         );
    END COMPONENT;

 
    COMPONENT decoder_RV32
    PORT(
         I_clk : IN  std_logic;
         I_en : IN  std_logic;
         I_dataInst : IN  std_logic_vector(31 downto 0);
         O_selRS1 : OUT  std_logic_vector(4 downto 0);
         O_selRS2 : OUT  std_logic_vector(4 downto 0);
         O_selD : OUT  std_logic_vector(4 downto 0);
         O_dataIMM : OUT  std_logic_vector(31 downto 0);
         O_regDwe : OUT  std_logic;
         O_aluOp : OUT  std_logic_vector(6 downto 0);
         O_aluFunc : OUT  std_logic_vector(15 downto 0); 
		 O_memOp : out STD_LOGIC_VECTOR(4 downto 0);
         O_csrOP : out STD_LOGIC_VECTOR(4 downto 0);
         O_csrAddr : out STD_LOGIC_VECTOR(11 downto 0);
         O_int : out STD_LOGIC;                          
         O_int_data : out STD_LOGIC_VECTOR (31 downto 0);
         I_int_ack: in STD_LOGIC 
        );
    END COMPONENT;
 

	 component alu_RV32I is
    Port ( I_clk : in  STD_LOGIC;
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
    end component;
	 
    COMPONENT register_set
    PORT(
         I_clk : IN  std_logic;
         I_en : IN  std_logic;
         I_dataD : IN  std_logic_vector(31 downto 0);
         I_selRS1 : IN  std_logic_vector(4 downto 0);
         I_selRS2 : IN  std_logic_vector(4 downto 0);
         I_selD : IN  std_logic_vector(4 downto 0);
         I_we : IN  std_logic;
         O_dataA : OUT  std_logic_vector(31 downto 0);
         O_dataB : OUT  std_logic_vector(31 downto 0)
        );
    END COMPONENT;
	 
	COMPONENT csr_unit 
    PORT ( 
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
        
       -- mcause has a fast path in from other units
       I_int_cause: in STD_LOGIC_VECTOR (XLENM1 downto 0);
       I_int_pc: in STD_LOGIC_VECTOR (XLENM1 downto 0);
       -- Currently just feeds machine level CSR values
       O_csr_status : out STD_LOGIC_VECTOR (XLENM1 downto 0);
       O_csr_cause : out STD_LOGIC_VECTOR (XLENM1 downto 0);
       O_csr_ie : out STD_LOGIC_VECTOR (XLENM1 downto 0);
       O_csr_tvec : out STD_LOGIC_VECTOR (XLENM1 downto 0);
       O_csr_epc : out STD_LOGIC_VECTOR (XLENM1 downto 0)
    );
    END COMPONENT;
    
    COMPONENT lint_unit 
    PORT ( 
       I_clk : in STD_LOGIC;
       I_reset : in STD_LOGIC;
       I_pc : in STD_LOGIC_VECTOR (31 downto 0);
       I_int0 : in STD_LOGIC;
       I_int_data0 : in STD_LOGIC_VECTOR (31 downto 0);
       O_int0_ack: out STD_LOGIC;
       I_int1 : in STD_LOGIC;
       I_int_data1 : in STD_LOGIC_VECTOR (31 downto 0);
       O_int1_ack: out STD_LOGIC;
       I_int2 : in STD_LOGIC;
       I_int_data2 : in STD_LOGIC_VECTOR (31 downto 0);
       I_int3 : in STD_LOGIC;
       I_int_data3 : in STD_LOGIC_VECTOR (31 downto 0);
       O_int : out STD_LOGIC;
       O_int_data : out STD_LOGIC_VECTOR (31 downto 0);
       O_int_epc : out STD_LOGIC_VECTOR (31 downto 0)
       );
    END COMPONENT;
	 	 
    COMPONENT mem_controller
    PORT(
         I_clk : IN  std_logic;
         I_reset : IN  std_logic;
         O_ready : OUT  std_logic;
         I_execute : IN  std_logic;
         I_dataWe : IN  std_logic;
         I_address : IN  std_logic_vector(XLENM1 downto 0);
         I_data : IN  std_logic_vector(XLENM1 downto 0);
         I_dataByteEn : IN  std_logic_vector(1 downto 0);
         O_data : OUT  std_logic_vector(XLENM1 downto 0);
         O_dataReady : OUT  std_logic;
         MEM_I_ready : IN  std_logic;
         MEM_O_cmd : OUT  std_logic;
         MEM_O_we : OUT  std_logic;
         MEM_O_byteEnable : OUT  std_logic_vector(1 downto 0);
         MEM_O_addr : OUT  std_logic_vector(XLENM1 downto 0);
         MEM_O_data : OUT  std_logic_vector(XLENM1 downto 0);
         MEM_I_data : IN  std_logic_vector(XLENM1 downto 0);
         MEM_I_dataReady : IN  std_logic
        );
    END COMPONENT;

	 
    signal state : std_logic_vector(6 downto 0) := (others => '0');
    
    
    signal pcop: std_logic_vector(1 downto 0);
    signal in_pc: std_logic_vector(XLENM1 downto 0);
    
    signal aluFunc: std_logic_vector(15 downto 0);
    signal memOp: std_logic_vector(4 downto 0);
    
    signal branchTarget:std_logic_vector(XLENM1 downto 0) := (others => '0');
    
    signal instruction : std_logic_vector(XLENM1 downto 0) := (others => '0');
    signal dataA : std_logic_vector(XLENM1 downto 0) := (others => '0');
    signal dataB : std_logic_vector(XLENM1 downto 0) := (others => '0');
    signal dataDwe : std_logic := '0';
    signal aluop : std_logic_vector(6 downto 0) := (others => '0');
    signal dataIMM : std_logic_vector(XLENM1 downto 0) := (others => '0');
    signal selRS1 : std_logic_vector(4 downto 0) := (others => '0');
    signal selRS2 : std_logic_vector(4 downto 0) := (others => '0');
    signal selD : std_logic_vector(4 downto 0) := (others => '0');
    signal dataregWrite: std_logic := '0';
    signal dataResult : std_logic_vector(XLENM1 downto 0) := (others => '0');
    signal dataWriteReg : std_logic := '0';
    signal shouldBranch : std_logic := '0';
    signal memMode : std_logic := '0';
    signal ram_req_size : std_logic := '0';
    
    
    signal decoder_int: STD_LOGIC;
    signal decoder_int_data: STD_LOGIC_VECTOR(XLENM1 downto 0);
    signal decoder_int_ack: STD_LOGIC := '0';
    
    
    signal reg_en: std_logic := '0';
    signal reg_we: std_logic := '0';
    
    signal registerWriteData : std_logic_vector(XLENM1 downto 0) := (others=>'0');
    signal alu_or_csr_output : std_logic_vector(XLENM1 downto 0) := (others=>'0');
    
    signal en_fetch : std_logic := '0';
    signal en_decode : std_logic := '0';
    signal en_alu : std_logic := '0';
    signal en_csru : std_logic := '0';
    signal en_memory : std_logic := '0';
    signal en_regwrite : std_logic := '0';
    signal en_stall : std_logic := '0';
    
    signal PC : std_logic_vector(XLENM1 downto 0) := (others => '0');
    signal PC_at_int : std_logic_vector(XLENM1 downto 0) := (others => '0');
    
    signal memctl_ready :    std_logic;
    signal memctl_execute :   std_logic := '0';
    signal memctl_dataWe :    std_logic;
    signal memctl_address :    std_logic_vector(XLENM1 downto 0);
    signal memctl_in_data :    std_logic_vector(XLENM1 downto 0);
    signal memctl_dataByteEn :   std_logic_vector(1 downto 0);
    signal memctl_out_data :    std_logic_vector(XLENM1 downto 0) := (others => '0');
    signal memctl_dataReady :    std_logic := '0';
    signal memctl_size : std_logic_vector(1 downto 0);
    signal memctl_signExtend: std_logic := '0';
    
    signal PCintVec: STD_LOGIC := '0';
    
    signal int_idata:   STD_LOGIC_VECTOR(XLENM1 downto 0); 
    signal int_set_idata:  STD_LOGIC;
    signal int_enabled: std_logic := '0';
    signal int_set_irpc:  STD_LOGIC;
    
    signal csru_int: STD_LOGIC;
    signal csru_int_data: STD_LOGIC_VECTOR(XLENM1 downto 0);
    signal csru_int_ack: STD_LOGIC := '0';
    
    signal csru_dataIn : STD_LOGIC_VECTOR(XLENM1 downto 0);
    signal csru_dataOut : STD_LOGIC_VECTOR(XLENM1 downto 0);
    
    signal csru_csrOp : STD_LOGIC_VECTOR (4 downto 0);
    signal csru_csrAddr : STD_LOGIC_VECTOR (11 downto 0);

    signal csru_instRetTick : STD_LOGIC;

    -- Some CSRs are needed in various places easily, so they are distributed
    signal csr_status : STD_LOGIC_VECTOR(XLENM1 downto 0);
    signal csr_tvec : STD_LOGIC_VECTOR(XLENM1 downto 0);
    signal csr_cause :  STD_LOGIC_VECTOR (XLENM1 downto 0);
    signal csr_ie :  STD_LOGIC_VECTOR (XLENM1 downto 0);
    signal csr_epc :  STD_LOGIC_VECTOR (XLENM1 downto 0);
        
    
    signal core_clock:STD_LOGIC := '0';

    signal lint_reset: STD_LOGIC := '0';
    signal lint_nothing: STD_LOGIC := '0';
    signal lint_nothing_data: STD_LOGIC_VECTOR(XLENM1 downto 0):= (others => '0');
    signal lint_int: STD_LOGIC;
    signal lint_int_data: STD_LOGIC_VECTOR(XLENM1 downto 0);
    
    signal dbg_data_line: STD_LOGIC_VECTOR(XLENM1 downto 0);
begin
	core_clock <= I_clk;
	
	memctl: mem_controller PORT MAP (
          I_clk => I_clk,
          I_reset => I_reset,
			 
          O_ready => memctl_ready,
          I_execute => memctl_execute,
          I_dataWe => memctl_dataWe,
          I_address => memctl_address,
          I_data => memctl_in_data,
          I_dataByteEn => memctl_dataByteEn,
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

	pcunit: pc_unit Port map (
		I_clk => core_clock,
		I_nPC => in_pc,
		I_nPCop => pcop, 
		I_intVec => PCintVec,
		O_PC => PC
		);

	   control: control_unit PORT MAP (
            I_clk => core_clock,
            I_reset => I_reset,
            I_aluop => aluop,
            
            I_int => lint_int,
            O_int_ack => lint_reset,
            I_int_enabled => int_enabled,
            I_int_mem_data=> lint_int_data,
            O_idata=> int_idata,
            O_set_idata=> int_set_idata,
            O_set_ipc=> PCintVec,
            O_set_irpc => int_set_irpc,
            O_instTick => csru_instRetTick,
            I_ready => memctl_ready,
            O_execute => memctl_execute,
            I_dataReady => memctl_dataReady,
            O_state => state
	   );
			
	   decoder: decoder_RV32 PORT MAP (
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
          -- This unit can raise exceptions
          O_int => decoder_int,
          O_int_data => decoder_int_data,
          I_int_ack => decoder_int_ack
        );
		  
   alu: alu_RV32I PORT MAP (
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
          O_dataResult => dataResult,
          O_branchTarget => branchTarget,
          O_dataWriteReg => dataWriteReg,
          O_shouldBranch => shouldBranch
        );
		  
	reg: register_set PORT MAP (
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
     
    csru: csr_unit PORT MAP (

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
        
        O_csr_status => csr_status,
        O_csr_tvec => csr_tvec,
        O_csr_cause => csr_cause,
        O_csr_ie => csr_ie,
        O_csr_epc => csr_epc
    );
    
    lint: lint_unit PORT MAP (
        I_clk => core_clock,
        I_reset => lint_reset,
        I_pc => PC,
        I_int0 => decoder_int,
        I_int_data0 => decoder_int_data,
        O_int0_ack => decoder_int_ack,
        I_int1 => csru_int,
        I_int_data1 => csru_int_data,
        O_int1_ack => csru_int_ack,
        I_int2 => lint_nothing,
        I_int_data2 => lint_nothing_data,
        I_int3 => lint_nothing,
        I_int_data3 => lint_nothing_data,
        O_int => lint_int,
        O_int_data => lint_int_data,
        O_int_epc => PC_at_int
    );

		  
    -- Register file controls
	reg_en <= en_decode or en_regwrite;
	reg_we <= dataWriteReg and en_regwrite;
		  
    -- These are the pipeline stage enable bits
	en_fetch <= state(0); 
	en_decode <= state(1); 
	en_alu <= '0' when (aluop(6 downto 2) = OPCODE_SYSTEM and aluFunc(2 downto 0) /= "000") else state(3); 
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
		  
    -- The input PC is just always the branch target output from ALU
    -- todo: tvec needs modifiec for vectored exceptions
	in_pc <= csr_tvec when PCintvec = '1' else branchTarget;
	
	-- input data from the register file, or use immediate if the OP specifies it
	csru_dataIn <= dataIMM when csru_csrOp(CSR_OP_BITS_IMM) = '1' else dataA;
	
	dbg_data_line <= registerWriteData when state(5) = '1' else  memctl_address;
	-- The debug output just allows some internal state to be visible outside the core black box
    O_DBG <= "0000" & "00" & memctl_dataReady  & MEM_I_dataReady & dataWriteReg & "0" & lint_reset  & lint_int & "00" & decoder_int & csru_int & "000" & aluop(6 downto 2) & "0" & state & dbg_data_line;-- & registerWriteData(15 downto 0);
    -- byte 1 - memctrl&dataready
    -- byte 2 - dataWriteReg, lint_reset, lint_int, decoder and csru_int
    -- byte 3 - aluop
    -- byte 4 - state
    -- uint32 - data
	
	-- Below statements are for memory interface use.
	memctl_address <= dataResult when en_memory = '1' else PC;
	ram_req_size <= memMode when en_memory = '1' else '0';
	memctl_dataByteEn <= memctl_size when en_memory = '1' else F2_MEM_LS_SIZE_W;
	memctl_in_data <= dataB; 
	memctl_dataWe <= '1' when en_memory = '1' and memOp(4 downto 3) = "11" else '0';
	memctl_size <= memOp(1 downto 0);
	memctl_signExtend <= memOp(2);
	
	-- This chooses to write registers with memory data or ALU/csr data
	registerWriteData <= memctl_out_data when memOp(4 downto 3) = "10" else csru_dataOut when aluop(6 downto 2) = OPCODE_SYSTEM else dataResult;
	
	-- The instructions are delivered from memctl
	instruction <= memctl_out_data;
	
end Behavioral;

