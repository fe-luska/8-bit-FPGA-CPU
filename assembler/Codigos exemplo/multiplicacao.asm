IN A
IN B
MOV R 0
LOOP_START:
  CMP B 0
  JEQ END_LOOP
  ADD R A
  STORE R 255
  SUB B 1
  MOV B R
  LOAD R 255
  JMP LOOP_START
END_LOOP:
  OUT R
WAIT