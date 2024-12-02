LOAD A, 50       ; Carrega o valor do endereço 50 no registrador A
MOV B, 1         ; Move o valor 1 para o registrador B
CMP A, B         ; Compara A e B
JEQ 12           ; Salta para o endereço 12 se A == 1
SUB A, B         ; Subtrai B de A, resultado em R
STORE R, 50      ; Armazena o novo valor em 50
JMP 4            ; Salta de volta para a comparação
