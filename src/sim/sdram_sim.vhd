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
      -- CAS: Initial value is 1, which will result in read error, if "SET MODE" command is not
      -- issued.
      cas          : natural range 1 to 3;
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

begin

   dqm                   <= sdram_dqmh_i & sdram_dqml_i;

   sdram_dq(15 downto 8) <= sdram_dq_out(15 downto 8) when dqm_ddd(1) = '0' else
                            (others => 'Z');
   sdram_dq( 7 downto 0) <= sdram_dq_out( 7 downto 0) when dqm_ddd(0) = '0' else
                            (others => 'Z');

   -- The value 0.5 ns is the estimated round-trip delay on the PCB
   sdram_dq_io           <= transport sdram_dq after 0.5 ns;

   ram_proc : process (sdram_clk_i)
      variable ram_v  : ram_type(0 to 2 ** G_RAM_SIZE - 1) := (others => X"FFFF");
      variable addr_v : std_logic_vector(24 downto 0);
      variable data_v : std_logic_vector(15 downto 0);
      variable cmd_v  : std_logic_vector(2 downto 0);
   begin
      if rising_edge(sdram_clk_i) then
         dqm_d       <= dqm;
         dqm_dd      <= dqm_d;
         dqm_ddd     <= dqm_dd;
         sdram_cke_d <= sdram_cke_i;

         -- CS=1 is command inhibit
         if sdram_cke_d = '1' and sdram_cs_n_i = '0' then
            -- RAS, CAS, and WE together make up the command.
            cmd_v := sdram_ras_n_i & sdram_cas_n_i & sdram_we_n_i;

            if G_RAM_DEBUG then
               report C_CMD_STRINGS(to_integer(cmd_v));
            end if;

            case cmd_v is

               when C_CMD_SET_MODE =>
                  assert sdram_ba_i = "00";
                  assert sdram_a_i(12 downto 10) = "000";
                  mode.write_burst <= sdram_a_i(9);
                  assert sdram_a_i(8 downto 7) = "00";
                  mode.cas         <= to_integer(sdram_a_i(6 downto 4));
                  mode.interleaved <= sdram_a_i(3);

                  case sdram_a_i(2 downto 0) is

                     when "000" =>
                        mode.burst_length <= 1;

                     when "001" =>
                        mode.burst_length <= 2;

                     when "010" =>
                        mode.burst_length <= 4;

                     when "011" =>
                        mode.burst_length <= 8;

                     when others =>
                        -- must be sequential access
                        assert sdram_a_i(3) = '0';

                        -- full-row
                        mode.burst_length <= 0;

                  end case;

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

               when C_CMD_ACTIVATE =>
                  assert now >= banks(to_integer(sdram_ba_i)).next_allowed_cmd;
                  assert banks(to_integer(sdram_ba_i)).active = '0';
                  banks(to_integer(sdram_ba_i)).row              <= sdram_a_i;
                  banks(to_integer(sdram_ba_i)).active           <= '1';
                  banks(to_integer(sdram_ba_i)).next_allowed_cmd <= now + C_TIME_RCD;

               when C_CMD_WRITE =>
                  assert now >= banks(to_integer(sdram_ba_i)).next_allowed_cmd;
                  assert banks(to_integer(sdram_ba_i)).active = '1';
                  addr_v := sdram_ba_i & banks(to_integer(sdram_ba_i)).row & sdram_a_i(9 downto 0);
                  if sdram_dqmh_i = '0' then
                     ram_v(to_integer(addr_v(G_RAM_SIZE - 1 downto 0)))(15 downto 8) := sdram_dq_io(15 downto 8);
                  end if;
                  if sdram_dqml_i = '0' then
                     ram_v(to_integer(addr_v(G_RAM_SIZE - 1 downto 0)))( 7 downto 0) := sdram_dq_io( 7 downto 0);
                  end if;
                  if sdram_a_i(10) = '1' then
                     -- auto precharge
                     banks(to_integer(sdram_ba_i)).active           <= '0';
                     banks(to_integer(sdram_ba_i)).next_allowed_cmd <= now + C_TIME_RP;
                  end if;

               when C_CMD_READ =>
                  assert now >= banks(to_integer(sdram_ba_i)).next_allowed_cmd;
                  assert banks(to_integer(sdram_ba_i)).active = '1';
                  addr_v       := sdram_ba_i & banks(to_integer(sdram_ba_i)).row & sdram_a_i(9 downto 0);
                  data_v       := ram_v(to_integer(addr_v(G_RAM_SIZE - 1 downto 0)));
                  sdram_dq_out <= transport data_v after ((mode.cas - 1) * 6 ns + C_TIME_AC3),
                                  (others => 'Z') after (mode.cas * 6 ns + C_TIME_OH);
                  if sdram_a_i(10) = '1' then
                     -- auto precharge
                     banks(to_integer(sdram_ba_i)).active           <= '0';
                     banks(to_integer(sdram_ba_i)).next_allowed_cmd <= now + C_TIME_RP;
                  end if;

               when C_CMD_BURST_STOP =>
                  null;

               when C_CMD_NOP =>
                  null;

               when others =>
                  report "Illegal command"
                     severity failure;

            end case;

         end if;
      end if;
   end process ram_proc;

end architecture simulation;

