-- This is a simulation model for an SDRAM.

-- Created by Michael Jørgensen in 2024 (mjoergen.github.io/SDRAM).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity sdram_sim is
   generic (
      G_RAM_DEBUG : boolean := false;
      G_RAM_SIZE  : natural := 8
   );
   port (
      -- SDRAM device interface
      -- SDRAM - 32M x 16 bit, 3.3V VCC. U44 = IS42S16320F-6BL
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
      sdram_dq_io   : inout std_logic_vector(15 downto 0) := (others => 'Z')
   );
end entity sdram_sim;

architecture simulation of sdram_sim is

   constant C_T_AC3 : time := 5.4 ns; -- t_AC3 has maximum 5.4 ns
   constant C_T_OH  : time := 2.5 ns; -- t_OH has minimum 2.5 ns

   type     ram_type is array (natural range <>) of std_logic_vector(15 downto 0);

   signal   sdram_cke_d  : std_logic;
   signal   dqm          : std_logic_vector(1 downto 0);
   signal   dqm_d        : std_logic_vector(1 downto 0);
   signal   dqm_dd       : std_logic_vector(1 downto 0);
   signal   dqm_ddd      : std_logic_vector(1 downto 0);
   signal   sdram_dq_out : std_logic_vector(15 downto 0);

begin

   dqm                      <= sdram_dqmh_i & sdram_dqml_i;

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

         if sdram_cke_d = '1' and sdram_cs_n_i = '0' then
            cmd_v := sdram_ras_n_i & sdram_cas_n_i & sdram_we_n_i;

            case cmd_v is

               when "000" =>
                  if G_RAM_DEBUG then
                     report "Mode register set";
                  end if;

               when "001" =>
                  if G_RAM_DEBUG then
                     report "Refresh";
                  end if;

               when "010" =>
                  if G_RAM_DEBUG then
                     report "Precharge";
                  end if;

               when "011" =>
                  if G_RAM_DEBUG then
                     report "Activate";
                  end if;
                  addr_v(24 downto 10) := sdram_ba_i & sdram_a_i;

               when "100" =>
                  addr_v(9 downto 0) := sdram_a_i(9 downto 0);
                  if sdram_dqmh_i = '0' then
                     ram_v(to_integer(addr_v(G_RAM_SIZE - 1 downto 0)))(15 downto 8) := sdram_dq_io(15 downto 8);
                  end if;
                  if sdram_dqml_i = '0' then
                     ram_v(to_integer(addr_v(G_RAM_SIZE - 1 downto 0)))( 7 downto 0) := sdram_dq_io( 7 downto 0);
                  end if;
                  if G_RAM_DEBUG then
                     report "Write " & to_hstring(sdram_dq_io) & " to address " &
                            to_hstring(addr_v) & " with byte-enable " & to_string(dqm);
                  end if;

               when "101" =>
                  addr_v(9 downto 0) := sdram_a_i(9 downto 0);
                  data_v             := ram_v(to_integer(addr_v(G_RAM_SIZE - 1 downto 0)));
                  if G_RAM_DEBUG then
                     report "Read from address " & to_hstring(addr_v) & " returning " & to_hstring(data_v);
                  end if;
                  sdram_dq_out <= transport data_v after (2 * 6 ns + C_T_AC3),
                                  (others => 'Z') after (3 * 6 ns + C_T_OH);

               when "110" =>
                  if G_RAM_DEBUG then
                     report "Burst stop";
                  end if;

               when "111" =>
                  if G_RAM_DEBUG then
                     report "NOP";
                  end if;

               when others =>
                  report "Illegal command"
                     severity failure;

            end case;

         end if;
      end if;
   end process ram_proc;

   sdram_dq_io(15 downto 8) <= sdram_dq_out(15 downto 8) when dqm_ddd(1) = '0' else
                               (others => 'Z');
   sdram_dq_io( 7 downto 0) <= sdram_dq_out( 7 downto 0) when dqm_ddd(0) = '0' else
                               (others => 'Z');


end architecture simulation;

