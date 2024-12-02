import argparse

# Anotações
# Falta resolver o problema de endereços de memória que são rótulos
# Falta implementar a verificação de endereços de memória válidos

class Assembler8Bit:
    def __init__(self):
        self.instructions = {
            "NOP": "0",
            "LOAD": "1",
            "CMP": "2",
            "JMP": "3",
            "JEQ": "4",
            "JGR": "5",
            "STORE": "6",
            "MOV": "7",
            "ADD": "8",
            "SUB": "9",
            "AND": "A",
            "OR": "B",
            "NOT": "C",
        }
        self.registers = {
            "A": "0",
            "B": "1",
            "R": "2",
        }
        self.code = []
        self.labels = {}
        self.output = []

    def parse_line(self, line, line_number):
        # Remove comentários
        line = line.split(";")[0].strip()
        if not line:
            return None

        # Identificar rótulos
        if line.endswith(":"):
            label = line[:-1]
            if label in self.labels:
                raise ValueError(f"Erro na linha {line_number}: rótulo duplicado '{label}'")
            self.labels[label] = line_number
            line = "$LABEL_SET$" + line[:-1]

        # remove as virgulas
        line = line.replace(",", " ")

        # Adicionar instrução à lista de código
        self.code.append((line, line_number))

    def assemble(self):
        # Primeira passada: processar rótulos
        for line, line_number in self.code:

            if line.startswith("$LABEL_SET$"):
                self.output.append(line)
                continue
            
            tokens = line.split()
            instruction = tokens[0].upper()

            if instruction not in self.instructions:
                raise ValueError(f"Erro na linha {line_number}: instrução desconhecida '{instruction}'")

            opcode = self.instructions[instruction]
            params = tokens[1:] if len(tokens) > 1 else []
            machine_code = self.generate_machine_code(opcode, params, line_number)

            # Adicionar ao programa
            self.output.extend(machine_code)

        # Resolver referências a rótulos (3 etapas)

        # (etapa 1) Trocar $LABEL_ADDR$ por endereços temporarios
        for i, word in enumerate(self.output):
            if isinstance(word, str) and word.startswith("$LABEL_ADDR$"):
                label_name = word.split("$LABEL_ADDR$")[1]

                # verifica se label existe
                if label_name not in self.labels:
                    raise ValueError(f"Rótulo não definido: '{label_name}'")
                
                # busca em self.output o $LABEL_SET$ correspondente
                index = self.output.index("$LABEL_SET$" + label_name)

                # adiciona o endereço temporario no label
                self.output[i] = "$LABEL_TEMP_ADDR$" + str(index)
        
        # (etapa 2) remover os $LABEL_SET$ e ajustar os endereços temporários
        for i, word in enumerate(self.output):
            if isinstance(word, str) and word.startswith("$LABEL_SET$"):
                label_name = word.split("$LABEL_SET$")[1]
                self.output.pop(i)

                # percorre a lista para todos os elementos maiores que o i
                for j in range(i, len(self.output)):
                    if isinstance(self.output[j], str) and self.output[j].startswith("$LABEL_TEMP_ADDR$") and int(self.output[j].split("$LABEL_TEMP_ADDR$")[1]) > i:
                        
                        # decrementa o endereço em 1
                        self.output[j] = "$LABEL_TEMP_ADDR$" + str(int(self.output[j].split("$LABEL_TEMP_ADDR$")[1]) - 1)

        # (etapa 3) remover os $LABEL_TEMP_ADDR$ e substituir pelo endereço final
        for i, word in enumerate(self.output):
            if isinstance(word, str) and word.startswith("$LABEL_TEMP_ADDR$"):
                label_name = word.split("$LABEL_TEMP_ADDR$")[1]
                self.output[i] = hex(int(label_name))[2:].upper()

    def generate_machine_code(self, opcode, params, line_number):
        machine_code = [opcode]

        if opcode == "0":  # NOP
            # retorna o próprio código da instrução + 00
            return machine_code + ["00"]

        elif opcode == "1": # LOAD

            if len(params) != 2:
                raise ValueError(f"Erro na linha {line_number}: {opcode} requer dois parâmetros")
            reg, addr = params

            if reg.upper() not in self.registers:
                raise ValueError(f"Erro na linha {line_number}: registrador inválido '{reg}'")
            
            # Adiciona o código do registrador ao código da instrução
            machine_code[0] += self.registers[reg.upper()]

            # Adiciona o endereço na instrução seguinte
            try: 
                machine_code.append(hex(int(addr))[2:].upper())
            except ValueError:
                raise ValueError(f"Erro na linha {line_number}: endereço inválido '{addr}'\n Endereços devem ser números decimais entre 0 e 255")

        elif opcode == "2":  # CMP
            if len(params) != 2:
                raise ValueError(f"Erro na linha {line_number}: CMP requer dois parâmetros")
            reg1, reg2 = params
            
            if reg1 == reg2:
                raise ValueError(f"Erro na linha {line_number}: CMP não permite operando duplicado")

            binario = ""
            reg1_eh_endereco = False
            reg2_eh_endereco = False

            if self.isRegister(reg1, line_number):
                if reg1.upper() == "A":
                    binario += "00"
                elif reg1.upper() == "B":
                    binario += "01"
                elif reg1.upper() == "R":
                    binario += "10"
                else:
                    raise ValueError(f"Erro na linha {line_number}: registrador inválido '{reg1}'")
            else:
                binario += "11"
                reg1_eh_endereco = True

            if self.isRegister(reg2, line_number):
                if reg2.upper() == "A":
                    binario += "00"
                elif reg2.upper() == "B":
                    binario += "01"
                elif reg2.upper() == "R":
                    binario += "10"
                else:
                    raise ValueError(f"Erro na linha {line_number}: registrador inválido '{reg2}'")
            else:
                binario += "11"
                reg2_eh_endereco = True

            machine_code[0] += (hex(int(binario, 2))[2:].upper())
            
            # adiciona o endereço na proxima palavra
            if reg1_eh_endereco:
                machine_code.append(reg1)
            elif reg2_eh_endereco:
                machine_code.append(reg2)

        elif opcode in ["3", "4", "5"]:  # JMP, JEQ, JGR
            if len(params) != 1:
                raise ValueError(f"Erro na linha {line_number}: {opcode} requer um parâmetro")
            
            # essas instruções nao tem parametros, completar com 0
            machine_code[0] += "0"
            
            # adiciona o endereço na proxima palavra
            addr = params[0]
            
            # precisa verificar se é um endereço ou um rótulo
            if addr in self.labels:
                machine_code.append(f"$LABEL_ADDR${addr}")
            else:
                machine_code.append(addr.upper())

        elif opcode == "6":  # STORE
            
            # primeiro arg eh o registrador, segundo é o endereço
            if len(params) != 2:
                raise ValueError(f"Erro na linha {line_number}: {opcode} requer dois parâmetros")
            reg, addr = params
            
            if reg.upper() not in self.registers:
                raise ValueError(f"Erro na linha {line_number}: registrador inválido '{reg}'")
            
            machine_code[0] += self.registers[reg.upper()]

            machine_code.append(hex(int(addr))[2:].upper())

        elif opcode == "7":  # MOV
            if len(params) != 2:
                raise ValueError(f"Erro na linha {line_number}: MOV requer dois parâmetros")
            
            reg1, reg2 = params
            if reg1 == reg2:
                raise ValueError(f"Erro na linha {line_number}: MOV não permite operando duplicado")
            
            # string binario, vamos converter pra hex depois
            binario = ""

            if reg1.upper() == "A":
                binario += "00"
            elif reg1.upper() == "B":
                binario += "01"
            elif reg1.upper() == "R":
                binario += "10"
            else:
                raise ValueError(f"Erro na linha {line_number}: registrador inválido '{reg1}'")

            if self.isRegister(reg2, line_number):
                if reg2.upper() == "A":
                    binario += "00"
                elif reg2.upper() == "B":
                    binario += "01"
                elif reg2.upper() == "R":
                    binario += "10"
                else:
                    raise ValueError(f"Erro na linha {line_number}: registrador inválido '{reg2}'")
            else:
                binario += "11"
            
            # binario para hex
            machine_code[0] += (hex(int(binario, 2))[2:].upper())
            
            if not self.isRegister(reg2, line_number):
                # converter reg2 (decimal) para hex e adicionar na proxima palavra
                machine_code.append(hex(int(reg2))[2:].upper())

        elif opcode in ["8", "9", "A", "B", "C"]:  # ADD, SUB, AND, OR, NOT
            if len(params) != 2:
                raise ValueError(f"Erro na linha {line_number}: {opcode} requer dois parâmetros")
            reg1, reg2 = params
            
            binario = ""
            reg1_eh_endereco = False
            reg2_eh_endereco = False

            if self.isRegister(reg1, line_number):
                if reg1.upper() == "A":
                    binario += "00"
                elif reg1.upper() == "B":
                    binario += "01"
                elif reg1.upper() == "R":
                    binario += "10"
                else:
                    raise ValueError(f"Erro na linha {line_number}: registrador inválido '{reg2}'")
            else:
                binario += "11"
                reg1_eh_endereco = True

            if self.isRegister(reg2, line_number):
                if reg2.upper() == "A":
                    binario += "00"
                elif reg2.upper() == "B":
                    binario += "01"
                elif reg2.upper() == "R":
                    binario += "10"
                else:
                    raise ValueError(f"Erro na linha {line_number}: registrador inválido '{reg2}'")
            else:
                binario += "11"
                reg2_eh_endereco = True

            machine_code[0] += (hex(int(binario, 2))[2:].upper())

            # adiciona o endereço na proxima palavra
            if reg1_eh_endereco:
                machine_code.append(hex(int(reg1))[2:].upper())
            elif reg2_eh_endereco:
                machine_code.append(reg2)

        return machine_code

    def isRegister(self, operand, line_number):
        if operand.upper() in self.registers:
            return True
        elif operand.isdigit():
            return False
        else:
            raise ValueError(f"Erro na linha {line_number}: operando inválido '{operand}'")

    def generate_output_file(self, filename):

        # verifica se filename termina com .hex
        if not filename.endswith(".hex"):
            filename += ".hex"

        formated_output = [s.zfill(2).upper() for s in self.output]
        with open(filename, "w") as file:
            for hex_code in formated_output:
                file.write(hex_code)

    def assemble_file(self, input_file, output_file):
        with open(input_file, "r") as file:
            lines = file.readlines()
        for line_number, line in enumerate(lines, 1):
            self.parse_line(line, line_number)
        self.assemble()
        self.generate_output_file(output_file)


def main():
    parser = argparse.ArgumentParser(description="Assembler para CPU de 8 bits.")
    parser.add_argument("input_file", help="Arquivo de entrada com código assembly.")
    parser.add_argument("output_file", help="Arquivo de saída em formato hexadecimal.")
    args = parser.parse_args()

    assembler = Assembler8Bit()
    try:
        assembler.assemble_file(args.input_file, args.output_file)
        print(f"Arquivo '{args.output_file}' gerado com sucesso!")
    except Exception as e:
        print(f"Erro durante a montagem: {e}")


if __name__ == "__main__":
    main()
