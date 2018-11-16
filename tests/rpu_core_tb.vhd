----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.11.2018 22:51:11
-- Design Name: 
-- Module Name: rpu_core_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library work;
use work.constants.all;

entity rpu_core_tb is
--  Port ( );
end rpu_core_tb;

architecture Behavioral of rpu_core_tb is


    -- The RPU core definition
    COMPONENT core
        PORT(
            I_clk : IN  std_logic;
            I_reset : IN  std_logic;
            I_halt : IN  std_logic;
                  -- External Interrupt interface
            I_int_data: in STD_LOGIC_VECTOR(31 downto 0);
            I_int: in STD_LOGIC;
            O_int_ack: out STD_LOGIC;
            
            MEM_O_cmd : OUT  std_logic;
            MEM_O_we : OUT  std_logic;
            
            MEM_O_byteEnable : OUT  std_logic_vector(1 downto 0);
            MEM_O_addr : OUT  std_logic_vector(31 downto 0);
            MEM_O_data : OUT  std_logic_vector(31 downto 0);
            MEM_I_data : IN  std_logic_vector(31 downto 0);
            
            MEM_I_ready : IN  std_logic;
            MEM_I_dataReady : IN  std_logic
            
            ;
            O_DBG:out std_logic_vector(XLEN32M1 downto 0)
        );
    END COMPONENT;
    
    
        signal cEng_core : std_logic := '0';
    signal I_reset : std_logic := '1';
    signal I_halt : std_logic := '0';
    signal I_int : std_logic := '0';
    signal MEM_I_ready : std_logic := '1';
    signal MEM_I_data : std_logic_vector(31 downto 0) := (others => '0');
    signal MEM_I_dataReady : std_logic := '0';

    signal MEM_O_data_swizzed : std_logic_vector(31 downto 0) := (others => '0');
 
    signal O_int_ack : std_logic;
    
    signal MEM_O_cmd : std_logic := '0';
    signal MEM_O_we : std_logic := '0';
    signal MEM_O_byteEnable : std_logic_vector(1 downto 0) := (others => '0');
    signal MEM_O_addr : std_logic_vector(31 downto 0) := (others => '0');
    signal MEM_O_data : std_logic_vector(31 downto 0) := (others => '0');
    
    signal I_int_data:  STD_LOGIC_VECTOR(31 downto 0);
            signal MEM_I_data_raw : std_logic_vector(31 downto 0) := (others => '0');
    
    -- Clock period definitions
    constant I_clk_period : time := 10 ns;
    
    
        signal MEM_readyState: integer := 0;
        
        
        -- SOC_CtrState definitions - running off SOC clock domain
        constant SOC_CtlState_Ready : integer :=  0;
        
        -- IMM SOC control states are immediate 1-cycle latency
        -- i.e. BRAM or explicit IO
        constant SOC_CtlState_IMM_WriteCmdComplete : integer := 9;
        constant SOC_CtlState_IMM_ReadCmdComplete : integer := 6;
        
    signal IO_LEDS: STD_LOGIC_VECTOR(7 downto 0):= (others => '0');
    signal INT_DATA: std_logic_vector(BWIDTHM1 downto 0):= (others => '0');
    signal IO_DATA: std_logic_vector(BWIDTHM1 downto 0):= (others => '0');
    signal DDR3_DATA: std_logic_vector(BWIDTHM1 downto 0):= (others => '0');
    
    -- Block ram management
    signal MEM_64KB_ADDR : std_logic_vector(31 downto 0):= (others => '0');
    signal MEM_BANK_ID : std_logic_vector(15 downto 0):= (others => '0');
    signal MEM_ANY_CS : std_logic := '0';
    signal MEM_WE : std_logic := '0';
    
    signal MEM_CS_BRAM_1 : std_logic := '0';
    signal MEM_CS_BRAM_2 : std_logic := '0';
    signal MEM_CS_BRAM_3 : std_logic := '0';
    
        signal mI_wea : STD_LOGIC_VECTOR ( 3 downto 0 ):= (others => '0');
    
    signal MEM_CS_DDR3 : std_logic := '0';
    
    signal MEM_CS_SYSTEM : std_logic := '0';
    
    signal MEM_DATA_OUT_BRAM_1: std_logic_vector(BWIDTHM1 downto 0):= (others => '0');
    signal MEM_DATA_OUT_BRAM_2: std_logic_vector(BWIDTHM1 downto 0):= (others => '0');
    signal MEM_DATA_OUT_BRAM_3: std_logic_vector(BWIDTHM1 downto 0):= (others => '0');
   
    
        signal    O_DBG: std_logic_vector(XLEN32M1 downto 0);
        
        
         type rom_type is array (0 to 31)
               of std_logic_vector(31 downto 0);
               
     constant ROM: rom_type:=(   
     X"00008137", --   lui      sp,0x8
     X"ffc10113", --   addi     sp,sp,-4 # 7ffc <_end+0x7fd0>
     X"c00015f3", --   csrrw    a1,cycle,zero
     X"c8001673", --   csrrw    a2,cycleh,zero
     X"f13016f3", --   csrrw    a3,mimpid,zero
     X"30101773", --   csrrw    a4,misa,zero
     X"c02017f3", --   csrrw    a5,instret,zer
     X"c8201873", --   csrrw    a6,instreth,ze
     X"c00018f3", --   csrrw    a7,cycle,zero
     X"c8001973", --   csrrw    s2,cycleh,zero
     X"400019f3", --   csrrw    s3,0x400,zero
     X"40069a73", --   csrrw    s4,0x400,a3
     X"40001af3", --   csrrw    s5,0x400,zero
     X"40011b73", --   csrrw    s6,0x400,sp
     X"40001bf3", --   csrrw    s7,0x400,zero
     X"40073c73", --   csrrc    s8,0x400,a4
     X"40001cf3", --   csrrw    s9,0x400,zero
     X"40111d73", --   csrrw    s10,0x401,sp
     X"40101df3", --   csrrw    s11,0x401,zero
     X"40172e73", --   csrrs    t3,0x401,a4
     X"40101ef3", --   csrrw    t4,0x401,zero

          X"0000006f", --             infloop
       others => X"00000000");
