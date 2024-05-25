-- Main testbench for the SDRAM controller.
-- This closely mimics the MEGA65 top level file, except that
-- clocks are generated directly, instead of via MMCM.
--
-- Created by Michael Jørgensen in 2024 (mjoergen.github.io/SDRAM).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity tb_sdram is
end entity tb_sdram;

architecture simulation of tb_sdram is

   constant C_CLK_PERIOD : time := 10 ns;                  -- 100 MHz

   signal   clk     : std_logic := '1';
   signal   rst     : std_logic := '1';
   signal   running : std_logic := '1';

   signal   tb_start  : std_logic;
   signal   tb_active : std_logic;

   -- Statistics
   signal   stat_total    : std_logic_vector(31 downto 0);
   signal   stat_error    : std_logic_vector(31 downto 0);
   signal   stat_err_addr : std_logic_vector(31 downto 0);
   signal   stat_err_exp  : std_logic_vector(31 downto 0);
   signal   stat_err_read : std_logic_vector(31 downto 0);

   signal   sys_resetn   : std_logic;
   signal   sys_csn      : std_logic;
   signal   sys_ck       : std_logic;
   signal   sys_rwds     : std_logic;
   signal   sys_dq       : std_logic_vector(7 downto 0);
   signal   sys_rwds_in  : std_logic;
   signal   sys_dq_in    : std_logic_vector(7 downto 0);
   signal   sys_rwds_out : std_logic;
   signal   sys_dq_out   : std_logic_vector(7 downto 0);
   signal   sys_rwds_oe  : std_logic;
   signal   sys_dq_oe    : std_logic;

   -- SDRAM simulation device interface
   signal   sdram_clk     : std_logic;
   signal   sdram_cke     : std_logic;
   signal   sdram_ras_n   : std_logic;
   signal   sdram_cas_n   : std_logic;
   signal   sdram_we_n    : std_logic;
   signal   sdram_cs_n    : std_logic;
   signal   sdram_ba      : std_logic_vector(1 downto 0);
   signal   sdram_a       : std_logic_vector(12 downto 0);
   signal   sdram_dqml    : std_logic;
   signal   sdram_dqmh    : std_logic;
   signal   sdram_dq_in   : std_logic_vector(15 downto 0);
   signal   sdram_dq_out  : std_logic_vector(15 downto 0);
   signal   sdram_dq_oe_n : std_logic_vector(15 downto 0); -- Output enable for DQ
   signal   sdram_dq      : std_logic_vector(15 downto 0);

begin

   ---------------------------------------------------------
   -- Generate clock and reset
   ---------------------------------------------------------

   clk <= running and not clk after C_CLK_PERIOD / 2;
   rst <= '1', '0' after 100 * C_CLK_PERIOD;


   --------------------------------------------------------
   -- Generate start signal for trafic generator
   --------------------------------------------------------

   tb_start_proc : process
   begin
      tb_start <= '0';
      wait for 160 us;
      wait until clk = '1';
      tb_start <= '1';
      wait until clk = '1';
      tb_start <= '0';
      wait;
   end process tb_start_proc;


   --------------------------------------------------------
   -- Instantiate core test generator
   --------------------------------------------------------

   core_wrapper_inst : entity work.core_wrapper
      generic map (
         G_SYS_ADDRESS_SIZE => 8,
         G_ADDRESS_SIZE     => 22,
         G_DATA_SIZE        => 16
      )
      port map (
         clk_i           => clk,
         rst_i           => rst,
         start_i         => tb_start,
         active_o        => tb_active,
         stat_total_o    => stat_total,
         stat_error_o    => stat_error,
         stat_err_addr_o => stat_err_addr,
         stat_err_exp_o  => stat_err_exp,
         stat_err_read_o => stat_err_read,
         sdram_clk_o     => sdram_clk,
         sdram_cke_o     => sdram_cke,
         sdram_ras_n_o   => sdram_ras_n,
         sdram_cas_n_o   => sdram_cas_n,
         sdram_we_n_o    => sdram_we_n,
         sdram_cs_n_o    => sdram_cs_n,
         sdram_ba_o      => sdram_ba,
         sdram_a_o       => sdram_a,
         sdram_dqml_o    => sdram_dqml,
         sdram_dqmh_o    => sdram_dqmh,
         sdram_dq_in_i   => sdram_dq_in,
         sdram_dq_out_o  => sdram_dq_out,
         sdram_dq_oe_n_o => sdram_dq_oe_n
      ); -- core_inst

   ----------------------------------
   -- Tri-state buffers for SDRAM
   ----------------------------------

   sdram_dq_gen : for i in sdram_dq'range generate
      sdram_dq(i) <= sdram_dq_out(i) when sdram_dq_oe_n(i) = '0' else
                     'Z';
   end generate sdram_dq_gen;

   sdram_dq_in <= sdram_dq;


   ---------------------------------------------------------
   -- Instantiate SDRAM simulation model
   ---------------------------------------------------------

   sdram_sim_inst : entity work.sdram_sim
      port map (
         sdram_clk_i   => sdram_clk,
         sdram_cke_i   => sdram_cke,
         sdram_ras_n_i => sdram_ras_n,
         sdram_cas_n_i => sdram_cas_n,
         sdram_we_n_i  => sdram_we_n,
         sdram_cs_n_i  => sdram_cs_n,
         sdram_ba_i    => sdram_ba,
         sdram_a_i     => sdram_a,
         sdram_dqml_i  => sdram_dqml,
         sdram_dqmh_i  => sdram_dqmh,
         sdram_dq_io   => sdram_dq
      ); -- sdram_sim

end architecture simulation;

