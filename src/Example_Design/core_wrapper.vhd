-- This is the wrapper for the test generator and SDRAM controller.
--
-- Created by Michael Jørgensen in 2024 (mjoergen.github.io/SDRAM).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity core_wrapper is
   generic (
      G_ADDRESS_SIZE     : integer;
      G_SYS_ADDRESS_SIZE : integer;
      G_DATA_SIZE        : integer
   );
   port (
      clk_i           : in    std_logic;                    -- Main controller clock
      rst_i           : in    std_logic;                    -- Synchronous reset, active high

      -- Control and Status for trafic generator
      start_i         : in    std_logic;
      active_o        : out   std_logic;

      -- Statistics output from verifier
      stat_total_o    : out   std_logic_vector(31 downto 0);
      stat_error_o    : out   std_logic_vector(31 downto 0);
      stat_err_addr_o : out   std_logic_vector(31 downto 0);
      stat_err_exp_o  : out   std_logic_vector(63 downto 0);
      stat_err_read_o : out   std_logic_vector(63 downto 0);

      -- SDRAM device interface
      sdram_clk_o     : out   std_logic;
      sdram_cke_o     : out   std_logic;
      sdram_ras_n_o   : out   std_logic;
      sdram_cas_n_o   : out   std_logic;
      sdram_we_n_o    : out   std_logic;
      sdram_cs_n_o    : out   std_logic;
      sdram_ba_o      : out   std_logic_vector(1 downto 0);
      sdram_a_o       : out   std_logic_vector(12 downto 0);
      sdram_dqml_o    : out   std_logic;
      sdram_dqmh_o    : out   std_logic;
      sdram_dq_in_i   : in    std_logic_vector(15 downto 0);
      sdram_dq_out_o  : out   std_logic_vector(15 downto 0);
      sdram_dq_oe_n_o : out   std_logic_vector(15 downto 0) -- Output enable for DQ
   );
end entity core_wrapper;

architecture synthesis of core_wrapper is

   -- Avalon Memory Map interface to SDRAM Controller
   signal avm_waitrequest   : std_logic;
   signal avm_write         : std_logic;
   signal avm_read          : std_logic;
   signal avm_address       : std_logic_vector(31 downto 0) := (others => '0');
   signal avm_writedata     : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal avm_byteenable    : std_logic_vector(G_DATA_SIZE / 8 - 1 downto 0);
   signal avm_burstcount    : std_logic_vector(7 downto 0);
   signal avm_readdata      : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal avm_readdatavalid : std_logic;

   signal dec_waitrequest   : std_logic;
   signal dec_write         : std_logic;
   signal dec_read          : std_logic;
   signal dec_address       : std_logic_vector(31 downto 0) := (others => '0');
   signal dec_writedata     : std_logic_vector(15 downto 0);
   signal dec_byteenable    : std_logic_vector(1 downto 0);
   signal dec_burstcount    : std_logic_vector(7 downto 0);
   signal dec_readdata      : std_logic_vector(15 downto 0);
   signal dec_readdatavalid : std_logic;

