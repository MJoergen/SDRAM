library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity ram is
   generic (
      G_ADDR_SIZE : natural;
      G_DATA_SIZE : natural
   );
   port (
      clk_i     : in    std_logic;
      addr_i    : in    std_logic_vector(G_ADDR_SIZE - 1 downto 0);
      wr_en_i   : in    std_logic_vector(G_DATA_SIZE / 8 - 1 downto 0);
      wr_data_i : in    std_logic_vector(G_DATA_SIZE - 1 downto 0);
      rd_en_i   : in    std_logic;
      rd_data_o : out   std_logic_vector(G_DATA_SIZE - 1 downto 0)
   );
end entity ram;

architecture simulation of ram is

   type ram_type is array (natural range <>) of std_logic_vector(G_DATA_SIZE - 1 downto 0);

begin

   ram_proc : process (clk_i)
      variable ram_v : ram_type(0 to 2 ** G_ADDR_SIZE - 1) := (others => (others => '1'));
   begin
      if rising_edge(clk_i) then
         if rd_en_i = '1' then
            rd_data_o <= ram_v(to_integer(addr_i));
         else
            rd_data_o <= (others => 'Z');
         end if;

         for i in 0 to G_DATA_SIZE / 8 - 1 loop
            if wr_en_i(i) = '1' then
               ram_v(to_integer(addr_i))(8 * i + 7 downto 8 * i) := wr_data_i(8 * i + 7 downto 8 * i);
            end if;
         end loop;

      end if;
   end process ram_proc;

end architecture simulation;

