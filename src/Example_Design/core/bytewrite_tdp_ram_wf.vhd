-- True-Dual-Port BRAM with Byte-wide Write Enable
-- Write First mode
--
-- bytewrite_tdp_ram_wf.vhd
-- WRITE_FIRST ByteWide WriteEnable Block RAM Template

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity bytewrite_tdp_ram_wf is
   generic (
      G_DOA_REG    : boolean;
      G_DOB_REG    : boolean;
      G_SIZE       : integer;
      G_ADDR_WIDTH : integer;
      G_COL_WIDTH  : integer;
      G_NB_COL     : integer
   );
   port (
      clka_i  : in    std_logic;
      ena_i   : in    std_logic;
      wea_i   : in    std_logic_vector(G_NB_COL - 1 downto 0);
      addra_i : in    std_logic_vector(G_ADDR_WIDTH - 1 downto 0);
      dia_i   : in    std_logic_vector(G_NB_COL * G_COL_WIDTH - 1 downto 0);
      doa_o   : out   std_logic_vector(G_NB_COL * G_COL_WIDTH - 1 downto 0);

      clkb_i  : in    std_logic;
      enb_i   : in    std_logic;
      web_i   : in    std_logic_vector(G_NB_COL - 1 downto 0);
      addrb_i : in    std_logic_vector(G_ADDR_WIDTH - 1 downto 0);
      dib_i   : in    std_logic_vector(G_NB_COL * G_COL_WIDTH - 1 downto 0);
      dob_o   : out   std_logic_vector(G_NB_COL * G_COL_WIDTH - 1 downto 0)
   );
end entity bytewrite_tdp_ram_wf;

architecture synthesis of bytewrite_tdp_ram_wf is

   type   ram_type is array (0 to G_SIZE - 1) of std_logic_vector(G_NB_COL * G_COL_WIDTH - 1 downto 0);
   signal ram : ram_type := (others => (others => '1'));


   signal doa_noreg : std_logic_vector(G_NB_COL * G_COL_WIDTH - 1 downto 0);
   signal doa_reg   : std_logic_vector(G_NB_COL * G_COL_WIDTH - 1 downto 0);
   signal dob_noreg : std_logic_vector(G_NB_COL * G_COL_WIDTH - 1 downto 0);
   signal dob_reg   : std_logic_vector(G_NB_COL * G_COL_WIDTH - 1 downto 0);

begin

   ------- Port A -------
   port_a_proc : process (clka_i)
   begin
      if rising_edge(clka_i) then
         if ena_i = '1' then

            for i in 0 to G_NB_COL - 1 loop
               if wea_i(i) = '1' then
                  ram(to_integer(addra_i))((i + 1) * G_COL_WIDTH - 1 downto i * G_COL_WIDTH)
                                  <= dia_i((i + 1) * G_COL_WIDTH - 1 downto i * G_COL_WIDTH);
               end if;
            end loop;

            doa_noreg <= ram(to_integer(addra_i));
         end if;
         doa_reg <= doa_noreg;
      end if;
   end process port_a_proc;

   doa_o <= doa_reg when G_DOA_REG else
            doa_noreg;


   ------- Port B -------
   port_b_proc : process (clkb_i)
   begin
      if rising_edge(clkb_i) then
         if enb_i = '1' then

            for i in 0 to G_NB_COL - 1 loop
               if web_i(i) = '1' then
                  ram(to_integer(addrb_i))((i + 1) * G_COL_WIDTH - 1 downto i * G_COL_WIDTH)
                                  <= dib_i((i + 1) * G_COL_WIDTH - 1 downto i * G_COL_WIDTH);
               end if;
            end loop;

            dob_noreg <= ram(to_integer(addrb_i));
         end if;
         dob_reg <= dob_noreg;
      end if;
   end process port_b_proc;

   dob_o <= dob_reg when G_DOB_REG else
            dob_noreg;

end architecture synthesis;

