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
            O_DBG:out std_logic_vector(63 downto 0)
        );
    END COMPONENT;
    
    
      signal  CLK12MHZ :   STD_LOGIC := '0';
          signal  CLKTIME :   STD_LOGIC := '0';
        constant I_CLKTIME_period : time := 8 ns;
        
        signal cEng_core : std_logic := '0';
    signal I_reset : std_logic := '1';
    signal I_halt : std_logic := '0';
    signal I_int : std_logic := '0';
    signal MEM_I_ready : std_logic := '1';
    signal MEM_I_data : std_logic_vector(31 downto 0) := (others => '0');
    signal MEM_I_dataReady : std_logic := '0';

    signal MEM_O_data_swizzed : std_logic_vector(31 downto 0) := (others => '0');
 
    signal O_int_ack : std_logic:= '0';
    signal O_int_ack_stable_12mhz : std_logic:= '0';
    signal O_int_ack_stable_12mhz_core : std_logic:= '0';
    
    signal MEM_O_cmd : std_logic := '0';
    signal MEM_O_we : std_logic := '0';
    signal MEM_O_byteEnable : std_logic_vector(1 downto 0) := (others => '0');
    signal MEM_O_addr : std_logic_vector(31 downto 0) := (others => '0');
    signal MEM_O_data : std_logic_vector(31 downto 0) := (others => '0');
    
    signal I_int_data:  STD_LOGIC_VECTOR(31 downto 0);
            signal MEM_I_data_raw : std_logic_vector(31 downto 0) := (others => '0');
    
    -- Clock period definitions
    constant I_clk_period : time := 5 ns;
    
    
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
   
    
        signal    O_DBG: std_logic_vector(63 downto 0);
        
            constant mmio_addr_mtime_lo: STD_LOGIC_VECTOR( 31 downto 0) := X"4400bff8";
        constant mmio_addr_mtime_hi: STD_LOGIC_VECTOR( 31 downto 0) := X"4400bffc";
        signal gcsr_mtime_lo: STD_LOGIC_VECTOR( 31 downto 0) := (others => '0');
        signal gcsr_mtime_hi: STD_LOGIC_VECTOR( 31 downto 0) := (others => '0');
        
            signal memcontroller_reset_count: integer := 100000;
        
        signal count12MHz: std_logic_vector(63 downto 0) := X"0000000000000000";    
        
       constant mmio_addr_mtimecmp0_lo: STD_LOGIC_VECTOR( 31 downto 0) := X"44004000";
       constant mmio_addr_mtimecmp0_hi: STD_LOGIC_VECTOR( 31 downto 0) := X"44004004";
          --       constant mmio_addr_mtimecmp0_lo: STD_LOGIC_VECTOR( 31 downto 0) := X"00000004";
            --     constant mmio_addr_mtimecmp0_hi: STD_LOGIC_VECTOR( 31 downto 0) := X"00000008";
        signal gcsr_timer_initialized : STD_LOGIC:='0';
        signal gcsr_mtimecmp0_lo: STD_LOGIC_VECTOR( 31 downto 0) := X"0000000c";--X"07270E00";--20s 0E4E1C00"; --?10 seconds of 12mhz counter?"; --(others => '0');
        signal gcsr_mtimecmp0_hi: STD_LOGIC_VECTOR( 31 downto 0) := (others => '0');
        signal gcsr_mtimecmp0_stable: STD_LOGIC_VECTOR( 63 downto 0) := (others => '0');
        
        signal gcsr_mtimecmp0_lo_written: STD_LOGIC := '0';
        signal gcsr_mtimecmp0_hi_written: STD_LOGIC := '0';
        signal gcsr_mtimecmp_irq_reset: STD_LOGIC := '0';
        signal gcsr_mtimecmp_irq_reset_stable: STD_LOGIC := '0';
        signal gcsr_mtimecmp_irq_en: STD_LOGIC := '0';  ----
        signal gcsr_mtimecmp_irq_en_stable: STD_LOGIC := '0'; ------
        signal gcsr_mtimecmp_irq: STD_LOGIC := '0';
        
        signal gcsr_mtimecmp_irq_served: std_logic := '0';
        signal plic_int : std_logic := '0';
        
         type rom_type is array (0 to 16384)
               of std_logic_vector(31 downto 0);
       signal ROM2: rom_type :=(others => X"00000000");    
                      signal ROM3: rom_type :=(others => X"00000000");        
     signal ROM: rom_type:=(  
   X"00000097",     --auipc	ra,0x0
     X"14408093",     --addi    ra,ra,324 # 10000230 <_trap_handler>
     X"30509ff3",     --csrrw    t6,mtvec,ra
     X"00002197",     --auipc    gp,0x2
     X"f0818193",     --addi    gp,gp,-248 # 10002000 <test_A1_data>
     X"00002117",     --auipc    sp,0x2
     X"f1010113",     --addi    sp,sp,-240 # 10002010 <begin_signature>
     X"00002097",     --auipc    ra,0x2
     X"f1808093",     --addi    ra,ra,-232 # 10002020 <test_A1_res_exc>
     X"00500293",     --li    t0,5
     X"00600313",     --li    t1,6
     X"0001a203",     --lw    tp,0(gp)
     X"00412023",     --sw    tp,0(sp)
     X"0011a203",     --lw    tp,1(gp)
     X"00412223",     --sw    tp,4(sp)
     X"0021a203",     --lw    tp,2(gp)
     X"00412423",     --sw    tp,8(sp)
     X"0031a203",     --lw    tp,3(gp)
     X"00412623",     --sw    tp,12(sp)
     X"00002197",     --auipc    gp,0x2
     X"ecc18193",     --addi    gp,gp,-308 # 10002004 <test_A2_data>
     X"00002117",     --auipc    sp,0x2
     X"ef810113",     --addi    sp,sp,-264 # 10002038 <test_A2_res>
     X"00002097",     --auipc    ra,0x2
     X"f1008093",     --addi    ra,ra,-240 # 10002058 <test_A2_res_exc>
     X"00500293",     --li    t0,5
     X"00600313",     --li    t1,6
     X"00019203",     --lh    tp,0(gp)
     X"00412023",     --sw    tp,0(sp)
     X"00119203",     --lh    tp,1(gp)
     X"00412223",     --sw    tp,4(sp)
     X"00219203",     --lh    tp,2(gp)
     X"00412423",     --sw    tp,8(sp)
     X"00319203",     --lh    tp,3(gp)
     X"00412623",     --sw    tp,12(sp)
     X"0001d203",     --lhu    tp,0(gp)
     X"00412823",     --sw    tp,16(sp)
     X"0011d203",     --lhu    tp,1(gp)
     X"00412a23",     --sw    tp,20(sp)
     X"0021d203",     --lhu    tp,2(gp)
     X"00412c23",     --sw    tp,24(sp)
     X"0031d203",     --lhu    tp,3(gp)
     X"00412e23",     --sw    tp,28(sp)
     X"00002117",     --auipc    sp,0x2
     X"ee010113",     --addi    sp,sp,-288 # 10002078 <test_B1_res>
     X"00002097",     --auipc    ra,0x2
     X"ee808093",     --addi    ra,ra,-280 # 10002088 <test_B1_res_exc>
     X"00000313",     --li    t1,0
     X"9999a2b7",     --lui    t0,0x9999a
     X"99928293",     --addi    t0,t0,-1639 # 99999999 <_end+0x89997795>
     X"00512023",     --sw    t0,0(sp)
     X"00512223",     --sw    t0,4(sp)
     X"00512423",     --sw    t0,8(sp)
     X"00512623",     --sw    t0,12(sp)
     X"00612023",     --sw    t1,0(sp)
     X"00410113",     --addi    sp,sp,4
     X"006120a3",     --sw    t1,1(sp)
     X"00410113",     --addi    sp,sp,4
     X"00612123",     --sw    t1,2(sp)
     X"00410113",     --addi    sp,sp,4
     X"006121a3",     --sw    t1,3(sp)
     X"00002117",     --auipc    sp,0x2
     X"ec010113",     --addi    sp,sp,-320 # 100020a0 <test_B2_res>
     X"00002097",     --auipc    ra,0x2
     X"ec808093",     --addi    ra,ra,-312 # 100020b0 <test_B2_res_exc>
     X"00000313",     --li    t1,0
     X"9999a2b7",     --lui    t0,0x9999a
     X"99928293",     --addi    t0,t0,-1639 # 99999999 <_end+0x89997795>
     X"00512023",     --sw    t0,0(sp)
     X"00512223",     --sw    t0,4(sp)
     X"00512423",     --sw    t0,8(sp)
     X"00512623",     --sw    t0,12(sp)
     X"00611023",     --sh    t1,0(sp)
     X"00410113",     --addi    sp,sp,4
     X"006110a3",     --sh    t1,1(sp)
     X"00410113",     --addi    sp,sp,4
     X"00611123",     --sh    t1,2(sp)
     X"00410113",     --addi    sp,sp,4
     X"006111a3",     --sh    t1,3(sp)
     X"305f9073",     --csrw    mtvec,t6
     X"02c0006f",     --j    10000258 <test_end>
     
     
     X"34102f73",     --csrr    t5,mepc
     X"004f0f13",     --addi    t5,t5,4
     X"341f1073",     --csrw    mepc,t5
     X"34302f73",     --csrr    t5,mtval
     X"003f7f13",     --andi    t5,t5,3
     X"01e0a023",     --sw    t5,0(ra)
     X"34202f73",     --csrr    t5,mcause
     X"01e0a223",     --sw    t5,4(ra)
     X"00808093",     --addi    ra,ra,8
     X"30200073",     --mret
     
     
     X"00100193",     --li    gp,1
     X"00002f17",     --auipc    t5,0x2
     X"e64f0f13",     --addi    t5,t5,-412 # 100020c0 <end_signature>
     X"000f2103",     --lw    sp,0(t5)
     X"00412083",     --lw    ra,4(sp)
     X"00812283",     --lw    t0,8(sp)
     X"00c12303",     --lw    t1,12(sp)
     X"01012383",     --lw    t2,16(sp)
     X"01412403",     --lw    s0,20(sp)
     X"01812483",     --lw    s1,24(sp)
     X"01c12503",     --lw    a0,28(sp)
     X"02012583",     --lw    a1,32(sp)
     X"02412603",     --lw    a2,36(sp)
     X"02812683",     --lw    a3,40(sp)
     X"02c12703",     --lw    a4,44(sp)
     X"03012783",     --lw    a5,48(sp)
     X"03412803",     --lw    a6,52(sp)
     X"03812883",     --lw    a7,56(sp)
     X"03c12903",     --lw    s2,60(sp)
     X"04012983",     --lw    s3,64(sp)
     X"04412a03",     --lw    s4,68(sp)
     X"04812a83",     --lw    s5,72(sp)
     X"04c12b03",     --lw    s6,76(sp)
     X"05012b83",     --lw    s7,80(sp)
     X"05412c03",     --lw    s8,84(sp)
     X"05812c83",     --lw    s9,88(sp)
     X"05c12d03",     --lw    s10,92(sp)
     X"06012d83",     --lw    s11,96(sp)
     X"06412e03",     --lw    t3,100(sp)
     X"06812e83",     --lw    t4,104(sp)
     X"06c12f03",     --lw    t5,108(sp)
     X"07012f83",     --lw    t6,112(sp)
     X"08010113",     --addi    sp,sp,128
             X"0000006f", --              j    00 <if>
--  X"00008067",     --ret
  
  
     X"00002f17",     --auipc    t5,0x2
     X"de0f0f13",     --addi    t5,t5,-544 # 100020c0 <end_signature>
     X"000f2103",     --lw    sp,0(t5)
     X"00412083",     --lw    ra,4(sp)
     X"00812283",     --lw    t0,8(sp)
     X"00c12303",     --lw    t1,12(sp)
     X"01012383",     --lw    t2,16(sp)
     X"01412403",     --lw    s0,20(sp)
     X"01812483",     --lw    s1,24(sp)
     X"01c12503",     --lw    a0,28(sp)
     X"02012583",     --lw    a1,32(sp)
     X"02412603",     --lw    a2,36(sp)
     X"02812683",     --lw    a3,40(sp)
     X"02c12703",     --lw    a4,44(sp)
     X"03012783",     --lw    a5,48(sp)
     X"03412803",     --lw    a6,52(sp)
     X"03812883",     --lw    a7,56(sp)
     X"03c12903",     --lw    s2,60(sp)
     X"04012983",     --lw    s3,64(sp)
     X"04412a03",     --lw    s4,68(sp)
     X"04812a83",     --lw    s5,72(sp)
     X"04c12b03",     --lw    s6,76(sp)
     X"05012b83",     --lw    s7,80(sp)
     X"05412c03",     --lw    s8,84(sp)
     X"05812c83",     --lw    s9,88(sp)
     X"05c12d03",     --lw    s10,92(sp)
     X"06012d83",     --lw    s11,96(sp)
     X"06412e03",     --lw    t3,100(sp)
     X"06812e83",     --lw    t4,104(sp)
     X"06c12f03",     --lw    t5,108(sp)
     X"07012f83",     --lw    t6,112(sp)
     X"08010113",     --addi    sp,sp,128
            X"0000006f", --              j    00 <if>

  --   X"00008067",     --ret
  --   X"c0001073",     --unimp
--     
--     X"00000097",      --auipc    ra,0x0
--     X"20808093",      --addi    ra,ra,520 # 100002f4 <_trap_handler>
--     X"30509ff3",      --csrrw    t6,mtvec,ra
--     X"30127073",      --csrci    misa,4
--     X"00002097",      --auipc    ra,0x2
--     X"f0408093",      --addi    ra,ra,-252 # 10002000 <begin_signature>
--     X"11111137",      --lui    sp,0x11111
--     X"11110113",      --addi    sp,sp,273 # 11111111 <_end+0x110ef0d>
--     X"00a0006f",      --j    10000116 <begin_testcode+0x2a>
--     X"00000113",      --li    sp,0
--     X"00002097",      --auipc    ra,0x2
--     X"ef808093",      --addi    ra,ra,-264 # 1000200c <test_A2_res>
--     X"22222137",      --lui    sp,0x22222
--     X"22210113",      --addi    sp,sp,546 # 22222222 <_end+0x1222001e>
--     X"00000217",      --auipc    tp,0x0
--     X"01120213",      --addi    tp,tp,17 # 10000135 <begin_testcode+0x49>
--     X"00020067",      --jr    tp # 0 <_start-0x10000000>
--     X"00000113",      --li    sp,0
--     X"0020a023",      --sw    sp,0(ra)
--     X"00408093",      --addi    ra,ra,4
--     X"33333137",      --lui    sp,0x33333
--     X"33310113",      --addi    sp,sp,819 # 33333333 <_end+0x2333112f>
--     X"00000217",      --auipc    tp,0x0
--     X"01020213",      --addi    tp,tp,16 # 10000154 <begin_testcode+0x68>
--     X"00120067",      --jr    1(tp) # 0 <_start-0x10000000>
--     X"00000113",      --li    sp,0
--     X"0020a023",      --sw    sp,0(ra)
--     X"00408093",      --addi    ra,ra,4
--     X"44444137",      --lui    sp,0x44444
--     X"44410113",      --addi    sp,sp,1092 # 44444444 <_end+0x34442240>
--     X"00000217",      --auipc    tp,0x0
--     X"01420213",      --addi    tp,tp,20 # 10000178 <begin_testcode+0x8c>
--     X"ffd20067",      --jr    -3(tp) # 0 <_start-0x10000000>
--     X"00000113",      --li    sp,0
--     X"0020a023",      --sw    sp,0(ra)
--     X"00408093",      --addi    ra,ra,4
--     X"00002097",      --auipc    ra,0x2
--     X"e9c08093",      --addi    ra,ra,-356 # 10002018 <test_A3_res_exc>
--     X"55555137",      --lui    sp,0x55555
--     X"55510113",      --addi    sp,sp,1365 # 55555555 <_end+0x45553351>
--     X"00000217",      --auipc    tp,0x0
--     X"01220213",      --addi    tp,tp,18 # 1000019e <begin_testcode+0xb2>
--     X"00020067",      --jr    tp # 0 <_start-0x10000000>
--     X"00000113",      --li    sp,0
--     X"66666137",      --lui    sp,0x66666
--     X"66610113",      --addi    sp,sp,1638 # 66666666 <_end+0x56664462>
--     X"00000217",      --auipc    tp,0x0
--     X"01320213",      --addi    tp,tp,19 # 100001b7 <begin_testcode+0xcb>
--     X"00020067",      --jr    tp # 0 <_start-0x10000000>
--     X"00000113",      --li    sp,0
--     X"77777137",      --lui    sp,0x77777
--     X"77710113",      --addi    sp,sp,1911 # 77777777 <_end+0x67775573>
--     X"00000217",      --auipc    tp,0x0
--     X"01020213",      --addi    tp,tp,16 # 100001cc <begin_testcode+0xe0>
--     X"00220067",      --jr    2(tp) # 0 <_start-0x10000000>
--     X"00000113",      --li    sp,0
--     X"88889137",      --lui    sp,0x88889
--     X"88810113",      --addi    sp,sp,-1912 # 88888888 <_end+0x78886684>
--     X"00000217",      --auipc    tp,0x0
--     X"01020213",      --addi    tp,tp,16 # 100001e4 <begin_testcode+0xf8>
--     X"00320067",      --jr    3(tp) # 0 <_start-0x10000000>
--     X"00000113",      --li    sp,0
--     X"00002097",      --auipc    ra,0x2
--     X"e6408093",      --addi    ra,ra,-412 # 10002048 <test_B1_res_exc>
--     X"00500293",      --li    t0,5
--     X"00600313",      --li    t1,6
--     X"00628763",      --beq    t0,t1,10000202 <begin_testcode+0x116>
--     X"9999a137",      --lui    sp,0x9999a
--     X"99910113",      --addi    sp,sp,-1639 # 99999999 <_end+0x89997795>
--     X"00000013",      --nop
--     X"00000013",      --nop
--     X"00528563",      --beq    t0,t0,10000212 <begin_testcode+0x126>
--     X"00000113",      --li    sp,0
--     X"00002097",      --auipc    ra,0x2
--     X"e4408093",      --addi    ra,ra,-444 # 10002054 <test_B2_res_exc>
--     X"00500293",      --li    t0,5
--     X"00600313",      --li    t1,6
--     X"00529763",      --bne    t0,t0,1000022e <begin_testcode+0x142>
--     X"aaaab137",      --lui    sp,0xaaaab
--     X"aaa10113",      --addi    sp,sp,-1366 # aaaaaaaa <_end+0x9aaa88a6>
--     X"00000013",      --nop
--     X"00000013",      --nop
--     X"00629563",      --bne    t0,t1,1000023e <begin_testcode+0x152>
--     X"00000113",      --li    sp,0
--     X"00002097",      --auipc    ra,0x2
--     X"e2408093",      --addi    ra,ra,-476 # 10002060 <test_B3_res_exc>
--     X"00500293",      --li    t0,5
--     X"00600313",      --li    t1,6
--     X"00534763",      --blt    t1,t0,1000025a <begin_testcode+0x16e>
--     X"bbbbc137",      --lui    sp,0xbbbbc
--     X"bbb10113",      --addi    sp,sp,-1093 # bbbbbbbb <_end+0xabbb99b7>
--     X"00000013",      --nop
--     X"00000013",      --nop
--     X"0062c563",      --blt    t0,t1,1000026a <begin_testcode+0x17e>
--     X"00000113",      --li    sp,0
--     X"00002097",      --auipc    ra,0x2
--     X"e0408093",      --addi    ra,ra,-508 # 1000206c <test_B4_res_exc>
--     X"00500293",      --li    t0,5
--     X"00600313",      --li    t1,6
--     X"00536763",      --bltu    t1,t0,10000286 <begin_testcode+0x19a>
--     X"ccccd137",      --lui    sp,0xccccd
--     X"ccc10113",      --addi    sp,sp,-820 # cccccccc <_end+0xbcccaac8>
--     X"00000013",      --nop
--     X"00000013",      --nop
--     X"0062e563",      --bltu    t0,t1,10000296 <begin_testcode+0x1aa>
--     X"00000113",      --li    sp,0
--     X"00002097",      --auipc    ra,0x2
--     X"de408093",      --addi    ra,ra,-540 # 10002078 <test_B5_res_exc>
--     X"00500293",      --li    t0,5
--     X"00600313",      --li    t1,6
--     X"0062d763",      --bge    t0,t1,100002b2 <begin_testcode+0x1c6>
--     X"dddde137",      --lui    sp,0xdddde
--     X"ddd10113",      --addi    sp,sp,-547 # dddddddd <_end+0xcdddbbd9>
--     X"00000013",      --nop
--     X"00000013",      --nop
--     X"00535563",      --bge    t1,t0,100002c2 <begin_testcode+0x1d6>
--     X"00000113",      --li    sp,0
--     X"00002097",      --auipc    ra,0x2
--     X"dc408093",      --addi    ra,ra,-572 # 10002084 <test_B6_res_exc>
--     X"00500293",      --li    t0,5
--     X"00600313",      --li    t1,6
--     X"0062f763",      --bgeu    t0,t1,100002de <begin_testcode+0x1f2>
--     X"eeeef137",      --lui    sp,0xeeeef
--     X"eee10113",      --addi    sp,sp,-274 # eeeeeeee <_end+0xdeeeccea>
--     X"00000013",      --nop
--     X"00000013",      --nop
--     X"00537563",      --bgeu    t1,t0,100002ee <begin_testcode+0x202>
--     X"00000113",      --li    sp,0
--     X"305f9073",      --csrw    mtvec,t6
--     X"0300006f",      --j    10000320 <test_end>
--     
--      --<_trap_handler>:
--     X"34302f73",      --csrr    t5,mtval
--     X"ffef0f13",      --addi    t5,t5,-2
--     X"341f1073",      --csrw    mepc,t5
--     X"34302f73",      --csrr    t5,mtval
--     X"003f7f13",      --andi    t5,t5,3
--     X"01e0a023",      --sw    t5,0(ra)
--     X"34202f73",      --csrr    t5,mcause
--     X"01e0a223",      --sw    t5,4(ra)
--     X"0020a423",      --sw    sp,8(ra)
--     X"00c08093",      --addi    ra,ra,12
--     X"30200073",      --mret
--     
--     -- <test_end>:
--     X"00100193",      --li    gp,1
--     X"00100f13", --              	li	t5,1
--     X"00100e93", --                  li    t4,1
--     X"03df0eb3", --                  mul    t4,t5,t4
--     
     
     X"0000006f", --              j    00 <if>
         
      X"06300513", --      0      	li	a0,99  0
      X"00a00693", --      4          li    a3,10
      X"02d57733", --      8          remu    a4,a0,a3
      X"00f605b3", --      c          add    a1,a2,a5
      X"00178793", --     10           addi    a5,a5,1
      X"02d55533", --     14           divu    a0,a0,a3
      X"03070713", --     18           addi    a4,a4,48

     
     
     --X"00812423", --   	sw	s0,8(sp)
    -- X"00112623", --       sw    ra,12(sp)
     --X"00048413", --       mv    s0,s1
     --X"00048793", --       mv    a5,s1
     --X"40960633", --       sub    a2,a2,s1
     X"00a00693", --       li    a3,10
     X"02d57733", --       remu    a4,a0,a3
     X"00f605b3", --       add    a1,a2,a5
     X"00178793", --       addi    a5,a5,1
     X"02d55533", --       divu    a0,a0,a3
     X"03070713", --       addi    a4,a4,48
     X"fee78fa3", --       sb    a4,-1(a5)
     X"fe0514e3", --       bnez    a0,20bbc <put_decimal+0x30>
 -- 00000000 <if>:
     X"0000006f", --              j    00 <if>

       others => X"00000000");
       
       signal I_hart0_int0_coreclk_stable : STD_LOGIC := '0';
       signal O_hart0_int_ack0_coreclk_stable : STD_LOGIC := '0';
       signal hart0_int_ack0_external : STD_LOGIC := '0';
       signal int_was_inactive: STD_LOGIC := '0';
       
       signal count12MHz_stable: STD_LOGIC_VECTOR(63 downto 0) := (others => '0');
