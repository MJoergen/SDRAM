library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity random is
   port (
      clk_i    : in    std_logic;
      rst_i    : in    std_logic;
      update_i : in    std_logic;
      output_o : out   std_logic_vector(127 downto 0)
   );
end entity random;

architecture synthesis of random is

   pure function reverse (
      arg : std_logic_vector
   ) return std_logic_vector is
      variable res_v : std_logic_vector(arg'range);
   begin
      --
      for i in arg'low to arg'high loop
         res_v(arg'high - i) := arg(i);
      end loop;

      return res_v;
   end function reverse;

   pure function scramble (
      arg : std_logic_vector
   ) return std_logic_vector is
      variable res_v : std_logic_vector(arg'range);
      variable index_slv : std_logic_vector(6 downto 0);
      variable index_slv_reverse : std_logic_vector(6 downto 0);
   begin
      for i in arg'low to arg'high loop
         index_slv := to_stdlogicvector(i, 7);
         index_slv_reverse := reverse(index_slv);
         res_v(to_integer(index_slv_reverse)) := arg(i);
      end loop;

      return res_v;
   end function scramble;

   signal random_s : std_logic_vector(127 downto 0);

begin

   lfsr_msb_inst : entity work.lfsr
      generic map (
         G_WIDTH => 64,
         G_TAPS  => X"80000000000019E2" -- See https://users.ece.cmu.edu/~koopman/lfsr/64.txt
      )
      port map (
         clk_i      => clk_i,
         rst_i      => rst_i,
         update_i   => update_i,
         load_i     => '0',
         load_val_i => (others => '1'),
         output_o   => random_s(127 downto 64)
      ); -- lfsr_msb_inst

   lfsr_lsb_inst : entity work.lfsr
      generic map (
         G_WIDTH => 64,
         G_TAPS  => X"80000000000019A9" -- See https://users.ece.cmu.edu/~koopman/lfsr/64.txt
      )
      port map (
         clk_i      => clk_i,
         rst_i      => rst_i,
         update_i   => update_i,
         load_i     => '0',
         load_val_i => (others => '1'),
         output_o   => random_s(63 downto 0)
      ); -- lfsr_lsb_inst

   output_o <= random_s + scramble(random_s);

end architecture synthesis;

