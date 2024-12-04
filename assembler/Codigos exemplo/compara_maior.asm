IN A		 ; Carrega o valor das chaves no registrador A
IN B       	 ; Carrega o valor das chaves no registrador B
CMP A, B         ; Compara A e B
JGR 8            ; Salta para o endereço 8 se A > B
MOV R, B         ; Move B para R
STORE R, 22      ; Armazena o valor de B em 22
JMP 10           ; Salta para o fim do programa
MOV R, A         ; Move A para R
STORE R, 22      ; Armazena o valor de A em 22