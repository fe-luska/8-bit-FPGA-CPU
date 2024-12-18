library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity io_module is
    Port (
        SW : in  STD_LOGIC_VECTOR(7 downto 0);  -- Entradas das chaves (SW0 a SW7)
		  BTN : in  STD_LOGIC;  -- Entrada do botão (pressionado ou não)
        LED : out  STD_LOGIC_VECTOR(7 downto 0); -- Saídas para os LEDs
        data_out : out  STD_LOGIC_VECTOR(7 downto 0); -- Saída para o módulo principal
        data_in : in  STD_LOGIC_VECTOR(7 downto 0); -- Entrada do módulo principal
		  button_status : out  STD_LOGIC -- Saída para o módulo principal indicando o estado do botão
    );
end io_module;

architecture Behavioral of io_module is
begin
    -- Enviar as entradas de SW para data_out
    data_out <= SW;

    -- Mapeamento dos bits de data_in para os LEDs
    LED <= data_in;
	 
	 -- Enviar o estado do botão para o módulo principal
    button_status <= BTN;
	 
end Behavioral;
