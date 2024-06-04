-- This module is a RAM test.
--
-- It generates a random sequence of WRITE and READ operations.
-- Burstcount is always 1, but byteenable varies randomly as well.
-- The module keeps a shadow copy of the memory, and uses that
-- to verify the values received during READ operations.
--
-- Created by Michael Jørgensen in 2023

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;
   use ieee.numeric_std_unsigned.all;

entity avm_verifier is
   generic (
      G_ADDRESS_SIZE : integer; -- Number of bits
      G_DATA_SIZE    : integer  -- Number of bits
   );
   port (
      clk_i               : in    std_logic;
      rst_i               : in    std_logic;
      avm_write_i         : in    std_logic;
      avm_read_i          : in    std_logic;
      avm_address_i       : in    std_logic_vector(G_ADDRESS_SIZE - 1 downto 0);
      avm_writedata_i     : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      avm_byteenable_i    : in    std_logic_vector(G_DATA_SIZE / 8 - 1 downto 0);
      avm_burstcount_i    : in    std_logic_vector(7 downto 0);
      avm_readdata_i      : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      avm_readdatavalid_i : in    std_logic;
      avm_waitrequest_i   : in    std_logic;
      -- Statistics output
      stat_total_o        : out   std_logic_vector(31 downto 0);
      stat_error_o        : out   std_logic_vector(31 downto 0);
      stat_err_addr_o     : out   std_logic_vector(G_ADDRESS_SIZE - 1 downto 0);
      stat_err_exp_o      : out   std_logic_vector(G_DATA_SIZE - 1 downto 0);
      stat_err_read_o     : out   std_logic_vector(G_DATA_SIZE - 1 downto 0)
   );
end entity avm_verifier;

architecture synthesis of avm_verifier is

   signal avm_address   : std_logic_vector(G_ADDRESS_SIZE - 1 downto 0);
   signal avm_writedata : std_logic_vector(G_DATA_SIZE - 1 downto 0);
   signal wr_en         : std_logic_vector(G_DATA_SIZE / 8 - 1 downto 0);
   signal mem_data      : std_logic_vector(G_DATA_SIZE - 1 downto 0);

   -- Debug counters
   signal req_count  : natural range 0 to 1023;
   signal read_count : natural range 0 to 1023;
   signal reading    : std_logic;

begin

   -- Debug counters
   wait_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if avm_waitrequest_i = '1' then
            if avm_write_i = '1' or avm_read_i = '1' then
               if req_count < 1023 then
                  req_count <= req_count + 1;
               end if;
            end if;
         else
            req_count <= 0;
         end if;
      end if;
   end process wait_proc;

   -- Debug counters
   read_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if avm_waitrequest_i = '0' and avm_read_i = '1' then
            read_count <= 0;
            reading    <= '1';
         end if;
         if reading = '1' then
            read_count <= read_count + 1;
         end if;
         if avm_readdatavalid_i = '1' then
            reading <= '0';
         end if;
         if rst_i = '1' then
            reading <= '0';
         end if;
      end if;
   end process read_proc;

   -- Register inputs for better timing
   reg_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         avm_address   <= avm_address_i;
         avm_writedata <= avm_writedata_i;
         wr_en         <= (others => '0');
         if avm_write_i = '1' and avm_waitrequest_i = '0' then
            wr_en <= avm_byteenable_i;
         end if;
      end if;
   end process reg_proc;

   bytewrite_tdp_ram_wf_inst : entity work.bytewrite_tdp_ram_wf
      generic map (
         G_DOA_REG    => true,
         G_DOB_REG    => false,
         G_SIZE       => 2 ** G_ADDRESS_SIZE,
         G_ADDR_WIDTH => G_ADDRESS_SIZE,
         G_COL_WIDTH  => 8,
         G_NB_COL     => G_DATA_SIZE / 8
      )
      port map (
         clka_i  => clk_i,
         ena_i   => '1',
         wea_i   => wr_en,
         addra_i => avm_address,
         dia_i   => avm_writedata,
         doa_o   => mem_data,
         clkb_i  => '0',
         enb_i   => '0',
         web_i   => (others => '0'),
         addrb_i => (others => '0'),
         dib_i   => (others => '0'),
         dob_o   => open
      ); -- bytewrite_tdp_ram_wf_inst

   verifier_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if avm_waitrequest_i = '0' and (avm_write_i = '1' or avm_read_i = '1') then
            stat_total_o <= stat_total_o + 1;
         end if;
         if avm_readdatavalid_i = '1' and avm_readdata_i /= mem_data then
            stat_err_addr_o <= avm_address_i;
            stat_err_exp_o  <= mem_data;
            stat_err_read_o <= avm_readdata_i;
            assert false
               report "ERROR at Address " & to_hstring(avm_address_i) &
                      ". Expected " & to_hstring(mem_data) &
                      ", read " & to_hstring(avm_readdata_i)
               severity failure;

            stat_error_o    <= stat_error_o + 1;
         end if;
         if rst_i = '1' then
            stat_total_o    <= (others => '0');
            stat_error_o    <= (others => '0');
            stat_err_addr_o <= (others => '0');
            stat_err_exp_o  <= (others => '0');
            stat_err_read_o <= (others => '0');
         end if;
      end if;
   end process verifier_proc;

end architecture synthesis;

