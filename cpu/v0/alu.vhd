library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
    port (
        operand_a : in  std_logic_vector(7 downto 0); -- Operando A
        operand_b : in  std_logic_vector(7 downto 0); -- Operando B
        alu_op    : in  std_logic_vector(3 downto 0); -- Código da operação
        result    : buffer std_logic_vector(7 downto 0); -- Resultado da operação
        zero_flag : out std_logic                    -- Flag de zero
    );
end alu;

architecture behavior of alu is
begin
    process(operand_a, operand_b, alu_op)
        variable temp_result : signed(7 downto 0);
    begin
        case alu_op is
            when "0000" => -- AND
					 result <= operand_a and operand_b;
            
            when "0001" => -- OR
                result <= operand_a or operand_b;
            
            when "0010" => -- ADD
                temp_result := signed(operand_a) + signed(operand_b);
                result <= std_logic_vector(temp_result);
            
            when "0011" => -- SUB
					 temp_result := signed(operand_a) - signed(operand_b);
                result <= std_logic_vector(temp_result);
            
            when "0100" => -- XOR
                result <= operand_a xor operand_b;
            
            when "0101" => -- NOT
                result <= not operand_a;
            
            when "0110" => -- SHIFT LEFT
                result <= std_logic_vector(shift_left(unsigned(operand_a), 1));
            
            when "0111" => -- SHIFT RIGHT
                result <= std_logic_vector(shift_right(unsigned(operand_a), 1));
            
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
