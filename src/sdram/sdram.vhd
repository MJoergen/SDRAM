-- This is the wrapper file for the complete SDRAM controller.
--
-- This module requires one clock:
-- clk_i          : 166 MHz : This is the main clock used for the Avalon MM
--                            interface as well as controlling the SDRAM
--                            device.
--
-- Created by Michael Jørgensen in 2024 (mjoergen.github.io/SDRAM).
--
-- Notes from datasheet for "IS42S16320F-6BL".
-- Link: https://www.issi.com/WW/pdf/42-45R-S_86400F-16320F.pdf
-- Programmable CAS# latency: 2 or 3 clock cycles. When running 167 MHz,
-- we must set CAS# latency to 3 clock cycles, i.e. 18 ns.
--
-- Addressing scheme:
-- Bank address   : BA0 and BA1 (i.e. 4 banks)
-- Row Address    : A0 - A12 (i.e. 8k)
-- Column Address : A0 - A9 (i.e. 1k)
-- Total : 25 address bits
--
-- During read:
-- DQ’s read data is subject to the logic level on the DQM inputs two clocks earlier. When
-- a given DQM signal was registered HIGH, the corresponding DQ’s will be High-Z two
-- clocks later. DQ’s will provide valid data when the DQM signal was registered LOW.


library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

library unisim;
   use unisim.vcomponents.all; -- needed for ODDR

entity sdram is
   port (
      clk_i               : in    std_logic;                     -- Main clock
      rst_i               : in    std_logic;                     -- Synchronous reset

      -- Avalon Memory Map
      avm_write_i         : in    std_logic;
      avm_read_i          : in    std_logic;
      avm_address_i       : in    std_logic_vector(31 downto 0);
      avm_writedata_i     : in    std_logic_vector(15 downto 0);
      avm_byteenable_i    : in    std_logic_vector( 1 downto 0);
      avm_burstcount_i    : in    std_logic_vector( 7 downto 0);
      avm_readdata_o      : out   std_logic_vector(15 downto 0);
      avm_readdatavalid_o : out   std_logic;
      avm_waitrequest_o   : out   std_logic;

      -- SDRAM device interface
      sdram_a_o           : out   std_logic_vector(12 downto 0);
      sdram_ba_o          : out   std_logic_vector(1 downto 0);
      sdram_cas_n_o       : out   std_logic;
      sdram_cke_o         : out   std_logic;                     -- Asynchronuous
      sdram_clk_o         : out   std_logic;
      sdram_cs_n_o        : out   std_logic;
      sdram_dq_in_i       : in    std_logic_vector(15 downto 0);
      sdram_dqmh_o        : out   std_logic;
      sdram_dqml_o        : out   std_logic;
      sdram_dq_oe_n_o     : out   std_logic_vector(15 downto 0); -- Output enable (inverted) for DQ
      sdram_dq_out_o      : out   std_logic_vector(15 downto 0);
      sdram_ras_n_o       : out   std_logic;
      sdram_we_n_o        : out   std_logic
   );
end entity sdram;

