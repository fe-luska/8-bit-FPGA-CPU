LOAD A, 42
LOAD B, 43
MOV R 0
STORE R 255
MOV R A
LOOP_START:; teste de comentario
    SUB R B; inicio do loop
    MOV A R
    LOAD R 255
    ADD R 1
    STORE R 255
    MOV R A
    CMP R B
    JGR LOOP_START; outro teste de comentario
LOAD R 255; mais um teste de comentario hahaha