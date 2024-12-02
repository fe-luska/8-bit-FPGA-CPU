library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu is
	port (
		clk    : in  std_logic;
		reset  : in  std_logic
	);
end cpu;

architecture behavior of cpu is

	-- Registradores
   signal PC : std_logic_vector(7 downto 0) := (others => '0'); -- Program Counter
   signal IR : std_logic_vector(7 downto 0) := (others => '0'); -- Instruction Register
   signal R  : std_logic_vector(7 downto 0) := (others => '0'); -- ALU resultado
   signal A  : std_logic_vector(7 downto 0) := (others => '0'); -- Registrador A
   signal B  : std_logic_vector(7 downto 0) := (others => '0'); -- Registrador B

   -- Barramentos
   signal address_bus  : std_logic_vector(7 downto 0);
   signal data_bus     : std_logic_vector(7 downto 0);
   signal control_bus  : std_logic_vector(5 downto 0);

   -- Sinais de controle
   signal read, write, mem_enable : std_logic;
   signal alu_enable : std_logic;

	-- memoria
   signal mem_data_in, mem_data_out : std_logic_vector(7 downto 0);
   signal mem_wren : std_logic;
	
	-- ALU
	signal zero_flag  : std_logic;
	signal wait_alu   : std_logic;
	signal alu_result : std_logic_vector(7 downto 0);
	signal op_a 		: std_logic_vector(7 downto 0);
	signal op_b 		: std_logic_vector(7 downto 0);
	
	
	type state_cpu_type is (fetch, decode, execute, wait_read, fetch_wait);
   type state_alu_type is (fetch_operands, ready);
	
	-- pra debug
	signal state_monitor : state_cpu_type := fetch;
	signal state_alu_monitor : state_alu_type := fetch_operands;

begin

   -- Instância da memória
   memory_inst: entity work.memoria
		port map (
			address => address_bus,
			clock   => clk,
			data    => mem_data_in, -- Para gravação na memória
			wren    => mem_wren,    -- Habilita escrita
			q       => mem_data_out -- Para leitura da memória
		);
		
	-- ALU	
	alu_inst: entity work.alu
		port map (
			operand_a => op_a,
			operand_b => op_b,
			alu_op    => IR(7 downto 4), -- Operação vem do opcode da instrução
			result    => alu_result,
			zero_flag => zero_flag
		);


process(clk)
   
	
	variable alu_state : state_alu_type := fetch_operands;
	variable state : state_cpu_type := fetch;

begin
   if rising_edge(clk) then
		if reset = '1' then
         PC <= (others => '0');
         IR <= (others => '0');
         A <= (others => '0');
         B <= (others => '0');
         state := fetch;
      else
         case state is
            when fetch =>
               address_bus <= PC;       -- Carrega o endereço do PC
               mem_wren <= '0';         -- Desativa escrita
               read <= '1';             -- Ativa leitura
               state := fetch_wait;         -- Vai para o próximo estado
					alu_enable <= '0'; -- inicizalizar
				
            when fetch_wait =>
					read <= '0';
					state := decode;
				
				when decode =>
               IR <= mem_data_out;      -- Carrega a instrução
               PC <= std_logic_vector(resize(unsigned(PC) + 1, 8)); -- Incrementa PC
               state := execute;        -- Vai para o estado de execução
            
            when execute =>
               case IR(7 downto 4) is
                  when "0001" => -- LOAD
                     
							if read = '0' then
								address_bus <= PC; -- Coloca o endereço no barramento
								read <= '1';       -- Ativa leitura
								state := wait_read; -- Vai para estado de espera
								PC <= std_logic_vector(resize(unsigned(PC) + 1, 8)); -- Incrementa PC
							
							else 
								case IR(3 downto 0) is
									when "0000" => -- Armazena em A
										A <= mem_data_out; -- Lê valor da memória
									when "0001" => -- Armazena em B
										B <= mem_data_out; -- Lê valor da memória
									when others =>
										null;              -- Operação inválida
								end case;
								state := fetch;          -- Retorna ao estado de busca
								read <= '0';
							end if;
               
						when "0010" => -- ADD
							
							if read = '0' then -- ciclo 1 fazer a(s) leitura(s)
								
								case IR(3 downto 0) is
									
									when "0000" => -- A e próxima palavra
											
										-- carrega a proxima palavra em B
										address_bus <= PC;
										read <= '1';
										state := wait_read;
										PC <= std_logic_vector(resize(unsigned(PC) + 1, 8));
										
									when "0001" => -- B e próxima palavra
										
										address_bus <= PC;
										read <= '1';
										state := wait_read;
										PC <= std_logic_vector(resize(unsigned(PC) + 1, 8));

									when "0011" => -- A e B
										read <= '1';
										state := wait_read;
										
									when others =>
										null; -- Operação inválida
								end case;
								
							else -- ja realizou a leitura (read = '1')
							
								if alu_enable = '0' then -- coloca os operandos
								
									case IR(3 downto 0) is
									when "0000" => -- A e próxima palavra
										
									op_a <= mem_data_out;
									op_b <= B;
									alu_enable <= '1';
										
									when "0001" => -- B e próxima palavra
											
										op_a <= A;
										op_b <= mem_data_out;
										alu_enable <= '1';

									when "0011" => -- A e B
									
										op_a <= A;
										op_b <= B;
										alu_enable <= '1';
										
									when others => -- erro;
										report "opcode invalido";
									end case;
									
								else -- ALU já fez a operação, extrair o resultado
								
									R <= alu_result;
									state := fetch;
									alu_enable <= '0';
									read <= '0';
								
								end if; -- end if alu_enable
								
							end if; -- if read
							
						-- FIM DO ADD
						when "0011" => -- SUB
						
							case alu_state is
								
								when fetch_operands => -- buscar operandos
									case IR(3 downto 0) is
									
										when "0000" => -- A e próxima palavra
												
											-- carrega a proxima palavra em B
											address_bus <= PC;
											read <= '1';
											state := wait_read;
											PC <= std_logic_vector(resize(unsigned(PC) + 1, 8));
										
										when "0001" => -- B e próxima palavra
										
											address_bus <= PC;
											read <= '1';
											state := wait_read;
											PC <= std_logic_vector(resize(unsigned(PC) + 1, 8));

										when "0011" => -- A e B
											R <= alu_result;
											state := wait_read;
										
										when others =>
											null; -- Operação inválida
									end case;
								
								when ready =>
									R <= alu_result;
									state := fetch;
							
							end case;
							
							
						when others =>
                     state := fetch;    -- Para outras instruções, retorna ao fetch
						
					end case;
            
            when wait_read =>
               --read <= '0';             -- Desativa leitura
               state := execute;         -- Aguarda um ciclo para leitura estabilizar
			
			end case; -- case state
      end if;
		
		state_monitor <= state;
      state_alu_monitor <= alu_state;
   end if;
end process;

end behavior;
