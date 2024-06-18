-- This is a simulation model for a SDR SDRAM.
-- It is designed to simulate an IS42S16320F-6BL
-- However, the SDRAM protocol is standardized, and this
-- file can easily be adapted to simulate other SDRAMs.
--
-- During read:
-- DQ’s read data is subject to the logic level on the DQM inputs two clocks earlier. When
-- a given DQM signal was registered HIGH, the corresponding DQ’s will be High-Z two
-- clocks later. DQ’s will provide valid data when the DQM signal was registered LOW.
--
-- Created by Michael Jørgensen in 2024 (mjoergen.github.io/SDRAM).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity sdram_sim is
   generic (
      G_RAM_DEBUG : boolean;
      G_RAM_SIZE  : natural -- Number of internal address bits
   );
   port (
      -- SDRAM device interface
      sdram_clk_i   : in    std_logic;
      sdram_cke_i   : in    std_logic;
      sdram_ras_n_i : in    std_logic;
      sdram_cas_n_i : in    std_logic;
      sdram_we_n_i  : in    std_logic;
      sdram_cs_n_i  : in    std_logic;
      sdram_ba_i    : in    std_logic_vector(1 downto 0);
      sdram_a_i     : in    std_logic_vector(12 downto 0);
      sdram_dqml_i  : in    std_logic;
      sdram_dqmh_i  : in    std_logic;
      sdram_dq_io   : inout std_logic_vector(15 downto 0)
   );
end entity sdram_sim;

architecture simulation of sdram_sim is

   constant C_CMD_SET_MODE   : std_logic_vector(2 downto 0) := "000";
   constant C_CMD_REFRESH    : std_logic_vector(2 downto 0) := "001";
   constant C_CMD_PRECHARGE  : std_logic_vector(2 downto 0) := "010";
   constant C_CMD_ACTIVATE   : std_logic_vector(2 downto 0) := "011";
   constant C_CMD_WRITE      : std_logic_vector(2 downto 0) := "100";
   constant C_CMD_READ       : std_logic_vector(2 downto 0) := "101";
   constant C_CMD_BURST_STOP : std_logic_vector(2 downto 0) := "110";
   constant C_CMD_NOP        : std_logic_vector(2 downto 0) := "111";

   constant C_ROW_SIZE : natural                            := 4096;

   type     string_vector_type is array (natural range <>) of string(1 to 10);
   constant C_CMD_STRINGS : string_vector_type(0 to 7)      :=
   (
      "Set Mode  ",
      "Refresh   ",
      "Precharge ",
      "Activate  ",
      "Write     ",
      "Read      ",
      "Burst Stop",
      "Nop       "
   );

   constant C_TIME_AC3 : time                               := 5.4 ns;  -- maximum
   constant C_TIME_OH  : time                               := 2.5 ns;  -- minimum
   constant C_TIME_RCD : time                               := 18.0 ns; -- minimum
   constant C_TIME_RP  : time                               := 18.0 ns; -- minimum
   constant C_TIME_RC  : time                               := 60.0 ns; -- minimum
   constant C_TIME_MRD : time                               := 12.0 ns; -- minimum

   type     ram_type is array (natural range <>) of std_logic_vector(15 downto 0);

   signal   sdram_cke_d  : std_logic;
   signal   dqm          : std_logic_vector(1 downto 0);
   signal   dqm_d        : std_logic_vector(1 downto 0);
   signal   dqm_dd       : std_logic_vector(1 downto 0);
   signal   dqm_ddd      : std_logic_vector(1 downto 0);
   signal   sdram_dq_out : std_logic_vector(15 downto 0);
   signal   sdram_dq     : std_logic_vector(15 downto 0);

   type     mode_type is record
      cas          : natural range 2 to 3;
      interleaved  : std_logic;
      burst_length : natural range 0 to 8;
      write_burst  : std_logic;
   end record mode_type;
   signal   mode : mode_type;

   type     bank_type is record
      row              : std_logic_vector(12 downto 0);
      active           : std_logic;
      next_allowed_cmd : time;
   end record bank_type;

   type     bank_vector_type is array (natural range <>) of bank_type;
   signal   banks : bank_vector_type(0 to 3);

   pure function get_mode (
      arg : std_logic_vector
   ) return mode_type is
      variable res_v : mode_type;
   begin
      assert arg(12 downto 10) = "000";
      res_v.write_burst := arg(9);
      assert arg(8 downto 7) = "00";
      res_v.cas         := to_integer(arg(6 downto 4));
      res_v.interleaved := arg(3);

      case arg(2 downto 0) is

         when "000" =>
            res_v.burst_length := 1;

         when "001" =>
            res_v.burst_length := 2;

         when "010" =>
            res_v.burst_length := 4;

         when "011" =>
            res_v.burst_length := 8;

         when others =>
            -- must be sequential access
            assert arg(3) = '0';

            -- full-row
            res_v.burst_length := 0;

      end case;

      return res_v;
   end function get_mode;

   pure function get_command (
      cke_d : std_logic;
      cs_n : std_logic;
      ras_n : std_logic;
      cas_n : std_logic;
      we_n : std_logic
   ) return std_logic_vector
   is
      variable res_v : std_logic_vector(2 downto 0);
   begin
      res_v := C_CMD_NOP;
      -- CS=1 is command inhibit
      if cke_d = '1' and cs_n = '0' then
         -- RAS, CAS, and WE together make up the command.
         res_v := ras_n & cas_n & we_n;
      end if;
      return res_v;
   end function get_command;

   signal   ram_addr     : std_logic_vector(24 downto 0)    := (others => '0');
   signal   ram_wr_en    : std_logic_vector(1 downto 0)     := (others => '0');
   signal   ram_wr_data  : std_logic_vector(15 downto 0)    := (others => '0');
   signal   ram_wr_count : natural range 0 to C_ROW_SIZE - 1;
   signal   ram_rd_en    : std_logic                        := '0';
   signal   ram_rd_data  : std_logic_vector(15 downto 0)    := (others => '0');
   signal   ram_rd_count : natural range 0 to C_ROW_SIZE - 1;
   signal   ram_offset   : natural range 0 to C_ROW_SIZE - 1;

