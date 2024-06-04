-- Main testbench for the SDRAM controller.
-- This closely mimics the MEGA65 top level file, except that
-- clocks are generated directly, instead of via MMCM.
--
-- Created by Michael Jørgensen in 2024 (mjoergen.github.io/SDRAM).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity tb_sdram_mega65r6 is
end entity tb_sdram_mega65r6;

architecture simulation of tb_sdram_mega65r6 is

   constant C_CLK_PERIOD : time      := 10 ns; -- 100 MHz

   signal   running      : std_logic := '1';
   signal   sys_clk      : std_logic := '1';   -- 100 MHz clock
   signal   sys_rst      : std_logic := '1';   -- CPU reset button (active high)
   signal   sdram_clk    : std_logic;
   signal   sdram_cke    : std_logic;
   signal   sdram_ras_n  : std_logic;
   signal   sdram_cas_n  : std_logic;
   signal   sdram_we_n   : std_logic;
   signal   sdram_cs_n   : std_logic;
   signal   sdram_ba     : std_logic_vector(1 downto 0);
   signal   sdram_a      : std_logic_vector(12 downto 0);
   signal   sdram_dqml   : std_logic;
   signal   sdram_dqmh   : std_logic;
   signal   sdram_dq     : std_logic_vector(15 downto 0);
   signal   kb_io0       : std_logic;
   signal   kb_io1       : std_logic := '1';
   signal   kb_io2       : std_logic := '1';
   signal   uart_rx      : std_logic := '1';
   signal   uart_tx      : std_logic;
   signal   vga_red      : std_logic_vector(7 downto 0);
   signal   vga_green    : std_logic_vector(7 downto 0);
   signal   vga_blue     : std_logic_vector(7 downto 0);
   signal   vga_hs       : std_logic;
   signal   vga_vs       : std_logic;
   signal   vdac_clk     : std_logic;
   signal   vdac_blank_n : std_logic;
   signal   vdac_psave_n : std_logic;
   signal   vdac_sync_n  : std_logic;

   signal   tx_valid : std_logic;
   signal   tx_ready : std_logic;
   signal   tx_data  : std_logic_vector(7 downto 0);
   signal   rx_valid : std_logic;
   signal   rx_ready : std_logic;
   signal   rx_data  : std_logic_vector(7 downto 0);
   signal   rx_str   : std_logic_vector(31 downto 0);

begin

   ---------------------------------------------------------
   -- Generate clock and reset
   ---------------------------------------------------------

   sys_clk <= running and not sys_clk after C_CLK_PERIOD / 2;
   sys_rst <= '1', '0' after 100 * C_CLK_PERIOD;


   ---------------------------------------------------------
   -- Instantiate top level file
   ---------------------------------------------------------

   sdram_mega65r6_inst : entity work.sdram_mega65r6
      generic map (
         G_SYS_ADDRESS_SIZE => 8,
         G_FONT_PATH        => "../Example_Design/mega65/video/"
      )
      port map (
         sys_clk_i      => sys_clk,
         sys_rst_i      => sys_rst,
         sdram_clk_o    => sdram_clk,
         sdram_cke_o    => sdram_cke,
         sdram_ras_n_o  => sdram_ras_n,
         sdram_cas_n_o  => sdram_cas_n,
         sdram_we_n_o   => sdram_we_n,
         sdram_cs_n_o   => sdram_cs_n,
         sdram_ba_o     => sdram_ba,
         sdram_a_o      => sdram_a,
         sdram_dqml_o   => sdram_dqml,
         sdram_dqmh_o   => sdram_dqmh,
         sdram_dq_io    => sdram_dq,
         kb_io0_o       => kb_io0,
         kb_io1_o       => kb_io1,
         kb_io2_i       => kb_io2,
         uart_rx_i      => uart_rx,
         uart_tx_o      => uart_tx,
         vga_red_o      => vga_red,
         vga_green_o    => vga_green,
         vga_blue_o     => vga_blue,
         vga_hs_o       => vga_hs,
         vga_vs_o       => vga_vs,
         vdac_clk_o     => vdac_clk,
         vdac_blank_n_o => vdac_blank_n,
         vdac_psave_n_o => vdac_psave_n,
         vdac_sync_n_o  => vdac_sync_n
      ); -- sdram_mega65r6_inst


   ---------------------------------------------------------
   -- Instantiate SDRAM simulation model
   ---------------------------------------------------------

   sdram_sim_inst : entity work.sdram_sim
      generic map (
         G_RAM_DEBUG => false,
         G_RAM_SIZE  => 8 -- Number of internal address bits
      )
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

   uart_inst : entity work.uart
      generic map (
         G_DIVISOR => 100 / 2
      )
      port map (
         clk_i      => sys_clk,
         rst_i      => sys_rst,
         tx_valid_i => tx_valid,
         tx_ready_o => tx_ready,
         tx_data_i  => tx_data,
         rx_valid_o => rx_valid,
         rx_ready_i => rx_ready,
         rx_data_o  => rx_data,
         uart_tx_o  => uart_rx,
         uart_rx_i  => uart_tx
      ); -- uart_inst

   rx_str_proc : process (sys_clk)
   begin
      if rising_edge(sys_clk) then
         if rx_valid and rx_ready then
            rx_str <= rx_str(rx_str'left - 8 downto 0) & rx_data;
         end if;
      end if;
   end process rx_str_proc;


   test_proc : process
   begin
      report "Test started";

      tx_valid <= '0';
      rx_ready <= '1';
      wait until sys_rst = '0';

      -- Wait until SDRAM is initialized
      wait for 100 us;
      wait until sys_clk = '1';

      -- Wait until initial welcome message is sent.
      if rx_str /= X"0D0A0D0A" then
         wait until rx_str = X"0D0A0D0A";
      end if;
      wait until sys_clk = '1';

      -- Start test by sending the "RETURN" key.
      tx_data  <= X"0D";
      tx_valid <= '1';
      wait until sys_clk = '1';
      if tx_ready /= '1' then
         wait until tx_ready /= '1';
      end if;
      wait until sys_clk = '1';
      tx_valid <= '0';
      wait until sys_clk = '1';

      -- Wait until new message is started (indicating the test is over).
      if rx_valid /= '1' then
         wait until rx_valid = '1';
      end if;
      wait until sys_clk = '1';

      wait for 10 us;
      running  <= '0';

      report "Test finished";
      wait;
   end process test_proc;

end architecture simulation;

