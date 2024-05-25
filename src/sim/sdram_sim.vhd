-- This is a simulation model for an SDRAM.

-- Created by Michael Jørgensen in 2024 (mjoergen.github.io/SDRAM).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity sdram_sim is
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
      sdram_dq_io   : inout std_logic_vector(15 downto 0)
   );
end entity sdram_sim;

architecture simulation of sdram_sim is

begin

   sdram_dq_io <= (others => 'H');

end architecture simulation;

