-- This is the top-level file for the MEGA65 platform (revision 6).
--
-- Created by Michael Jørgensen in 2024 (mjoergen.github.io/SDRAM).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity sdram_mega65r6 is
   generic (
      G_SYS_ADDRESS_SIZE : integer := 19;
      G_FONT_PATH        : string  := ""
   );
   port (
      sys_clk_i      : in    std_logic; -- 100 MHz clock
      sys_rst_i      : in    std_logic; -- CPU reset button (active high)

      -- SDRAM - 32M x 16 bit, 3.3V VCC. U44 = IS42S16320F-6BL
      sdram_clk_o    : out   std_logic;
      sdram_cke_o    : out   std_logic;
      sdram_ras_n_o  : out   std_logic;
      sdram_cas_n_o  : out   std_logic;
      sdram_we_n_o   : out   std_logic;
      sdram_cs_n_o   : out   std_logic;
      sdram_ba_o     : out   std_logic_vector(1 downto 0);
      sdram_a_o      : out   std_logic_vector(12 downto 0);
      sdram_dqml_o   : out   std_logic;
      sdram_dqmh_o   : out   std_logic;
      sdram_dq_io    : inout std_logic_vector(15 downto 0);

      -- MEGA65 keyboard
      kb_io0_o       : out   std_logic;
      kb_io1_o       : out   std_logic;
      kb_io2_i       : in    std_logic;

      -- UART
      uart_rx_i      : in    std_logic;
      uart_tx_o      : out   std_logic;

      -- VGA
      vga_red_o      : out   std_logic_vector(7 downto 0);
      vga_green_o    : out   std_logic_vector(7 downto 0);
      vga_blue_o     : out   std_logic_vector(7 downto 0);
      vga_hs_o       : out   std_logic;
      vga_vs_o       : out   std_logic;
      vdac_clk_o     : out   std_logic;
      vdac_blank_n_o : out   std_logic;
      vdac_psave_n_o : out   std_logic;
      vdac_sync_n_o  : out   std_logic
   );
end entity sdram_mega65r6;

architecture synthesis of sdram_mega65r6 is

   constant C_SYS_ADDRESS_SIZE : integer := G_SYS_ADDRESS_SIZE;
   -- The SDRAM has 32M addresses and 16 data bits,
   -- i.e. a total of 512 Mbits = 64 MBytes.
   constant C_ADDRESS_SIZE     : integer := 25;
   constant C_DATA_SIZE        : integer := 16;

   -- SDRAM controller clocks and reset
   signal   ctrl_clk : std_logic;                          -- SDRAM controller clock
   signal   ctrl_rst : std_logic;                          -- SDRAM controller reset (active high)

   signal   ctrl_key_valid     : std_logic;
   signal   ctrl_key_ready     : std_logic;
   signal   ctrl_key_data      : std_logic_vector(7 downto 0);
   signal   ctrl_uart_rx_valid : std_logic;
   signal   ctrl_uart_rx_ready : std_logic;
   signal   ctrl_uart_rx_data  : std_logic_vector(7 downto 0);
   signal   ctrl_uart_tx_valid : std_logic;
   signal   ctrl_uart_tx_ready : std_logic;
   signal   ctrl_uart_tx_data  : std_logic_vector(7 downto 0);

   -- Control and Status for trafic generator
   signal   ctrl_start         : std_logic;
   signal   ctrl_active        : std_logic;
   signal   ctrl_stat_total    : std_logic_vector(31 downto 0);
   signal   ctrl_stat_error    : std_logic_vector(31 downto 0);
   signal   ctrl_stat_err_addr : std_logic_vector(31 downto 0);
   signal   ctrl_stat_err_exp  : std_logic_vector(31 downto 0);
   signal   ctrl_stat_err_read : std_logic_vector(31 downto 0);

   signal   sdram_dq_in   : std_logic_vector(15 downto 0);
   signal   sdram_dq_out  : std_logic_vector(15 downto 0);
   signal   sdram_dq_oe_n : std_logic_vector(15 downto 0); -- Output enable for DQ

   signal   video_clk    : std_logic;
   signal   video_rst    : std_logic;
   signal   video_pos_x  : std_logic_vector(7 downto 0);
   signal   video_pos_y  : std_logic_vector(7 downto 0);
   signal   video_char   : std_logic_vector(7 downto 0);
   signal   video_colors : std_logic_vector(15 downto 0);

