# Assembler

Foi desenvolvido um assembler compatível com a CPU apresentada. Ele suporta rótulos para referências a endereços de memória, instruções básicas de controle, operações aritméticas/lógicas e comentários no código iniciados com “;”. O assembler inclui verificações de sintaxe e retorna erros explicativos caso ocorram.

---

### Características principais
- Suporte para rótulos e endereços simbólicos.
- Verificação de sintaxe para instruções, registradores e endereços.
- Tradução em duas passagens para resolução de rótulos.
- Conversão automática de valores decimais para hexadecimal.

---

## Uso do Assembler

### Execução

1. Certifique-se de que o Python está instalado em seu sistema.
2. Salve o código do assembler em um arquivo chamado `assembler.py`.
3. Execute o assembler com o seguinte comando:

```bash
python assembler.py <arquivo_de_entrada> <arquivo_de_saida>
```

4.Depois que o arquivo .hex foi gerado, mova-o para o diretório “cpu” e modifique seu nome para “memoria_dados.hex" para ser reconhecido pela CPU.

#### Parâmetros
- <arquivo_de_entrada>: Nome do arquivo de entrada contendo o código assembly com a extensão .asm.
- <arquivo_de_saida>: Nome do arquivo de saída onde o código de máquina será salvo com a extensão .hex.

### Formato do Código Assembly
- Cada linha contém uma instrução ou rótulo.
- Rótulos devem terminar com `:`.
- Comentários iniciam com `;` e são ignorados pelo assembler.
- Operandos de instruções são separados por espaços ou vírgulas.

#### Exemplo:
```assembly
; Exemplo de código assembly
START:
    LOAD A, 10  ; Carrega o valor que está no endereço 10 (decimal) no registrador A
    CMP A, B    ; Compara os valores de A e B
    JEQ END     ; Salta para END se A for igual a B
    ADD A, B    ; Soma A com B
END:
    STORE A, 20 ; Armazena o valor de A no endereço 20
    NOP         ; Nenhuma operação
```

No diretorio "codigos exemplo" há exemplos programas em assembly aceitos pelo assembler. 

---

## Conjunto de Instruções

### Instruções Suportadas

As instruções suportadas são as instruções apresentadas anteriormente no documento principal do projeto, porém, aqui está uma tabela resumida das instruções. Caso seja necessário, verifique o detalhamento das instruções no diretório raíz do projeto.

| Instrução | Opcode | Parâmetros         | Descrição                              |
|-------------|--------|-------------------|------------------------------------------|
| NOP         | 0      | -                 | Nenhuma operação                        |
| LOAD        | 1      | Registrador, End. | Carrega valor da memória para registrador |
| CMP         | 2      | Registrador, Reg. | Compara dois registradores               |
| JMP         | 3      | Endereço          | Salta para um endereço                   |
| JEQ         | 4      | Endereço          | Salta se igual                           |
| JGR         | 5      | Endereço          | Salta se maior                           |
| STORE       | 6      | Registrador, End. | Armazena valor do registrador na memória |
| MOV         | 7      | Registrador, Reg. | Move valor entre registradores           |
| ADD         | 8      | Registrador, Reg. | Soma dois registradores                  |
| SUB         | 9      | Registrador, Reg. | Subtrai dois registradores               |
| AND         | A      | Registrador, Reg. | Operação AND entre dois registradores    |
| OR          | B      | Registrador, Reg. | Operação OR entre dois registradores     |
| NOT         | C      | Registrador       | Operação NOT em um registrador          |
| IN          | D      | Registrador       | Carrega o valor das chaves no registrador |
| OUT         | E      | Registrador       | Exibe o valor do registrador nos LEDs     |
| WAIT        | F      | -                 | Aguarda o botão ser pressionado.          |

Obs: Os endereços utilizados em LOAD e STORE devem ser decimais de 0 a 255.

### Registradores Suportados

Os registradores suportados são: A, B e R (utilizado para resultados da ULA).

## Processo de Tradução

1. **Primeira Passagem**
   - Processar rótulos e identificar endereços simbólicos.
   - Armazenar rótulos com seus endereços correspondentes.

2. **Geração de Código de Máquina**
   - Traduzir instruções e operandos para código hexadecimal.
   - Substituir rótulos por endereços temporários.

3. **Resolução de Endereços**
   - Ajustar endereços temporários após remoção de rótulos.
   - Substituir endereços temporários por endereços finais.