architecture synthesis of sdram is

   -- The below constants are taken from the datasheet.

   -- 101 us @ 167 MHz
   constant C_TIME_INIT_POWER_ON : natural                  := 101 * 167;

   -- CAS# latency
   constant C_TIME_CAC : natural                            := 3;

   -- Active Command to Read/Write Command Delay Time
   constant C_TIME_RCD : natural                            := 3;

   -- RAS# latency (t_RCD + t_CAC)
   constant C_TIME_RAC : natural                            := 6;

   -- Command Period (REF to REF / ACT to ACT)
   constant C_TIME_RC : natural                             := 10;

   -- Command Period (ACT to PRE)
   constant C_TIME_RAS : natural                            := 7;

   -- Command Period (PRE to ACT)
   constant C_TIME_RP : natural                             := 3;

   -- Command Period (ACT[0] to ACT[1])
   constant C_TIME_RRD : natural                            := 2;

   -- Column Command Delay Time (READ, WRITE)
   constant C_TIME_CCD : natural                            := 1;

   -- Input Data to Precharge Command Delay Time
   constant C_TIME_DPL : natural                            := 2;

   -- Input Data to Active/Refresh Command Delay Time
   constant C_TIME_DAL : natural                            := 5;

   -- Burst Stop Command to Output in High-Z Delay Time (Read)
   constant C_TIME_RBD : natural                            := 3;

   -- Burst Stop Command to Input in Invalid Delay Time (Write)
   constant C_TIME_WBD : natural                            := 0;

   -- Precharge Command to Output in High-Z Delay Time (Read)
   constant C_TIME_RQL : natural                            := 3;

   -- Precharge Command to Input in Invalid Delay Time (Write)
   constant C_TIME_WDL : natural                            := 0;

   -- Last Output to Auto-Precharge Start Time (Read)
   constant C_TIME_PQL : integer                            := -2;

   -- DQM to Output Delay Time (Read)
   constant C_TIME_QMD : natural                            := 2;

   -- DQM to Input Delay Time (Write
   constant C_TIME_DMD : natural                            := 0;

   -- Mode Register Set to Command Delay Time
   constant C_TIME_MRD : natural                            := 2;

   -- Device commands:
   -- bit 2 : RAS#
   -- bit 1 : CAS#
   -- bit 0 : WE#
   constant C_NO_OPERATION   : std_logic_vector(2 downto 0) := "111";
   constant C_BURST_STOP     : std_logic_vector(2 downto 0) := "110";
   constant C_READ           : std_logic_vector(2 downto 0) := "101";
   constant C_WRITE          : std_logic_vector(2 downto 0) := "100";
   constant C_BANK_ACTIVATE  : std_logic_vector(2 downto 0) := "011";
   constant C_PRECHARGE_BANK : std_logic_vector(2 downto 0) := "010";     -- Same as de-activate
   constant C_AUTO_REFRESH   : std_logic_vector(2 downto 0) := "001";
   constant C_MODE_SET       : std_logic_vector(2 downto 0) := "000";

   type     state_type is (
      INIT_POWER_ON_ST,
      INIT_PRECHARGE_ST,
      INIT_REFRESH_1_ST,
      INIT_REFRESH_2_ST,
      INIT_SET_MODE_ST,
      IDLE_ST,
      ACTIVE_ST,
      WRITE_ST,
      READ_ST,
      PRECHARGE_ST
   );
   signal   state : state_type;
   signal   timer : natural range 0 to C_TIME_INIT_POWER_ON - 1;

   signal   avm_write      : std_logic;
   signal   avm_read       : std_logic;
   signal   avm_address    : std_logic_vector(31 downto 0);
   signal   avm_writedata  : std_logic_vector(15 downto 0);
   signal   avm_byteenable : std_logic_vector( 1 downto 0);
   signal   avm_burstcount : std_logic_vector( 7 downto 0);

   -- SDRAM device output interface
   signal   sdram_a       : std_logic_vector(12 downto 0)   := (others => '0');
   signal   sdram_ba      : std_logic_vector(1 downto 0)    := (others => '0');
   signal   sdram_cas_n   : std_logic                       := '1';
   signal   sdram_cke     : std_logic                       := '1';
   signal   sdram_cs_n    : std_logic                       := '1';
   signal   sdram_dqmh    : std_logic                       := '1';
   signal   sdram_dqml    : std_logic                       := '1';
   signal   sdram_dq_oe_n : std_logic_vector(15 downto 0)   := (others => '1');
   signal   sdram_dq_out  : std_logic_vector(15 downto 0)   := (others => '1');
   signal   sdram_ras_n   : std_logic                       := '1';
   signal   sdram_we_n    : std_logic                       := '1';

   signal   sdram_dq_in : std_logic_vector(15 downto 0);

   -- Make sure all sixteen flip-flops are preserved, even though
   -- they have identical inputs. This is necessary for the
   -- set_property IOB TRUE constraint to have effect.
   attribute dont_touch : string;
   attribute dont_touch of sdram_dq_oe_n : signal is "true";

begin

   -- This is just a dummy controller for the time being.
   -- All writes are ignored, and all reads return in the following
   -- clock cycle. Assumes burstcount = 1.
   avm_waitrequest_o <= '0' when state = IDLE_ST else
                        '1';

   avm_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         avm_readdatavalid_o <= '0';

         -- Data lines are high-Z by default
         sdram_dq_oe_n       <= (others => '1');
         sdram_dqmh          <= '1';
         sdram_dqml          <= '1';

         if timer > 0 then
            timer <= timer - 1;
         end if;

         sdram_cs_n  <= '1';
         sdram_ras_n <= C_NO_OPERATION(2);
         sdram_cas_n <= C_NO_OPERATION(1);
         sdram_we_n  <= C_NO_OPERATION(0);

         case state is

            when INIT_POWER_ON_ST =>
               -- A 100µs delay is required prior to issuing any command other than a
               -- COMMAND INHIBIT or a NOP.

               if timer = 0 then
                  sdram_cs_n  <= '0';
                  sdram_ras_n <= C_PRECHARGE_BANK(2);
                  sdram_cas_n <= C_PRECHARGE_BANK(1);
                  sdram_we_n  <= C_PRECHARGE_BANK(0);
                  sdram_a(10) <= '1';                                                         -- precharge all banks

                  timer       <= C_TIME_RP - 1;
                  state       <= INIT_PRECHARGE_ST;
               end if;

            when INIT_PRECHARGE_ST =>
               if timer = 0 then
                  sdram_cs_n  <= '0';
                  sdram_ras_n <= C_AUTO_REFRESH(2);
                  sdram_cas_n <= C_AUTO_REFRESH(1);
                  sdram_we_n  <= C_AUTO_REFRESH(0);
                  timer       <= C_TIME_RC - 1;
                  state       <= INIT_REFRESH_1_ST;
               end if;

            when INIT_REFRESH_1_ST =>
               if timer = 0 then
                  sdram_cs_n  <= '0';
                  sdram_ras_n <= C_AUTO_REFRESH(2);
                  sdram_cas_n <= C_AUTO_REFRESH(1);
                  sdram_we_n  <= C_AUTO_REFRESH(0);
                  timer       <= C_TIME_RC - 1;
                  state       <= INIT_REFRESH_2_ST;
               end if;

            when INIT_REFRESH_2_ST =>
               if timer = 0 then
                  sdram_cs_n          <= '0';
                  sdram_a             <= (others => '0');                                     -- Clear all reserved bits
                  sdram_a(9)          <= '1';                                                 -- Write burst mode = single location access
                  sdram_a(8 downto 7) <= "00";                                                -- standard operating mode
                  sdram_a(6 downto 4) <= "011";                                               -- CAS latency = 3 (i.e. 166 MHz)
                  sdram_a(3)          <= '0';                                                 -- burst type = sequential
                  sdram_a(2 downto 0) <= "000";                                               -- burst length = 1
                  sdram_ras_n         <= C_MODE_SET(2);
                  sdram_cas_n         <= C_MODE_SET(1);
                  sdram_we_n          <= C_MODE_SET(0);
                  timer               <= C_TIME_MRD - 1;
                  state               <= INIT_SET_MODE_ST;
               end if;

            when INIT_SET_MODE_ST =>
               if timer = 0 then
                  state <= IDLE_ST;
               end if;

            when IDLE_ST =>
               if avm_read_i = '1' or avm_write_i = '1' then
                  assert avm_read_i = '0' or avm_write_i = '0'
                     report "Simultaneous READ and WRITE not allowed";
                  assert avm_burstcount_i = X"01"
                     report "Dummy controller requires burstcount = 1";
                  avm_read       <= avm_read_i;
                  avm_write      <= avm_write_i;
                  avm_address    <= avm_address_i;
                  avm_writedata  <= avm_writedata_i;
                  avm_byteenable <= avm_byteenable_i;
                  avm_burstcount <= avm_burstcount_i;
                  sdram_cs_n     <= '0';
                  sdram_ras_n    <= C_BANK_ACTIVATE(2);
                  sdram_cas_n    <= C_BANK_ACTIVATE(1);
                  sdram_we_n     <= C_BANK_ACTIVATE(0);
                  sdram_a        <= avm_address_i(22 downto 10);                              -- row address
                  sdram_ba       <= avm_address_i(24 downto 23);                              -- bank address
                  timer          <= C_TIME_RCD - 1;
                  state          <= ACTIVE_ST;
               end if;

            when ACTIVE_ST =>
               if timer = 0 then
                  if avm_read = '1' then
                     sdram_cs_n          <= '0';
                     sdram_ras_n         <= C_READ(2);
                     sdram_cas_n         <= C_READ(1);
                     sdram_we_n          <= C_READ(0);
                     sdram_a             <= (others => '0');                                  -- Clear all reserved bits
                     sdram_a(9 downto 0) <= avm_address(9 downto 0);                          -- column address
                     sdram_a(10)         <= '0';                                              -- no precharge
                     sdram_ba            <= avm_address(24 downto 23);                        -- bank address
                     sdram_dqmh          <= '0';
                     sdram_dqml          <= '0';
                     timer               <= C_TIME_CAC;
                     state               <= READ_ST;
                  end if;
                  if avm_write = '1' then
                     sdram_cs_n          <= '0';
                     sdram_ras_n         <= C_WRITE(2);
                     sdram_cas_n         <= C_WRITE(1);
                     sdram_we_n          <= C_WRITE(0);
                     sdram_a             <= (others => '0');                                  -- Clear all reserved bits
                     sdram_a(9 downto 0) <= avm_address(9 downto 0);                          -- column address
                     sdram_a(10)         <= '0';                                              -- no precharge
                     sdram_ba            <= avm_address(24 downto 23);                        -- bank address
                     if C_TIME_DMD = 0 then
                        sdram_dqmh    <= not avm_byteenable(1);
                        sdram_dqml    <= not avm_byteenable(0);
                        sdram_dq_out  <= avm_writedata;
                        sdram_dq_oe_n <= (others => '0');
                     end if;
                     state <= WRITE_ST;
                  end if;
               end if;

            when WRITE_ST =>
               sdram_cs_n  <= '0';
               sdram_ras_n <= C_PRECHARGE_BANK(2);
               sdram_cas_n <= C_PRECHARGE_BANK(1);
               sdram_we_n  <= C_PRECHARGE_BANK(0);
               sdram_a(10) <= '1';                                                            -- precharge all banks
               timer       <= C_TIME_RP - 1;
               state       <= PRECHARGE_ST;

            when READ_ST =>
               if timer = C_TIME_QMD + 1 then
                  sdram_dqmh <= '0';
                  sdram_dqml <= '0';
               end if;
               if timer = 0 then
                  avm_readdata_o      <= sdram_dq_in;
                  avm_readdatavalid_o <= '1';
                  sdram_cs_n          <= '0';
                  sdram_ras_n         <= C_PRECHARGE_BANK(2);
                  sdram_cas_n         <= C_PRECHARGE_BANK(1);
                  sdram_we_n          <= C_PRECHARGE_BANK(0);
                  sdram_a(10)         <= '1';                                                 -- precharge all banks
                  timer               <= C_TIME_RP - 1;
                  state               <= PRECHARGE_ST;
               end if;

            when PRECHARGE_ST =>
               if timer = 0 then
                  state <= IDLE_ST;
               end if;

            when others =>
               state <= IDLE_ST;

         end case;

         if rst_i = '1' then
            avm_readdata_o      <= (others => '0');
            avm_readdatavalid_o <= '0';
            -- Keep clock-enable high all the time (it's asynchronous)
            sdram_cke           <= '1';
            -- Disable SDRAM chip-select by default
            sdram_cs_n          <= '1';
            -- By default, send NOP command
            sdram_ras_n         <= C_NO_OPERATION(2);
            sdram_cas_n         <= C_NO_OPERATION(1);
            sdram_we_n          <= C_NO_OPERATION(0);
            sdram_a             <= (others => '0');
            sdram_ba            <= (others => '0');
            sdram_dqmh          <= '1';
            sdram_dqml          <= '1';
            sdram_dq_oe_n       <= (others => '1');
            sdram_dq_out        <= (others => '1');
            timer               <= C_TIME_INIT_POWER_ON - 1;
            state               <= INIT_POWER_ON_ST;
         end if;
      end if;
   end process avm_proc;

   read_proc : process (clk_i)
   begin
      if falling_edge(clk_i) then
         sdram_dq_in <= sdram_dq_in_i;
      end if;
   end process read_proc;

   sdram_a_o         <= sdram_a;
   sdram_ba_o        <= sdram_ba;
   sdram_cas_n_o     <= sdram_cas_n;
   sdram_cke_o       <= sdram_cke;
   sdram_cs_n_o      <= sdram_cs_n;
   sdram_dqmh_o      <= sdram_dqmh;
   sdram_dqml_o      <= sdram_dqml;
   sdram_dq_oe_n_o   <= sdram_dq_oe_n;
   sdram_dq_out_o    <= sdram_dq_out;
   sdram_ras_n_o     <= sdram_ras_n;
   sdram_we_n_o      <= sdram_we_n;


   --------------------------------------------------------------------------
   -- Generate SDRAM clock equal to inverted clk_i.
   -- This forces the output clock register to be placed at the I/O pad.
   --------------------------------------------------------------------------

   oddr_inst : component oddr
      generic map (
         DDR_CLK_EDGE => "SAME_EDGE"
      )
      port map (
         d1 => '1',
         d2 => '0',
         ce => '1',
         q  => sdram_clk_o,
         c  => not clk_i
      ); -- oddr_inst

end architecture synthesis;