begin

   dqm                   <= sdram_dqmh_i & sdram_dqml_i;

   ram_addr              <= (sdram_ba_i & banks(to_integer(sdram_ba_i)).row & sdram_a_i(9
                            downto 0)) + ram_offset;

   sdram_dq_out          <= transport ram_rd_data after ((mode.cas - 2) * 6 ns + C_TIME_AC3);

   sdram_dq(15 downto 8) <= sdram_dq_out(15 downto 8) when dqm_ddd(1) = '0' else
                            (others => 'Z');
   sdram_dq( 7 downto 0) <= sdram_dq_out( 7 downto 0) when dqm_ddd(0) = '0' else
                            (others => 'Z');

   -- The value 0.5 ns is the estimated round-trip delay on the PCB
   sdram_dq_io           <= transport sdram_dq after 0.5 ns;

   fsm_proc : process (sdram_clk_i)
      variable cmd_v : std_logic_vector(2 downto 0);
   begin
      if rising_edge(sdram_clk_i) then
         ram_rd_en   <= '0';
         ram_wr_en   <= (others => '0');
         dqm_d       <= dqm;
         dqm_dd      <= dqm_d;
         dqm_ddd     <= dqm_dd;
         sdram_cke_d <= sdram_cke_i;

         cmd_v       := get_command(sdram_cke_d, sdram_cs_n_i, sdram_ras_n_i, sdram_cas_n_i, sdram_we_n_i);

         if G_RAM_DEBUG then
            report C_CMD_STRINGS(to_integer(cmd_v));
         end if;

         case cmd_v is

            when C_CMD_SET_MODE =>
               assert sdram_ba_i = "00";
               mode <= get_mode(sdram_a_i);

               -- Require all banks to be idle
               bank_set_mode_loop : for bank in 0 to 3 loop
                  assert banks(bank).active = '0';
                  banks(bank).next_allowed_cmd <= now + C_TIME_MRD;
               end loop bank_set_mode_loop;

            when C_CMD_REFRESH =>
               -- Require all banks to be idle
               bank_refresh_loop : for bank in 0 to 3 loop
                  assert banks(bank).active = '0';
                  banks(bank).next_allowed_cmd <= now + C_TIME_RC;
               end loop bank_refresh_loop;

            when C_CMD_PRECHARGE =>
               if sdram_a_i(10) = '0' then
                  banks(to_integer(sdram_ba_i)).active           <= '0';
                  banks(to_integer(sdram_ba_i)).next_allowed_cmd <= now + C_TIME_RP;
               else

                  bank_precharge_loop : for bank in 0 to 3 loop
                     banks(bank).active           <= '0';
                     banks(bank).next_allowed_cmd <= now + C_TIME_RP;
                  end loop bank_precharge_loop;

               end if;
               ram_wr_en    <= (others => '0');
               ram_wr_data  <= (others => 'Z');
               ram_wr_count <= 0;
               ram_rd_en    <= '0';
               ram_rd_count <= 0;
               ram_offset   <= 0;

            when C_CMD_ACTIVATE =>
               assert now >= banks(to_integer(sdram_ba_i)).next_allowed_cmd;
               assert banks(to_integer(sdram_ba_i)).active = '0';
               banks(to_integer(sdram_ba_i)).row              <= sdram_a_i;
               banks(to_integer(sdram_ba_i)).active           <= '1';
               banks(to_integer(sdram_ba_i)).next_allowed_cmd <= now + C_TIME_RCD;

            when C_CMD_WRITE =>
               assert now >= banks(to_integer(sdram_ba_i)).next_allowed_cmd;
               assert banks(to_integer(sdram_ba_i)).active = '1';
               ram_wr_en   <= (not sdram_dqmh_i) & (not sdram_dqml_i);
               ram_wr_data <= sdram_dq_io;
               ram_offset  <= 0;
               if mode.burst_length > 0 then
                  ram_wr_count <= mode.burst_length - 1;
               else
                  ram_wr_count <= C_ROW_SIZE - 1;
               end if;
               if sdram_a_i(10) = '1' then
                  -- auto precharge
                  banks(to_integer(sdram_ba_i)).active           <= '0';
                  banks(to_integer(sdram_ba_i)).next_allowed_cmd <= now + C_TIME_RP;
               end if;

            when C_CMD_READ =>
               assert now >= banks(to_integer(sdram_ba_i)).next_allowed_cmd;
               assert banks(to_integer(sdram_ba_i)).active = '1';
               ram_rd_en  <= '1';
               ram_offset <= 0;
               if mode.burst_length > 0 then
                  ram_rd_count <= mode.burst_length - 1;
               else
                  ram_rd_count <= C_ROW_SIZE - 1;
               end if;
               if sdram_a_i(10) = '1' then
                  -- auto precharge
                  banks(to_integer(sdram_ba_i)).active           <= '0';
                  banks(to_integer(sdram_ba_i)).next_allowed_cmd <= now + C_TIME_RP;
               end if;

            when C_CMD_BURST_STOP =>
               ram_wr_en    <= (others => '0');
               ram_wr_data  <= (others => 'Z');
               ram_wr_count <= 0;
               ram_rd_en    <= '0';
               ram_rd_count <= 0;
               ram_offset   <= 0;

            when C_CMD_NOP =>
               if ram_rd_en = '1' and ram_rd_count > 0 then
                  ram_rd_en    <= '1';
                  ram_rd_count <= ram_rd_count - 1;
                  ram_offset   <= ram_offset + 1;
               end if;
               if ram_wr_count > 0 then
                  ram_wr_en    <= (not sdram_dqmh_i) & (not sdram_dqml_i);
                  ram_wr_data  <= sdram_dq_io;
                  ram_wr_count <= ram_wr_count - 1;
                  ram_offset   <= ram_offset + 1;
               end if;

            when others =>
               report "Illegal command"
                  severity failure;

         end case;

      end if;
   end process fsm_proc;


   --------------------------------------------------------------------------
   -- Instantiate RAM
   --------------------------------------------------------------------------

   ram_inst : entity work.ram
      generic map (
         G_ADDR_SIZE => G_RAM_SIZE,
         G_DATA_SIZE => 16
      )
      port map (
         clk_i     => sdram_clk_i,
         addr_i    => ram_addr(G_RAM_SIZE - 1 downto 0),
         wr_en_i   => ram_wr_en,
         wr_data_i => ram_wr_data,
         rd_en_i   => ram_rd_en,
         rd_data_o => ram_rd_data
      ); -- ram_inst

end architecture simulation;