begin

   --------------------------------------------------------
   -- Instantiate trafic generator
   --------------------------------------------------------

   traffic_gen_inst : entity work.trafic_gen
      generic map (
         G_DATA_SIZE    => G_DATA_SIZE,
         G_ADDRESS_SIZE => G_SYS_ADDRESS_SIZE
      )
      port map (
         clk_i               => clk_i,
         rst_i               => rst_i,
         start_i             => start_i,
         wait_o              => active_o,
         stat_total_o        => stat_total_o,
         stat_error_o        => stat_error_o,
         stat_err_addr_o     => stat_err_addr_o(G_SYS_ADDRESS_SIZE - 1 downto 0),
         stat_err_exp_o      => stat_err_exp_o(G_DATA_SIZE - 1 downto 0),
         stat_err_read_o     => stat_err_read_o(G_DATA_SIZE - 1 downto 0),
         avm_write_o         => avm_write,
         avm_read_o          => avm_read,
         avm_address_o       => avm_address(G_SYS_ADDRESS_SIZE - 1 downto 0),
         avm_writedata_o     => avm_writedata,
         avm_byteenable_o    => avm_byteenable,
         avm_burstcount_o    => avm_burstcount,
         avm_readdata_i      => avm_readdata,
         avm_readdatavalid_i => avm_readdatavalid,
         avm_waitrequest_i   => avm_waitrequest
      ); -- traffic_gen_inst

   stat_err_addr_o(31 downto G_SYS_ADDRESS_SIZE) <= (others => '0');
   stat_err_exp_o(63 downto G_DATA_SIZE)         <= (others => '0');
   stat_err_read_o(63 downto G_DATA_SIZE)        <= (others => '0');


   decrease_gen : if G_DATA_SIZE > 16 generate

      avm_decrease_inst : entity work.avm_decrease
         generic map (
            G_SLAVE_ADDRESS_SIZE  => G_ADDRESS_SIZE,
            G_SLAVE_DATA_SIZE     => G_DATA_SIZE,
            G_MASTER_ADDRESS_SIZE => 25,
            G_MASTER_DATA_SIZE    => 16
         )
         port map (
            clk_i                 => clk_i,
            rst_i                 => rst_i,
            s_avm_waitrequest_o   => avm_waitrequest,
            s_avm_write_i         => avm_write,
            s_avm_read_i          => avm_read,
            s_avm_address_i       => avm_address(G_ADDRESS_SIZE - 1 downto 0),
            s_avm_writedata_i     => avm_writedata,
            s_avm_byteenable_i    => avm_byteenable,
            s_avm_burstcount_i    => avm_burstcount,
            s_avm_readdata_o      => avm_readdata,
            s_avm_readdatavalid_o => avm_readdatavalid,
            m_avm_waitrequest_i   => dec_waitrequest,
            m_avm_write_o         => dec_write,
            m_avm_read_o          => dec_read,
            m_avm_address_o       => dec_address(24 downto 0),
            m_avm_writedata_o     => dec_writedata,
            m_avm_byteenable_o    => dec_byteenable,
            m_avm_burstcount_o    => dec_burstcount,
            m_avm_readdata_i      => dec_readdata,
            m_avm_readdatavalid_i => dec_readdatavalid
         ); -- avm_decrease_inst

   else generate
      avm_waitrequest   <= dec_waitrequest;
      dec_write         <= avm_write;
      dec_read          <= avm_read;
      dec_address       <= avm_address;
      dec_writedata     <= avm_writedata;
      dec_byteenable    <= avm_byteenable;
      dec_burstcount    <= avm_burstcount;
      avm_readdata      <= dec_readdata;
      avm_readdatavalid <= dec_readdatavalid;
   end generate decrease_gen;


   --------------------------------------------------------
   -- Instantiate SDRAM controller
   --------------------------------------------------------

   sdram_inst : entity work.sdram
      port map (
         clk_i               => clk_i,
         rst_i               => rst_i,
         avm_write_i         => dec_write,
         avm_read_i          => dec_read,
         -- Make sure all 25 address bits of the SDRAM is used, rather than the 19 address
         -- bits offered by the Block RAM. Therefore we shift the address 25-19 = 6 bits
         -- left.
         avm_address_i       => dec_address xor
                               (dec_address(25 downto 0) & "000000"),
         avm_writedata_i     => dec_writedata,
         avm_byteenable_i    => dec_byteenable,
         avm_burstcount_i    => dec_burstcount,
         avm_readdata_o      => dec_readdata,
         avm_readdatavalid_o => dec_readdatavalid,
         avm_waitrequest_o   => dec_waitrequest,
         sdram_clk_o         => sdram_clk_o,
         sdram_cke_o         => sdram_cke_o,
         sdram_ras_n_o       => sdram_ras_n_o,
         sdram_cas_n_o       => sdram_cas_n_o,
         sdram_we_n_o        => sdram_we_n_o,
         sdram_cs_n_o        => sdram_cs_n_o,
         sdram_ba_o          => sdram_ba_o,
         sdram_a_o           => sdram_a_o,
         sdram_dqml_o        => sdram_dqml_o,
         sdram_dqmh_o        => sdram_dqmh_o,
         sdram_dq_in_i       => sdram_dq_in_i,
         sdram_dq_out_o      => sdram_dq_out_o,
         sdram_dq_oe_n_o     => sdram_dq_oe_n_o
      ); -- sdram_inst

end architecture synthesis;

