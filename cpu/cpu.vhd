library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu is
	port (
		clk           : in  std_logic;
		reset         : in  std_logic
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
   signal control_bus  : std_logic_vector(6 downto 0);
	
	-- Control_bus:
	--	1: read 				(read)
	-- 2: write 			(wren)
	-- 3: memory enable  (mem_enable)
	-- 4: input_enable   (io_input_enable)
	-- 5: output_enable  (io_output_enable)
	-- 6: clk				(clk)
	-- 7: reset			   (reset)

   -- Sinais de controle
   signal read, mem_enable : std_logic;
   signal alu_enable : std_logic;
	signal sign_flag : std_logic;
	signal equal_flag: std_logic;

	-- memoria
   signal mem_data_in : std_logic_vector(7 downto 0);
   signal mem_wren : std_logic;
	signal memory_enable : STD_LOGIC;
	
	-- ALU
	signal zero_flag  : std_logic;
	signal carry_flag : std_logic := '0';
	signal wait_alu   : std_logic;
	signal alu_result : std_logic_vector(7 downto 0);
	signal op_a 		: std_logic_vector(7 downto 0);
	signal op_b 		: std_logic_vector(7 downto 0);
	
	-- estados da CPU e instruções
	type state_cpu_type is (fetch, decode, decode_wait, execute, wait_read, fetch_wait);
   type state_alu_type is (fetch_operand_A, fetch_operand_B, ready);
	type cmp_state_type is (fetch_operand_A, fetch_operand_B, ready);
	
	-- sinais para IO
	signal io_data_out : STD_LOGIC_VECTOR(7 downto 0);
   signal io_data_in : STD_LOGIC_VECTOR(7 downto 0);
   signal io_button_status : STD_LOGIC;
	signal io_SW :  STD_LOGIC_VECTOR(7 downto 0);
	signal io_BTN : STD_LOGIC;
	signal io_LED : STD_LOGIC_VECTOR(7 downto 0);
	signal io_input_enable  : STD_LOGIC;
	signal io_output_enable : STD_LOGIC;
	
	-- pra debug
	signal state_monitor : state_cpu_type := fetch;
	signal state_alu_monitor : state_alu_type := fetch_operand_A;

begin

   -- Instância da memória
   memory_inst: entity work.memoria
		port map (
			address => address_bus,
			clock   => clk,
			data    => mem_data_in, -- Para gravação na memória
			wren    => mem_wren,    -- Habilita escrita
			q       => data_bus -- Para leitura da memória
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
		
	-- IO
	io_inst: entity work.io_module
       Port map (
          SW => io_SW,                 -- Entradas das chaves
          BTN => io_BTN,               -- Botão de entrada
          LED => io_LED,               -- Saídas dos LEDs
          data_out => io_data_out,  -- Sinal interno para leitura da saida de dados
			 data_in => io_data_in,    -- Sinal interno para entrada de dados
          button_status => io_button_status -- Sinal interno para o estado do botão
       );

process(clk)
   
	
	variable alu_state : state_alu_type := fetch_operand_A;
	variable state : state_cpu_type := fetch;
	variable cmp_state : cmp_state_type := fetch_operand_A;
	variable botao_despressionado : STD_LOGIC;
	
begin
   if rising_edge(clk) then
		if reset = '1' then
         PC <= (others => '0');
         IR <= (others => '0');
         A <= (others => '0');
         B <= (others => '0');
         
			mem_enable <= '0';
			mem_wren <= '0';
			read <= '0';
			alu_enable <= '0';
			botao_despressionado := '0';
			io_output_enable <= '0';
			io_input_enable <= '0';
			
			
			state := fetch;
      else
         case state is
            when fetch =>
               address_bus <= PC;       -- Carrega o endereço do PC
               
					mem_enable <= '1';
					mem_wren <= '0';         -- Desativa escrita
               read <= '1';             -- Ativa leitura
               
					state := fetch_wait;         -- Vai para o próximo estado
					
					-- inicizalizar
					alu_enable <= '0';
					botao_despressionado := '0';
					mem_enable <= '0';
					io_output_enable <= '0';
					io_input_enable <= '0';
				
            when fetch_wait =>
					state := decode;
				
				when decode =>
               IR <= data_bus;      -- Carrega a instrução
               PC <= std_logic_vector(resize(unsigned(PC) + 1, 8)); -- Incrementa PC
					address_bus <= std_logic_vector(resize(unsigned(PC) + 1, 8)); -- recebe o valor do PC incrementado
               state := decode_wait;        -- Vai para o estado de execução
					mem_enable <= '0';
					read <= '0';
				
				when decode_wait =>
					state := execute;
					-- isso é necessário para que no proximo ciclo o conteudo do endereço colocado ja esteja disponivel
				
            when execute =>
               case IR(7 downto 4) is
                  when "0001" => -- LOAD
                     
							if read = '0' then -- não fez a leitura
							
								address_bus <= data_bus; -- Coloca o endereço no barramento
								mem_enable <= '1';
								read <= '1';       -- Ativa leitura
								state := wait_read; -- Vai para estado de espera
								PC <= std_logic_vector(resize(unsigned(PC) + 1, 8)); -- Incrementa PC
							
							else -- já fez a leitura
								case IR(3 downto 0) is
									when "0000" => -- Armazena em A
										A <= data_bus; -- Lê valor da memória
									when "0001" => -- Armazena em B
										B <= data_bus; -- Lê valor da memória
									when "0010" => -- armazena em R
										R <= data_bus;
									when others =>
										null;              -- Operação inválida
								end case;
								state := fetch;          -- Retorna ao estado de busca
								mem_enable <= '0';
								read <= '0';
							end if;
						
						when "0010" => -- CMP
							
							case IR(3 downto 2) is
								when "00" => -- primeiro operando: A
									
									case IR(1 downto 0) is
										when "00" => -- CMP A, A
											report "CMP A, A nao permitido";
										
										when "01" => -- CMP A, B
										
											if A = B then
												equal_flag <= '1';
											else
												equal_flag <= '0';
											end if;

											if signed(A) < signed(B) then
												sign_flag <= '1'; -- A é menor que B
											else
												sign_flag <= '0'; -- A é maior ou igual a B
											end if;
										
										when "10" => -- CMP A, R
										
											if A = R then
												equal_flag <= '1';
											else
												equal_flag <= '0';
											end if;

											if signed(A) < signed(R) then
												sign_flag <= '1';
											else
												sign_flag <= '0';
											end if;
										
										when "11" => -- CMP A, op
										
											if A = data_bus then
												equal_flag <= '1';
											else
												equal_flag <= '0';
											end if;

											if signed(A) < signed(data_bus) then
												sign_flag <= '1';
											else
												sign_flag <= '0';
											end if;
											
											PC <= std_logic_vector(resize(unsigned(PC) + 1, 8)); -- Incrementa PC
										
										when others =>
											report "CMP: erro nos parametros";
									end case;
								
								
								when "01" => -- primeiro operando: B
									
									case IR(1 downto 0) is
										when "00" => -- CMP B, A
										
											if B = A then
												equal_flag <= '1';
											else
												equal_flag <= '0';
											end if;

											if signed(B) < signed(A) then
												sign_flag <= '1';
											else
												sign_flag <= '0';
											end if;
										
										when "01" => -- CMP B, B
										
											report "CMP B, B nao permitido";
										
										when "10" => -- CMP B, R
										
											if B = R then
												equal_flag <= '1';
											else
												equal_flag <= '0';
											end if;

											if signed(B) < signed(R) then
												sign_flag <= '1';
											else
												sign_flag <= '0';
											end if;
										
										when "11" => -- CMP B, op
										
											if B = data_bus then
												equal_flag <= '1';
											else
												equal_flag <= '0';
											end if;

											if signed(B) < signed(data_bus) then
												sign_flag <= '1';
											else
												sign_flag <= '0';
											end if;
											
											PC <= std_logic_vector(resize(unsigned(PC) + 1, 8)); -- Incrementa PC
										
										when others =>
											report "CMP: erro nos parametros";
									end case;
								
								
								when "10" => -- primeiro operando: R
								
									case IR(1 downto 0) is
										when "00" => -- CMP R, A
										
											if R = A then
												equal_flag <= '1';
											else
												equal_flag <= '0';
											end if;

											if signed(R) < signed(A) then
												sign_flag <= '1';
											else
												sign_flag <= '0';
											end if;
										
										when "01" => -- CMP R, B
										
											if R = B then
												equal_flag <= '1';
											else
												equal_flag <= '0';
											end if;

											if signed(R) < signed(B) then
												sign_flag <= '1';
											else
												sign_flag <= '0';
											end if;
										
										when "10" => -- CMP R, R
										
											report "CMP R, R nao permitido";
										
										when "11" => -- CMP R, op
										
											if R = data_bus then
												equal_flag <= '1';
											else
												equal_flag <= '0';
											end if;

											if signed(R) < signed(data_bus) then
												sign_flag <= '1';
											else
												sign_flag <= '0';
											end if;
											
											PC <= std_logic_vector(resize(unsigned(PC) + 1, 8)); -- Incrementa PC
										
										when others =>
											report "CMP: erro nos parametros";
									end case;
								
								
								when "11" => -- primeiro operando: op
								
									case IR(1 downto 0) is
										when "00" => -- CMP op, A
										
											if data_bus = A then
												equal_flag <= '1';
											else
												equal_flag <= '0';
											end if;

											if signed(data_bus) < signed(A) then
												sign_flag <= '1';
											else
												sign_flag <= '0';
											end if;
											
											PC <= std_logic_vector(resize(unsigned(PC) + 1, 8)); -- Incrementa PC
										
										when "01" => -- CMP op, B
										
											if data_bus = B then
												equal_flag <= '1';
											else
												equal_flag <= '0';
											end if;

											if signed(data_bus) < signed(B) then
												sign_flag <= '1';
											else
												sign_flag <= '0';
											end if;
											
											PC <= std_logic_vector(resize(unsigned(PC) + 1, 8)); -- Incrementa PC
										
										when "10" => -- CMP op, R
										
											if data_bus = R then
												equal_flag <= '1';
											else
												equal_flag <= '0';
											end if;

											if signed(data_bus) < signed(R) then
												sign_flag <= '1';
											else
												sign_flag <= '0';
											end if;
											
											PC <= std_logic_vector(resize(unsigned(PC) + 1, 8)); -- Incrementa PC
										
										when "11" => -- CMP op, op
										
											report "CMP op, op nao permitido";
										
										when others =>
											report "CMP: erro nos parametros";
									end case;
								
								when others =>
									report "CMP: erro nos parametros";
							end case;
							
							state := fetch;
							
						-- FIM DO CMP
						
						when "0011" => -- JMP
						
						-- não há parametros para essa instrução
						-- O endereço de salto é o endereço da proxima palavra
						PC <= data_bus;
						state := fetch;
						
						when "0100" => -- JEQ
						
						-- Salta se a ultima comparação for igual
						-- O endereço de salto é o endereço da proxima palavra
						if equal_flag = '1' then
							PC <= data_bus;
						else
							PC <= std_logic_vector(resize(unsigned(PC) + 1, 8)); -- Incrementa PC
						end if;
						state := fetch;
						
						when "0101" => -- JGR
						
						-- salta se primeiro comparado é maior que o segundo
						-- O endereço de salto é o endereço da proxima palavra
						if sign_flag = '0' and equal_flag = '0' then
							PC <= data_bus;
						else
							PC <= std_logic_vector(resize(unsigned(PC) + 1, 8)); -- Incrementa PC
						end if;
						state := fetch;
						
						when "0110" => -- STORE
						
							case mem_wren is
							
								when '0' => -- fazer a escrita
								
									case IR(1 downto 0) is
									
										when "00" => -- STORE A,  addr
											address_bus <= data_bus;
											mem_data_in <= A;
											mem_wren <= '1';
											PC <= std_logic_vector(resize(unsigned(PC) + 1, 8)); -- Incrementa PC
										
										when "01" => -- STORE B,  addr
											address_bus <= data_bus;
											mem_data_in <= B;
											mem_wren <= '1';
											PC <= std_logic_vector(resize(unsigned(PC) + 1, 8)); -- Incrementa PC
										
										when "10" => -- STORE R,  addr
											address_bus <= data_bus;
											mem_data_in <= R;
											mem_wren <= '1';
											PC <= std_logic_vector(resize(unsigned(PC) + 1, 8)); -- Incrementa PC
											
										when "11" => -- STORE op, addr
											report "STORE: erro parametro"; -- erro
											
										when others =>
											report "STORE: erro na escrita";
									
									end case; -- end case IR
							
								when '1' => -- escrita realizada	
									mem_wren <= '0';
									state := fetch;
									
								when others =>
									report "STORE: erro na escrita";
									
							end case; -- end case mem_wren
							
						when "0111" => -- MOV
						
							-- primeiro operando
							case IR(3 downto 2) is
								when "00" => -- A
								
									-- segundo operando
									case IR(1 downto 0) is
										when "00" => -- MOV A, A
											report "MOV: erro no parametro MOV, A A";
										
										when "01" => -- MOV A, B
											A <= B;
											
										when "10" => -- MOV A, R
											A <= R;
										
										when "11" => -- MOV A, op
											A <= data_bus;
											PC <= std_logic_vector(resize(unsigned(PC) + 1, 8)); -- Incrementa PC
										when others =>
											report "MOV: erro nos parametros";
									
									end case;
								
								when "01" => -- B
								
									-- segundo operando
									case IR(1 downto 0) is
										when "00" => -- MOV B, A
											B <= A;
										
										when "01" => -- MOV B, B
											report "MOV: erro parametro MOV B, B";
										
										when "10" => -- MOV B, R
											B <= R;
										
										when "11" => -- MOV B, op
											B <= data_bus;
											PC <= std_logic_vector(resize(unsigned(PC) + 1, 8)); -- Incrementa PC
											
										when others =>
											report "MOV: erro nos parametros";
											
									end case;
								
								when "10" => -- R
								
									-- segundo operando
									case IR(1 downto 0) is
										when "00" => -- MOV R, A
											R <= A;
										
										when "01" => -- MOV R, B
											R <= B;
										
										when "10" => -- MOV R, R
											report "MOV: erro parametro MOV R, R";
										
										when "11" => -- MOV R, op
											R <= data_bus;
											PC <= std_logic_vector(resize(unsigned(PC) + 1, 8)); -- Incrementa PC
									
										when others =>
											report "MOV: erro nos parametros";
											
									end case;
								
								when "11" => -- erro
									report "MOV: parametro invalido";
									
								when others =>
									report "MOV: erro nos parametros";
							
							end case;
							state := fetch;
							
							
						-- fim do MOV
						when "1101" => -- IN
							-- Salva o valor das SWs em um registrador depois que o botao for pressionado
							
							io_input_enable <= '1';
							-- aguarda o botao ser despressionado
							if (io_button_status = '0') then
								botao_despressionado := '1';
							end if;
							
							
							if (io_button_status = '1' and botao_despressionado = '1') then
							
								CASE IR(1 downto 0) is
									
									when "00" => -- salva em A
										A <= io_SW;
									when "01" => -- B
										B <= io_SW;
									when "10" => -- R
										R <= io_SW;
									when others =>
										report "erro na instrucao IN";
								
								end case;
								state := fetch;
								botao_despressionado := '0';
								io_input_enable <= '0';
							
							else -- aguarda o botao ser pressionado para salvar os dados e continuar
								state := execute;
							end if;
							
						when "1110" => -- OUT
							-- Exibe o valor de um registrador nos LEDs
							
							io_output_enable <= '1';
							CASE IR(1 downto 0) is
									
								when "00" => -- exibe A
									io_data_in <= A;
								when "01" => -- B
									io_data_in <= B;
								when "10" => -- R
									io_data_in <= R;
								when others =>
									report "erro na instrucao IN";
								
							end case;
							state := fetch;
							
						when "1111" => -- WAIT
							-- aguarda que o BTN seja pressionado
							if (io_button_status = '0') then
								botao_despressionado := '1';
							end if;
							
							if (io_button_status = '1' and botao_despressionado = '1') then
								state := fetch;
								botao_despressionado := '0';
							else
								state := execute;
							end if;
						
						when "0000" => -- nop
						   -- retorna ao fetch
							state := fetch;
						
						when others => -- Operação com ALU: ADD (1000), SUB (1001), AND (1010), OR (1011), NOT (1100)
							
							case alu_state is
								
							when fetch_operand_A =>
							
								case IR(3 downto 2) is -- primeiro operando
								
									when "00" => -- A
									op_a <= A;
									
									when "01" => -- B
									op_a <= B;
									
									when "10" => -- R
									op_a <= R;
									
									when "11" => -- op
									-- fazer leitura e incrementa PC
									op_a <= data_bus;
									state := wait_read;
									PC <= std_logic_vector(resize(unsigned(PC) + 1, 8));
								
									when others =>
										report "erro em fetch_operand_A";
										
								end case;
								alu_state := fetch_operand_B; -- prox estado
							
							when fetch_operand_B =>
							
								case IR(1 downto 0) is -- segundo operando
									
									when "00" => -- A
									op_b <= A;
									
									when "01" => -- B
									op_b <= B;
									
									when "10" => -- R
									op_b <= R;
									
									when "11" => -- op
									--fazer leitura e incrementa PC
									op_b <= data_bus;
									state := wait_read;
									PC <= std_logic_vector(resize(unsigned(PC) + 1, 8));
									
									when others =>
										report "erro em fetch_operand_B";
										
								end case;
								alu_enable <= '1'; -- ALU pronta
								alu_state := ready; -- prox estado
								
							when ready => -- operandos estão posicionados e ALU ja fez a operação
								
								R <= alu_result;
								state := fetch;
								alu_enable <= '0';
								alu_state := fetch_operand_A; -- reseta o estado da alu
								
						end case; -- case alu_state
					
					end case; -- case IR (dentro de execute)
            
            when wait_read =>
               --read <= '0';             -- Desativa leitura
               state := execute;         -- Aguarda um ciclo para leitura estabilizar
			
			end case; -- case state
      end if;
		
		-- sinais de debug
		state_monitor <= state;
      state_alu_monitor <= alu_state;
		
		-- sinais do barramento de controle
		control_bus(0) <= read;
		control_bus(1) <=	mem_wren;
		control_bus(2) <=	mem_enable;
		control_bus(3) <=	io_input_enable;
		control_bus(4) <=	io_output_enable;
		control_bus(5) <= clk;
		control_bus(6) <= reset;
   end if;
end process;

end behavior;