begin

   ----------------------------------------------------------
   -- Instantiate MEGA65 platform interface
   ----------------------------------------------------------

   mega65_wrapper_inst : entity work.mega65_wrapper
      generic map (
         G_FONT_PATH => G_FONT_PATH
      )
      port map (
         -- MEGA65 I/O ports
         sys_clk_i            => sys_clk_i,
         sys_rst_i            => sys_rst_i,
         uart_rx_i            => uart_rx_i,
         uart_tx_o            => uart_tx_o,
         kb_io0_o             => kb_io0_o,
         kb_io1_o             => kb_io1_o,
         kb_io2_i             => kb_io2_i,
         vga_red_o            => vga_red_o,
         vga_green_o          => vga_green_o,
         vga_blue_o           => vga_blue_o,
         vga_hs_o             => vga_hs_o,
         vga_vs_o             => vga_vs_o,
         vdac_clk_o           => vdac_clk_o,
         vdac_blank_n_o       => vdac_blank_n_o,
         vdac_psave_n_o       => vdac_psave_n_o,
         vdac_sync_n_o        => vdac_sync_n_o,
         -- Connection to core
         ctrl_clk_o           => ctrl_clk,
         ctrl_rst_o           => ctrl_rst,
         ctrl_key_valid_o     => ctrl_key_valid,
         ctrl_key_ready_i     => ctrl_key_ready,
         ctrl_key_data_o      => ctrl_key_data,
         ctrl_uart_rx_valid_o => ctrl_uart_rx_valid,
         ctrl_uart_rx_ready_i => ctrl_uart_rx_ready,
         ctrl_uart_rx_data_o  => ctrl_uart_rx_data,
         ctrl_uart_tx_valid_i => ctrl_uart_tx_valid,
         ctrl_uart_tx_ready_o => ctrl_uart_tx_ready,
         ctrl_uart_tx_data_i  => ctrl_uart_tx_data,
         video_clk_o          => video_clk,
         video_rst_o          => video_rst,
         video_pos_x_o        => video_pos_x,
         video_pos_y_o        => video_pos_y,
         video_char_i         => video_char,
         video_colors_i       => video_colors
      ); -- mega65_wrapper_inst


   ----------------------------------------------------------
   -- Controller
   ----------------------------------------------------------

   controller_wrapper_inst : entity work.controller_wrapper
      port map (
         ctrl_clk_i           => ctrl_clk,
         ctrl_rst_i           => ctrl_rst,
         ctrl_key_valid_i     => ctrl_key_valid,
         ctrl_key_ready_o     => ctrl_key_ready,
         ctrl_key_data_i      => ctrl_key_data,
         ctrl_uart_rx_valid_i => ctrl_uart_rx_valid,
         ctrl_uart_rx_ready_o => ctrl_uart_rx_ready,
         ctrl_uart_rx_data_i  => ctrl_uart_rx_data,
         ctrl_uart_tx_valid_o => ctrl_uart_tx_valid,
         ctrl_uart_tx_ready_i => ctrl_uart_tx_ready,
         ctrl_uart_tx_data_o  => ctrl_uart_tx_data,
         ctrl_start_o         => ctrl_start,
         ctrl_active_i        => ctrl_active,
         ctrl_stat_total_i    => ctrl_stat_total,
         ctrl_stat_error_i    => ctrl_stat_error,
         ctrl_stat_err_addr_i => ctrl_stat_err_addr,
         ctrl_stat_err_exp_i  => ctrl_stat_err_exp,
         ctrl_stat_err_read_i => ctrl_stat_err_read,
         video_clk_i          => video_clk,
         video_rst_i          => video_rst,
         video_pos_x_i        => video_pos_x,
         video_pos_y_i        => video_pos_y,
         video_char_o         => video_char,
         video_colors_o       => video_colors
      ); -- controller_wrapper_inst


   ----------------------------------------------------------
   -- Instantiate core: Test generator and SDRAM controller.
   -- This runs entirely at the SDRAM clock (166 MHz).
   ----------------------------------------------------------

   core_wrapper_inst : entity work.core_wrapper
      generic map (
         G_SYS_ADDRESS_SIZE => C_SYS_ADDRESS_SIZE,
         G_ADDRESS_SIZE     => C_ADDRESS_SIZE,
         G_DATA_SIZE        => C_DATA_SIZE
      )
      port map (
         clk_i           => ctrl_clk,
         rst_i           => ctrl_rst,
         start_i         => ctrl_start,
         active_o        => ctrl_active,
         stat_total_o    => ctrl_stat_total,
         stat_error_o    => ctrl_stat_error,
         stat_err_addr_o => ctrl_stat_err_addr,
         stat_err_exp_o  => ctrl_stat_err_exp,
         stat_err_read_o => ctrl_stat_err_read,
         sdram_clk_o     => sdram_clk_o,
         sdram_cke_o     => sdram_cke_o,
         sdram_ras_n_o   => sdram_ras_n_o,
         sdram_cas_n_o   => sdram_cas_n_o,
         sdram_we_n_o    => sdram_we_n_o,
         sdram_cs_n_o    => sdram_cs_n_o,
         sdram_ba_o      => sdram_ba_o,
         sdram_a_o       => sdram_a_o,
         sdram_dqml_o    => sdram_dqml_o,
         sdram_dqmh_o    => sdram_dqmh_o,
         sdram_dq_in_i   => sdram_dq_in,
         sdram_dq_out_o  => sdram_dq_out,
         sdram_dq_oe_n_o => sdram_dq_oe_n
      ); -- core_wrapper_inst

   ----------------------------------------------------------
   -- Tri-state buffers for SDRAM
   ----------------------------------------------------------

   sdram_dq_gen : for i in sdram_dq_io'range generate
      sdram_dq_io(i) <= sdram_dq_out(i) when sdram_dq_oe_n(i) = '0' else
                        'Z';
   end generate sdram_dq_gen;

   sdram_dq_in <= sdram_dq_io;

end architecture synthesis;

