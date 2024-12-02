library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
    port (
        operand_a : in  std_logic_vector(7 downto 0); -- Operando A
        operand_b : in  std_logic_vector(7 downto 0); -- Operando B
        alu_op    : in  std_logic_vector(3 downto 0); -- Código da operação
        result    : buffer std_logic_vector(7 downto 0); -- Resultado da operação
        zero_flag : buffer std_logic                    -- Flag de zero
    );
end alu;

architecture behavior of alu is
begin
    process(operand_a, operand_b, alu_op)
        variable temp_result : signed(7 downto 0);
    begin
        case alu_op is
            when "1000" => -- ADD
					 temp_result := signed(operand_a) + signed(operand_b);
                result <= std_logic_vector(temp_result);
            
            when "1001" => -- SUB
                temp_result := signed(operand_a) - signed(operand_b);
                result <= std_logic_vector(temp_result);
            
            when "1010" => -- AND
					 result <= operand_a and operand_b;
					 
            when "1011" => -- OR
					 result <= operand_a or operand_b;
            
            when "1100" => -- NOT
                result <= not operand_a;
            
            when others =>
                result <= (others => '0'); -- Operação inválida
        end case;
        
        -- Define a flag zero
		  if result = "0" then
			   zero_flag <= '1';
		  else
			   zero_flag <= '0';
		  end if;
    end process;
end behavior;