BEGIN

   I_int <= gcsr_mtimecmp_irq;
   
process(CLK12MHZ)
begin
 if rising_edge(CLK12MHZ) then
     count12MHz <= std_logic_vector(unsigned(count12MHz) + 1);
 end if;
end process;

process (cEng_core)
begin
if rising_edge(cEng_core) then
    count12MHz_stable <= count12MHz;
end if;
end process;


process(cEng_core)
begin
 if rising_edge(cEng_core) then
     if gcsr_mtimecmp_irq_en = '1' then
         if count12MHz_stable >= (gcsr_mtimecmp0_hi & gcsr_mtimecmp0_lo) then
             gcsr_mtimecmp_irq <= '1';
             gcsr_mtimecmp_irq_en <= '0';
         end if;
     else
         if gcsr_mtimecmp_irq_reset = '1' then
            gcsr_mtimecmp_irq_en <= '1';
         end if;
         if gcsr_mtimecmp_irq = '1' and O_int_ack = '1' then
            gcsr_mtimecmp_irq <= '0';
         end if;
     end if;
 end if;
end process;

   I_int_data <= EXCEPTION_INT_MACHINE_TIMER;

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
    MEM_I_data_raw <= 
                  MEM_DATA_OUT_BRAM_1 when MEM_CS_BRAM_1 = '1' 
                  else MEM_DATA_OUT_BRAM_2 when MEM_CS_BRAM_2 = '1' 
                  else MEM_DATA_OUT_BRAM_3 when MEM_CS_BRAM_3 = '1' 
                  else X"91a1b1c1";--IO_DATA;
                  
 MEM_DATA_OUT_BRAM_1 <= ROM(to_integer(unsigned( MEM_64KB_ADDR(15 downto 2)and "01" & X"fff" )));--and "00"&X"03F" )));
 MEM_DATA_OUT_BRAM_2 <= ROM2(to_integer(unsigned( MEM_64KB_ADDR(15 downto 2)and "01" & X"fff" )));--and "00"&X"03F" )));
 MEM_DATA_OUT_BRAM_3 <= ROM3(to_integer(unsigned( MEM_64KB_ADDR(15 downto 2)and "01" & X"fff" )));--and "00"&X"03F" )));

   MEM_I_data  <= MEM_I_data_raw; 

        
               
    cEng_core_clk: process
    begin
            cEng_core <= '0';
            wait for I_clk_period/2;
            cEng_core <= '1';
            wait for I_clk_period/2;
    end process;
                   
