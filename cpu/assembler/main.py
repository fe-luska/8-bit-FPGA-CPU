import argparse

class Assembler8Bit:
    def __init__(self):
        self.instructions = {
            "NOP": "00",
            "LOAD": "01",
            "CMP": "02",
            "JMP": "03",
            "JEQ": "04",
            "JGR": "05",
            "STORE": "06",
            "MOV": "07",
            "ADD": "08",
            "SUB": "09",
            "AND": "0A",
            "OR": "0B",
            "NOT": "0C",
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
            self.labels[label] = len(self.output)
            return None

        # Adicionar instrução à lista de código
        self.code.append((line, line_number))

    def assemble(self):
        # Primeira passada: processar rótulos
        for line, line_number in self.code:
            tokens = line.split()
            instruction = tokens[0].upper()

            if instruction not in self.instructions:
                raise ValueError(f"Erro na linha {line_number}: instrução desconhecida '{instruction}'")

            opcode = self.instructions[instruction]
            params = tokens[1:] if len(tokens) > 1 else []
            machine_code = self.generate_machine_code(opcode, params, line_number)

            # Adicionar ao programa
            self.output.extend(machine_code)

        # Resolver referências a rótulos
        for i, word in enumerate(self.output):
            if isinstance(word, str) and word.startswith("$LABEL$"):
                label_name = word.split("$LABEL$")[1]
                if label_name not in self.labels:
                    raise ValueError(f"Rótulo não definido: '{label_name}'")
                self.output[i] = f"{self.labels[label_name]:02X}"

    def generate_machine_code(self, opcode, params, line_number):
        machine_code = [opcode]

        if opcode == "00":  # NOP
            return machine_code  # Nenhum parâmetro necessário

        if opcode in ["01", "06"]:  # LOAD, STORE
            if len(params) != 2:
                raise ValueError(f"Erro na linha {line_number}: {opcode} requer dois parâmetros")
            reg, addr = params
            if reg.upper() not in self.registers:
                raise ValueError(f"Erro na linha {line_number}: registrador inválido '{reg}'")
            machine_code[0] += self.registers[reg.upper()]
            machine_code.append(self.resolve_address(addr, line_number))

        elif opcode in ["03", "04", "05"]:  # JMP, JEQ, JGR
            if len(params) != 1:
                raise ValueError(f"Erro na linha {line_number}: {opcode} requer um parâmetro")
            addr = params[0]
            machine_code.append(self.resolve_address(addr, line_number))

        elif opcode == "02":  # CMP
            if len(params) != 2:
                raise ValueError(f"Erro na linha {line_number}: CMP requer dois parâmetros")
            reg1, reg2 = params
            machine_code[0] += self.resolve_register_or_immediate(reg1, line_number)
            machine_code[0] += self.resolve_register_or_immediate(reg2, line_number)

        elif opcode == "07":  # MOV
            if len(params) != 2:
                raise ValueError(f"Erro na linha {line_number}: MOV requer dois parâmetros")
            reg1, reg2 = params
            if reg1 == reg2:
                raise ValueError(f"Erro na linha {line_number}: MOV não permite operando duplicado")
            machine_code[0] += self.resolve_register_or_immediate(reg1, line_number)
            machine_code[0] += self.resolve_register_or_immediate(reg2, line_number)

        elif opcode in ["08", "09", "0A", "0B", "0C"]:  # ADD, SUB, AND, OR, NOT
            if len(params) != 2:
                raise ValueError(f"Erro na linha {line_number}: {opcode} requer dois parâmetros")
            reg1, reg2 = params
            machine_code[0] += self.resolve_register_or_immediate(reg1, line_number)
            machine_code[0] += self.resolve_register_or_immediate(reg2, line_number)

        return machine_code

    def resolve_address(self, addr, line_number):
        if addr.isdigit():
            return f"{int(addr):02X}"
        return f"$LABEL${addr}"

    def resolve_register_or_immediate(self, operand, line_number):
        if operand.upper() in self.registers:
            return self.registers[operand.upper()]
        elif operand.isdigit():
            return "3"  # Representa valor imediato
        else:
            raise ValueError(f"Erro na linha {line_number}: operando inválido '{operand}'")

    def generate_output_file(self, filename):
        with open(filename, "w") as file:
            file.write("".join(self.output))

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
