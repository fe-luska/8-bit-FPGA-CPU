LOAD A 46;     
LOAD B 47; 
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
  NOP