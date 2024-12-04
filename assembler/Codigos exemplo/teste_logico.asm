IN A             ; Carrega o valor das chaves no registrador A
IN B             ; Carrega o valor das chaves no registrador B
AND A, B         ; Faz A AND B, resultado armazenado em R
STORE R, 32      ; Armazena o resultado da operação AND no endereço 32
OR A, B          ; Faz A OR B, resultado armazenado em R
STORE R, 33      ; Armazena o resultado da operação OR no endereço 33