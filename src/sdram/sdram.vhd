-- This is the wrapper file for the complete SDRAM controller.

-- This module requires one clock:
-- clk_i          : 166 MHz : This is the main clock used for the Avalon MM
--                            interface as well as controlling the SDRAM
--                            device.
--
-- Created by Michael Jørgensen in 2024 (mjoergen.github.io/SDRAM).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity sdram is
   port (
      clk_i               : in    std_logic;                    -- Main clock
      rst_i               : in    std_logic;                    -- Synchronous reset

      -- Avalon Memory Map
      avm_write_i         : in    std_logic;
      avm_read_i          : in    std_logic;
      avm_address_i       : in    std_logic_vector(31 downto 0);
      avm_writedata_i     : in    std_logic_vector(15 downto 0);
      avm_byteenable_i    : in    std_logic_vector( 1 downto 0);
      avm_burstcount_i    : in    std_logic_vector( 7 downto 0);
      avm_readdata_o      : out   std_logic_vector(15 downto 0);
      avm_readdatavalid_o : out   std_logic;
      avm_waitrequest_o   : out   std_logic;

      -- SDRAM device interface
      -- SDRAM - 32M x 16 bit, 3.3V VCC. U44 = IS42S16320F-6BL
      sdram_clk_o         : out   std_logic;
      sdram_cke_o         : out   std_logic;
      sdram_ras_n_o       : out   std_logic;
      sdram_cas_n_o       : out   std_logic;
      sdram_we_n_o        : out   std_logic;
      sdram_cs_n_o        : out   std_logic;
      sdram_ba_o          : out   std_logic_vector(1 downto 0);
      sdram_a_o           : out   std_logic_vector(12 downto 0);
      sdram_dqml_o        : out   std_logic;
      sdram_dqmh_o        : out   std_logic;
      sdram_dq_in_i       : in    std_logic_vector(15 downto 0);
      sdram_dq_out_o      : out   std_logic_vector(15 downto 0);
      sdram_dq_oe_n_o     : out   std_logic_vector(15 downto 0) -- Output enable for DQ
   );
end entity sdram;

architecture synthesis of sdram is

   type   state_type is (IDLE_ST, BUSY_ST);
   signal state : state_type := IDLE_ST;

   signal avm_address    : std_logic_vector(31 downto 0);
   signal avm_writedata  : std_logic_vector(15 downto 0);
   signal avm_byteenable : std_logic_vector( 1 downto 0);
   signal avm_burstcount : std_logic_vector( 7 downto 0);

begin

   -- This is just a dummy controller for the time being.
   -- All writes are ignored, and all reads return in the following
   -- clock cycle. Assumes burstcount = 1.
   avm_waitrequest_o <= '0' when state = IDLE_ST else
                        '1';

   avm_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         avm_readdatavalid_o <= '0';

         case state is

            when IDLE_ST =>
               if avm_read_i = '1' then
                  assert avm_burstcount_i = X"01"
                     report "Dummy controller requires burstcount = 1";
                  avm_address    <= avm_address_i;
                  avm_burstcount <= avm_burstcount_i;
                  state          <= BUSY_ST;
               end if;

            when BUSY_ST =>
               avm_readdata_o      <= avm_address(31 downto 16) xor avm_address(15 downto 0);
               avm_readdatavalid_o <= '1';
               state               <= IDLE_ST;

         end case;

         if rst_i = '1' then
            avm_readdata_o      <= (others => '0');
            avm_readdatavalid_o <= '0';
            state               <= IDLE_ST;
         end if;
      end if;
   end process avm_proc;

   sdram_clk_o       <= clk_i;
   sdram_cke_o       <= '0';
   sdram_ras_n_o     <= '0';
   sdram_cas_n_o     <= '0';
   sdram_we_n_o      <= '0';
   sdram_cs_n_o      <= '0';
   sdram_ba_o        <= (others => '0');
   sdram_a_o         <= (others => '0');
   sdram_dqml_o      <= '0';
   sdram_dqmh_o      <= '0';
   sdram_dq_out_o    <= (others => '0');
   sdram_dq_oe_n_o   <= (others => '1');

end architecture synthesis;