BEGIN
   
   
 	-- The O_we signal can sustain too long. Clamp it to only when O_cmd is active.
    MEM_WE <= MEM_O_cmd and MEM_O_we;
    
    -- "Local" BRAM banks are 64KB. To address inside we need lower 16b
    MEM_64KB_ADDR <= X"0000" & MEM_O_addr(15 downto 0);
    MEM_BANK_ID <= MEM_O_addr(31 downto 16);

    MEM_CS_BRAM_1 <= '1' when (MEM_BANK_ID = X"0000") else '0'; -- 0x0000ffff bank 64KB
    MEM_CS_BRAM_2 <= '1' when (MEM_BANK_ID = X"0001") else '0'; -- 0x0001ffff bank 64KB
    MEM_CS_BRAM_3 <= '1' when (MEM_BANK_ID = X"0002") else '0'; -- 0x0002ffff bank 64KB
    
    MEM_CS_DDR3 <= '1' when (MEM_BANK_ID(15 downto 12) = X"1") else '0'; -- 0x1******* ddr3 bank 256MB
    
    -- if any CS line is active, this is 1
    MEM_ANY_CS <= MEM_CS_BRAM_1 or MEM_CS_BRAM_2 or MEM_CS_BRAM_3;
    
    -- select the correct data to send to cpu
    MEM_I_data_raw <= INT_DATA when O_int_ack = '1'     
                  else MEM_DATA_OUT_BRAM_1 when MEM_CS_BRAM_1 = '1' 
                  else MEM_DATA_OUT_BRAM_2 when MEM_CS_BRAM_2 = '1' 
                  else MEM_DATA_OUT_BRAM_3 when MEM_CS_BRAM_3 = '1' 
                  else IO_DATA;
 
 MEM_I_data  <= ROM(to_integer(unsigned( MEM_64KB_ADDR(15 downto 2) )));

        
               
    cEng_core_clk: process
    begin
            cEng_core <= '0';
            wait for I_clk_period/2;
            cEng_core <= '1';
            wait for I_clk_period/2;
    end process;

   core0: core PORT MAP (
          I_clk => cEng_core,
          I_reset => I_reset,
          I_halt => I_halt,
          I_int => I_int,
          O_int_ack => O_int_ack,
          I_int_data => I_int_data,
          MEM_I_ready => MEM_I_ready,
          MEM_O_cmd => MEM_O_cmd,
          MEM_O_we => MEM_O_we,
          MEM_O_byteEnable => MEM_O_byteEnable,
          MEM_O_addr => MEM_O_addr,
          MEM_O_data => MEM_O_data,
          MEM_I_data => MEM_I_data,
          MEM_I_dataReady => MEM_I_dataReady
		  ,
		  O_DBG=>O_DBG
        );
        
        


    -- Huge process which handles memory request arbitration at the Soc/Core clock 
    MEM_proc: process(cEng_core)
    begin
        if rising_edge(cEng_core) then
            if MEM_readyState = SOC_CtlState_Ready then
                if MEM_O_cmd = '1' then
                
                 
                    
                    MEM_I_ready <= '0';
                    MEM_I_dataReady  <= '0';
                    if MEM_O_we = '1' then
                        -- DDR3 request, or immediate command?
                         
                        MEM_readyState <= SOC_CtlState_IMM_WriteCmdComplete;
                         
                    else
                        -- DDR3 request, or immediate command?
                        
                        MEM_readyState <= SOC_CtlState_IMM_ReadCmdComplete; 
                    end if;
                    
                end if;
            elsif MEM_readyState >= 1 then
                 
                
                -- Immediate commands do not cross clock domains and complete immediately
                if MEM_readyState = SOC_CtlState_IMM_ReadCmdComplete then
                    MEM_I_ready <= '1';
                    MEM_I_dataReady <= '1'; 
                    MEM_readyState <= SOC_CtlState_Ready;  
                    
                elsif MEM_readyState = SOC_CtlState_IMM_WriteCmdComplete then
                    MEM_I_ready <= '1';
                    MEM_I_dataReady  <= '0'; 
                    MEM_readyState <= SOC_CtlState_Ready;
          
            end if;
        end if;
    end if;
  end process;
   
    
     -- Stimulus process
     stim_proc: process
     begin        
        -- hold reset state for 100 ns.
        wait for 100 ns;    
  
        I_reset <= '0';
        
     end process;


end Behavioral;
