LOAD A, 20       ; Carrega o valor do endereço 20 no registrador A
LOAD B, 21       ; Carrega o valor do endereço 21 no registrador B
CMP A, B         ; Compara A e B
JGR 8            ; Salta para o endereço 8 se A > B
MOV R, B         ; Move B para R
STORE R, 22      ; Armazena o valor de B em 22
JMP 10           ; Salta para o fim do programa
MOV R, A         ; Move A para R
STORE R, 22      ; Armazena o valor de A em 22
