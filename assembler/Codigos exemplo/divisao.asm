IN A
IN B
MOV R 0
STORE R 255
MOV R A
LOOP_START:
    SUB R B; inicio do loop
    MOV A R
    LOAD R 255
    ADD R 1
    STORE R 255
    MOV R A
    CMP R B
    JGR LOOP_START
LOAD R 255
OUT R
WAIT