CLKTIME_clk: process
begin
 CLKTIME <= '0';
 wait for I_CLKTIME_period/2;
 CLKTIME <= '1';
 wait for I_CLKTIME_period/2;
end process;
    
    CLK12MHZ <= CLKTIME;

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
            if gcsr_mtimecmp_irq_en = '1' and gcsr_mtimecmp_irq_reset = '1' then
               gcsr_mtimecmp_irq_reset <= '0';
            end if;
                        
            if MEM_readyState = SOC_CtlState_Ready then
                if MEM_O_cmd = '1' then
                
                    -- system memory maps
                    if MEM_O_addr = X"f0009000" and MEM_O_we = '1' then
                        -- onboard leds
                        IO_LEDS <= "0000" & MEM_O_data( 3 downto 0);
                    end if;
                    if MEM_O_addr = X"f0009000" and MEM_O_we = '0' then
                        -- onboard leds
                        IO_DATA <= X"000000" &  IO_LEDS;
                    end if;

                   if MEM_O_addr = mmio_addr_mtime_lo and MEM_O_we = '0' then
                      IO_DATA <= count12MHz_stable(31 downto 0);
                    end if; 
                                    
                   if MEM_O_addr = mmio_addr_mtime_hi and MEM_O_we = '0' then
                     IO_DATA <= count12MHz_stable(63 downto 32);
                   end if;
                     
                    
                   if MEM_O_addr = mmio_addr_mtimecmp0_lo and MEM_O_we = '1' then---1
                     gcsr_mtimecmp0_lo <= MEM_O_data;
                     gcsr_mtimecmp0_lo_written <= '1';
                   end if; 
                   
                   if MEM_O_addr = mmio_addr_mtimecmp0_hi and MEM_O_we = '1' then---1
                      gcsr_mtimecmp0_hi <= MEM_O_data;
                      if gcsr_mtimecmp0_lo_written = '1' then
                        --gcsr_mtimecmp0_hi_written <= '1';
                        gcsr_mtimecmp_irq_reset <= '1';
                        gcsr_mtimecmp0_lo_written <= '0';
                        --gcsr_mtimecmp0_hi_written <= '0';
                      end if;
                   end if;
                   
    
                     if MEM_O_addr = mmio_addr_mtimecmp0_lo and MEM_O_we = '0' then
                       IO_DATA <= (gcsr_mtimecmp0_lo);
                     end if; 
                     
                     if MEM_O_addr = mmio_addr_mtimecmp0_hi and MEM_O_we = '0' then
                        IO_DATA <= (gcsr_mtimecmp0_hi);
                     end if;
               
                    
                    MEM_I_ready <= '0';
                    MEM_I_dataReady  <= '0';
                    if MEM_O_we = '1' then
                        -- DDR3 request, or immediate command?
                         
                        MEM_readyState <= SOC_CtlState_IMM_WriteCmdComplete;
                        if (MEM_CS_BRAM_1 = '1') then
                            ROM(to_integer(unsigned( MEM_64KB_ADDR(15 downto 2)))) <= MEM_O_data;
                        end if;
                        if (MEM_CS_BRAM_2 = '1') then
                            ROM2(to_integer(unsigned( MEM_64KB_ADDR(15 downto 2)))) <= MEM_O_data;
                        end if;
                        if (MEM_CS_BRAM_3 = '1') then
                            ROM3(to_integer(unsigned( MEM_64KB_ADDR(15 downto 2)))) <= MEM_O_data;
                        end if;
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
        wait for 20 ns;    
        memcontroller_reset_count <= 0;
  
        I_reset <= '0';

        wait;
--    
     end process;


end Behavioral;
