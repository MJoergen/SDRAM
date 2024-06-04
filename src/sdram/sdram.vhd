-- This file contains the complete SDR SDRAM controller.
--
-- It is designed to communicate with an IS42S16320F-6BL.
-- However, the SDR SDRAM protocol is standardized, and this
-- file can easily be adapted to communicate with other SDR SDRAMs.
--
-- This module requires one clock:
-- clk_i          : 166 MHz : This is the main clock used for the Avalon MM
--                            interface as well as controlling the SDRAM
--                            device.
--
-- Addressing scheme:
-- Bank address   : BA0 and BA1 (i.e. 4 banks)
-- Row Address    : A0 - A12 (i.e. 8k)
-- Column Address : A0 - A9 (i.e. 1k)
-- Total : 25 address bits and 16 data bits = 64 MB.
--
-- Read takes 11 clock cycles.
-- Write takes 8 clock cycles.
-- Single cycle access can be achieved at 166/11 = 15 MHz.
-- Refresh takes 12 clock cycles, i.e. about 1% of bandwidth.
-- This version does not support burst mode.
--
-- Link to datasheet for "IS42S16320F-6BL":
-- https://www.issi.com/WW/pdf/42-45R-S_86400F-16320F.pdf
--
-- Created by Michael Jørgensen in 2024 (mjoergen.github.io/SDRAM).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

-- needed for ODDR

library unisim;
   use unisim.vcomponents.all;

