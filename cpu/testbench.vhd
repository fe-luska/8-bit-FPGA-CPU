library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testbench is
end entity testbench;

architecture sim of testbench is

   -- Component Declaration
   component cpu
      port (
         clk    : in  std_logic;
         reset  : in  std_logic
      );
   end component;

   -- Sinais de teste
   signal clk   : std_logic := '0';
   signal reset : std_logic := '0';

   -- Constantes para clock
   constant clk_period : time := 10 ns;

begin

   -- Instância da CPU
   uut: cpu
      port map (
         clk   => clk,
         reset => reset
      );

   -- Geração do clock
   clk_process: process
   begin
      while true loop
         clk <= '1';
         wait for clk_period / 2;
         clk <= '0';
         wait for clk_period / 2;
      end loop;
   end process;

   -- Estímulos de entrada
   stim_proc: process
   begin
      -- Reset inicial
      reset <= '1';
      wait for 20 ns;
      reset <= '0';

      -- Aguarda para observar comportamento
      wait for 100 ns;

      -- Finaliza a simulação
      wait;
   end process;

end architecture sim;