entity sdram is
   port (
      clk_i               : in    std_logic;                     -- Main clock = 166 MHz
      rst_i               : in    std_logic;                     -- Synchronous reset

      -- Avalon Memory Map
      avm_waitrequest_o   : out   std_logic;
      avm_write_i         : in    std_logic;
      avm_read_i          : in    std_logic;
      avm_address_i       : in    std_logic_vector(31 downto 0);
      avm_writedata_i     : in    std_logic_vector(15 downto 0);
      avm_byteenable_i    : in    std_logic_vector( 1 downto 0);
      avm_burstcount_i    : in    std_logic_vector( 7 downto 0);
      avm_readdata_o      : out   std_logic_vector(15 downto 0);
      avm_readdatavalid_o : out   std_logic;

      -- SDRAM device interface
      sdram_a_o           : out   std_logic_vector(12 downto 0);
      sdram_ba_o          : out   std_logic_vector(1 downto 0);
      sdram_cas_n_o       : out   std_logic;
      sdram_cke_o         : out   std_logic;
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

   constant C_CLOCK_SPEED_MHZ : natural                     := 166;

   -- The below constants are taken from the datasheet.

   -- Power-on time set to 102 us (rather than 100 us), to allow some extra margin, and
   -- account for possible inaccuracies in clock frequency.
   constant C_TIME_INIT_POWER_ON : natural                  := 102 * C_CLOCK_SPEED_MHZ;

   -- CAS# latency
   constant C_TIME_CAC : natural                            := 3;

   -- Active Command to Read/Write Command Delay Time
   constant C_TIME_RCD : natural                            := 3;

   -- RAS# latency (t_RCD + t_CAC)
   -- Not used.
   constant C_TIME_RAC : natural                            := 6;

   -- Command Period (REF to REF / ACT to ACT)
   constant C_TIME_RC : natural                             := 10;

   -- Command Period (ACT to PRE)
   -- Not used.
   constant C_TIME_RAS : natural                            := 7;

   -- Command Period (PRE to ACT)
   constant C_TIME_RP : natural                             := 3;

   -- Command Period (ACT[0] to ACT[1])
   -- Not used.
   constant C_TIME_RRD : natural                            := 2;

   -- Column Command Delay Time (READ, WRITE)
   -- Not used.
   constant C_TIME_CCD : natural                            := 1;

   -- Input Data to Precharge Command Delay Time
   -- Not used.
   constant C_TIME_DPL : natural                            := 2;

   -- Input Data to Active/Refresh Command Delay Time
   -- Not used.
   constant C_TIME_DAL : natural                            := 5;

   -- Burst Stop Command to Output in High-Z Delay Time (Read)
   -- Not used.
   constant C_TIME_RBD : natural                            := 3;

   -- Burst Stop Command to Input in Invalid Delay Time (Write)
   -- Not used.
   constant C_TIME_WBD : natural                            := 0;

   -- Precharge Command to Output in High-Z Delay Time (Read)
   -- Not used.
   constant C_TIME_RQL : natural                            := 3;

   -- Precharge Command to Input in Invalid Delay Time (Write)
   -- Not used.
   constant C_TIME_WDL : natural                            := 0;

   -- Last Output to Auto-Precharge Start Time (Read)
   -- Not used.
   constant C_TIME_PQL : integer                            := -2;

   -- DQM to Output Delay Time (Read)
   constant C_TIME_QMD : natural                            := 2;

   -- DQM to Input Delay Time (Write
   constant C_TIME_DMD : natural                            := 0;

   -- Mode Register Set to Command Delay Time
   constant C_TIME_MRD : natural                            := 2;

   -- Interval between refresh commands (in clock cycles):
   -- We must send 8192 refresh commands in the span of 64 ms.
   -- Subtract small value to compensate for time spent in previous command
   constant C_TIME_REFRESH : natural                        := C_CLOCK_SPEED_MHZ * 1000 * 64 / 8192 - 12;

   -- Device commands:
   -- bit 2 : RAS#
   -- bit 1 : CAS#
   -- bit 0 : WE#
   constant C_NO_OPERATION   : std_logic_vector(2 downto 0) := "111";
   constant C_BURST_STOP     : std_logic_vector(2 downto 0) := "110";
   constant C_READ           : std_logic_vector(2 downto 0) := "101";
   constant C_WRITE          : std_logic_vector(2 downto 0) := "100";
   constant C_BANK_ACTIVATE  : std_logic_vector(2 downto 0) := "011";
   constant C_PRECHARGE_BANK : std_logic_vector(2 downto 0) := "010"; -- Same as de-activate
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
      PRECHARGE_ST,
      REFRESH_ST
   );
   signal   state         : state_type;
   signal   timer_cmd     : natural range 0 to C_TIME_INIT_POWER_ON - 1;
   signal   timer_refresh : natural range 0 to C_TIME_REFRESH - 1;

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

   -- SDRAM device input interface
   signal   sdram_dq_in : std_logic_vector(15 downto 0);

   -- Make sure all sixteen flip-flops are preserved, even though
   -- they have identical inputs. This is necessary for the
   -- set_property IOB TRUE constraint to have effect.
   attribute dont_touch : string;
   attribute dont_touch of sdram_dq_oe_n : signal is "true";

--   attribute mark_debug : string;
--   attribute mark_debug of sdram_a       : signal is "true";
--   attribute mark_debug of sdram_ba      : signal is "true";
--   attribute mark_debug of sdram_cas_n   : signal is "true";
--   attribute mark_debug of sdram_cke     : signal is "true";
--   attribute mark_debug of sdram_cs_n    : signal is "true";
--   attribute mark_debug of sdram_dqmh    : signal is "true";
--   attribute mark_debug of sdram_dqml    : signal is "true";
--   attribute mark_debug of sdram_dq_oe_n : signal is "true";
--   attribute mark_debug of sdram_dq_out  : signal is "true";
--   attribute mark_debug of sdram_ras_n   : signal is "true";
--   attribute mark_debug of sdram_we_n    : signal is "true";
--   attribute mark_debug of sdram_dq_in   : signal is "true";

--   attribute mark_debug of avm_waitrequest_o   : signal is "true";
--   attribute mark_debug of avm_write_i         : signal is "true";
--   attribute mark_debug of avm_read_i          : signal is "true";
--   attribute mark_debug of avm_address_i       : signal is "true";
--   attribute mark_debug of avm_writedata_i     : signal is "true";
--   attribute mark_debug of avm_byteenable_i    : signal is "true";
--   attribute mark_debug of avm_readdata_o      : signal is "true";
--   attribute mark_debug of avm_readdatavalid_o : signal is "true";

begin

   avm_waitrequest_o <= '0' when state = IDLE_ST and timer_refresh /= 0 else
                        '1';

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

   avm_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         avm_readdatavalid_o <= '0';

         -- Data lines are high-Z by default
         sdram_dq_oe_n       <= (others => '1');
         sdram_dqmh          <= '1';
         sdram_dqml          <= '1';

         if timer_cmd > 0 then
            timer_cmd <= timer_cmd - 1;
         end if;

         if timer_refresh > 0 then
            timer_refresh <= timer_refresh - 1;
         end if;

         -- Default command is NOP
         sdram_cs_n  <= '1';
         sdram_ras_n <= C_NO_OPERATION(2);
         sdram_cas_n <= C_NO_OPERATION(1);
         sdram_we_n  <= C_NO_OPERATION(0);

         case state is

            when INIT_POWER_ON_ST =>
               -- A 100µs delay is required prior to issuing any command other than a
               -- COMMAND INHIBIT or a NOP.

               if timer_cmd = 0 then
                  sdram_cs_n  <= '0';
                  sdram_ras_n <= C_PRECHARGE_BANK(2);
                  sdram_cas_n <= C_PRECHARGE_BANK(1);
                  sdram_we_n  <= C_PRECHARGE_BANK(0);
                  -- precharge all banks
                  sdram_a(10) <= '1';

                  timer_cmd   <= C_TIME_RP - 1;
                  state       <= INIT_PRECHARGE_ST;
               end if;

            when INIT_PRECHARGE_ST =>
               if timer_cmd = 0 then
                  sdram_cs_n  <= '0';
                  sdram_ras_n <= C_AUTO_REFRESH(2);
                  sdram_cas_n <= C_AUTO_REFRESH(1);
                  sdram_we_n  <= C_AUTO_REFRESH(0);
                  timer_cmd   <= C_TIME_RC - 1;
                  state       <= INIT_REFRESH_1_ST;
               end if;

            when INIT_REFRESH_1_ST =>
               if timer_cmd = 0 then
                  sdram_cs_n    <= '0';
                  sdram_ras_n   <= C_AUTO_REFRESH(2);
                  sdram_cas_n   <= C_AUTO_REFRESH(1);
                  sdram_we_n    <= C_AUTO_REFRESH(0);
                  timer_refresh <= C_TIME_REFRESH - 1;
                  timer_cmd     <= C_TIME_RC - 1;
                  state         <= INIT_REFRESH_2_ST;
               end if;

            when INIT_REFRESH_2_ST =>
               if timer_cmd = 0 then
                  sdram_cs_n          <= '0';
                  sdram_a             <= (others => '0');               -- Clear all reserved bits
                  sdram_a(9)          <= '1';                           -- Write burst mode = single location access
                  sdram_a(8 downto 7) <= "00";                          -- standard operating mode
                  sdram_a(6 downto 4) <= "011";                         -- CAS latency = 3 (i.e. 166 MHz)
                  sdram_a(3)          <= '0';                           -- burst type = sequential
                  sdram_a(2 downto 0) <= "000";                         -- burst length = 1
                  sdram_ras_n         <= C_MODE_SET(2);
                  sdram_cas_n         <= C_MODE_SET(1);
                  sdram_we_n          <= C_MODE_SET(0);
                  timer_cmd           <= C_TIME_MRD - 1;
                  state               <= INIT_SET_MODE_ST;
               end if;

            when INIT_SET_MODE_ST =>
               if timer_cmd = 0 then
                  state <= IDLE_ST;
               end if;

            when IDLE_ST =>
               if timer_refresh = 0 then
                  timer_refresh <= C_TIME_REFRESH - 1;
                  timer_cmd     <= C_TIME_RC;
                  sdram_cs_n    <= '0';
                  sdram_ras_n   <= C_AUTO_REFRESH(2);
                  sdram_cas_n   <= C_AUTO_REFRESH(1);
                  sdram_we_n    <= C_AUTO_REFRESH(0);
                  state         <= REFRESH_ST;
               elsif avm_read_i = '1' or avm_write_i = '1' then
                  assert avm_read_i = '0' or avm_write_i = '0'
                     report "Simultaneous READ and WRITE not allowed";
                  assert avm_burstcount_i = X"01"
                     report "This controller requires burstcount = 1";
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
                  sdram_a        <= avm_address_i(22 downto 10);        -- row address
                  sdram_ba       <= avm_address_i(24 downto 23);        -- bank address
                  timer_cmd      <= C_TIME_RCD - 1;
                  state          <= ACTIVE_ST;
               end if;

            when ACTIVE_ST =>
               if timer_cmd = 0 then
                  if avm_read = '1' then
                     sdram_cs_n          <= '0';
                     sdram_ras_n         <= C_READ(2);
                     sdram_cas_n         <= C_READ(1);
                     sdram_we_n          <= C_READ(0);
                     sdram_a             <= (others => '0');            -- Clear all reserved bits
                     sdram_a(9 downto 0) <= avm_address(9 downto 0);    -- column address
                     sdram_a(10)         <= '0';                        -- no automatic precharge
                     sdram_ba            <= avm_address(24 downto 23);  -- bank address
                     timer_cmd           <= C_TIME_CAC+1;
                     state               <= READ_ST;
                  end if;
                  if avm_write = '1' then
                     sdram_cs_n          <= '0';
                     sdram_ras_n         <= C_WRITE(2);
                     sdram_cas_n         <= C_WRITE(1);
                     sdram_we_n          <= C_WRITE(0);
                     sdram_a             <= (others => '0');            -- Clear all reserved bits
                     sdram_a(9 downto 0) <= avm_address(9 downto 0);    -- column address
                     sdram_a(10)         <= '0';                        -- no automatic precharge
                     sdram_ba            <= avm_address(24 downto 23);  -- bank address
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
               sdram_a(10) <= '1';                                      -- precharge all banks
               timer_cmd   <= C_TIME_RP - 1;
               state       <= PRECHARGE_ST;

            when READ_ST =>
               if timer_cmd = C_TIME_QMD + 2 then
                  sdram_dqmh <= '0';
                  sdram_dqml <= '0';
               end if;
               if timer_cmd = 0 then
                  avm_readdata_o      <= sdram_dq_in;
                  avm_readdatavalid_o <= '1';
                  sdram_cs_n          <= '0';
                  sdram_ras_n         <= C_PRECHARGE_BANK(2);
                  sdram_cas_n         <= C_PRECHARGE_BANK(1);
                  sdram_we_n          <= C_PRECHARGE_BANK(0);
                  sdram_a(10)         <= '1';                           -- precharge all banks
                  timer_cmd           <= C_TIME_RP - 1;
                  state               <= PRECHARGE_ST;
               end if;

            when PRECHARGE_ST =>
               if timer_cmd = 0 then
                  state <= IDLE_ST;
               end if;

            when REFRESH_ST =>
               if timer_cmd = 0 then
                  state <= IDLE_ST;
               end if;

            when others =>
               state <= IDLE_ST;

         end case;

         if rst_i = '1' then
            avm_readdata_o      <= (others => '0');
            avm_readdatavalid_o <= '0';
            -- Keep clock-enable high all the time
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
            timer_cmd           <= C_TIME_INIT_POWER_ON - 1;
            state               <= INIT_POWER_ON_ST;
         end if;
      end if;
   end process avm_proc;

   -- Sample data from SDRAM directly into register
   read_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         sdram_dq_in <= sdram_dq_in_i;
      end if;
   end process read_proc;


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

